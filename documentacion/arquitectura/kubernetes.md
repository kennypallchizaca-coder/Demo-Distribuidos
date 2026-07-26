# Guía de Arquitectura y Objetos en Kubernetes (K8s)

Documento de referencia para comprender la función, sintaxis línea por línea, estrategias de despliegue y solución de problemas en Kubernetes.

---

## 1. Explicación Detallada de Objetos Principales

### A. Deployment (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: webapp
spec:
  replicas: 6
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: web
        image: practice:v2
        ports:
        - containerPort: 8080
```

#### Línea: `replicas: 6`
- **Para qué sirve**: Define la cantidad deseada de instancias (Pods) idénticas que deben estar ejecutándose simultáneamente en el clúster.
- **Por qué se coloca**: Garantiza alta disponibilidad y distribución de carga.
- **Qué pasa si se cambia por `replicas: 1`**: La aplicación funcionará, pero si el pod cae o el nodo sufre una falla, el servicio quedará fuera de línea hasta que K8s recree el Pod.
- **Cuándo conviene utilizar réplicas elevadas (ej. 6)**: Cuando se espera un incremento masivo de tráfico (escenario de "El Giro").

#### Línea: `selector.matchLabels.app: webapp`
- **Para qué sirve**: Le indica al controlador del Deployment a qué Pods debe administrar.
- **Por qué se coloca**: Kubernetes no rastrea Pods por nombre, sino por etiquetas.
- **Qué pasa si no coincide con `template.metadata.labels.app`**:
  - **ERROR EXACTO**: La API de Kubernetes rechaza el manifiesto con el mensaje `selector does not match template labels`.

#### Línea: `template.metadata.labels.app: webapp`
- **Para qué sirve**: Asigna la etiqueta clave-valor `app: webapp` a cada Pod nuevo creado por este Deployment.
- **Por qué se coloca**: Es la clave de conexión para que tanto el Deployment como el `Service` reconozcan a los Pods.
<<<<<<< HEAD
- **Qué pasa si se cambia por `app: web` (Reto 2)**:
  - **SÍNTOMA DE FALLA**: Los Pods se crean y pasan a estado `Running`, pero el `Service` no les envía tráfico. Al ejecutar `kubectl get endpoints web-service` la salida muestra `ENDPOINTS: <none>`.

---

### B. Service (`service.yaml`)
=======

---

## 2. Estrategias de Despliegue para "El Giro"

### Opción 1: RollingUpdate (Actualización Progresiva Zero-Downtime)
Estrategia por defecto recomendada para despliegues sin corte de servicio.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2         # Crea hasta 2 Pods nuevos antes de apagar los antiguos
    maxUnavailable: 0   # 0 Pods caídos durante la transición -> Cero interrupción
```

### Opción 2: Blue-Green Deployment (Conmutación Instantánea)
Se mantienen dos instalaciones completas: `blue` (versión actual) y `green` (versión nueva).

- **Cómo funciona**: Se despliega el Deployment `green` en paralelo. Una vez verificado, se cambia la etiqueta `version: green` en el `Service.spec.selector` para redirigir el 100% del tráfico instantáneamente.
>>>>>>> d811b45 (Commit inicial)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
<<<<<<< HEAD
  type: ClusterIP
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
```

#### Línea: `selector.app: webapp`
- **Para qué sirve**: Es el filtro mediante el cual el Servicio descubre automáticamente las direcciones IP de los Pods activos.
- **Por qué se coloca**: Abstrae las IPs efímeras de los Pods. Cuando un Pod muere y renace con una IP distinta, el Servicio actualiza su tabla de Endpoints dinámicamente.
- **Qué pasa si no coincide con las etiquetas del Pod**: Los Endpoints quedan vacíos (`<none>`) y el Servicio retorna un error de timeout al intentar acceder.

#### Líneas: `port: 80` y `targetPort: 8080`
- **`port: 80`**: El puerto público/interno en el cual el Servicio recibe solicitudes dentro del clúster.
- **`targetPort: 8080`**: El puerto exacto donde el contenedor dentro del Pod está escuchando (`containerPort`).
- **Qué pasa si `targetPort` es incorrecto**: El Servicio reenvía la petición a un puerto donde la aplicación no escucha, generando un error de conexión rehusada.

#### Alternativas de Tipos de Servicio (`type`)
- **ClusterIP** (Por defecto): Recomendado para comunicación interna dentro del clúster o detrás de un Ingress.
- **NodePort**: Expone el Servicio en un puerto estático en la IP de cada nodo del clúster (rango 30000-32767). Útil para pruebas simples.
- **LoadBalancer**: Solicita un balanceador de carga público a un proveedor de nube (AWS, GCP, Azure).

---

## 2. Estrategias de Despliegue y Zero-Downtime

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2
    maxUnavailable: 0
```

### Directiva: `type: RollingUpdate`
- **Para qué sirve**: Reemplaza gradualmente los Pods de la versión anterior por la versión nueva.
- **Alternativa**: `type: Recreate` (Apaga todos los Pods viejos antes de crear los nuevos).
- **Por qué RollingUpdate es más recomendable**: Evita caídas de servicio. Con `Recreate` el sistema sufre una interrupción total durante varios segundos mientras cargan las nuevas instancias.

### Directiva: `maxUnavailable: 0` (Crucial para "El Giro")
- **Para qué sirve**: Especifica que durante la actualización **cero** Pods de la versión actual pueden estar desactivados antes de que los nuevos estén totalmente listos.
- **Qué pasa si se deja en el valor por defecto (`25%`)**: Durante el despliegue, la capacidad total de Pods disponibles disminuye, lo que bajo picos de tráfico causará saturación y caídas en las solicitudes de los usuarios.

=======
  selector:
    app: webapp
    version: green # CAMBIAR DE 'blue' A 'green' PARA CONMUTAR INSTANTANEAMENTE
```

### Opción 3: Canary Deployment (Despliegue Progresivo por Porcentaje)
Se despliega la nueva versión para un porcentaje reducido del tráfico (ej. 10%) mientras el 90% restante sigue en la versión estable.

- **Cómo funciona**: Se crean dos Deployments con la misma etiqueta `app: webapp`, ajustando la proporción de réplicas (ej. 9 réplicas de `stable` y 1 réplica de `canary`).

```yaml
# Deployment Estable (90% del tráfico)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment-stable
spec:
  replicas: 9
  # ...
---
# Deployment Canary (10% del tráfico)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment-canary
spec:
  replicas: 1
  # ...
```

>>>>>>> d811b45 (Commit inicial)
---

## 3. Sondas de Monitoreo de Salud (Health Probes)

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 2
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

### Sonda: `readinessProbe`
- **Función**: Comprueba si el proceso de la aplicación está listo para atender tráfico HTTP.
<<<<<<< HEAD
- **Por qué se coloca**: Cuando un contenedor Node.js inicia, tarda 1 a 3 segundos en levantar el puerto web. Sin `readinessProbe`, Kubernetes le envía tráfico inmediatamente, causando respuestas `502 Bad Gateway` a los usuarios.
- **Qué pasa si falla la prueba**: Kubernetes retira temporalmente la IP de ese Pod de la lista de Endpoints del Servicio hasta que responda HTTP 200 OK.

### Sonda: `livenessProbe`
- **Función**: Comprueba si el contenedor sigue funcionando correctamente en el tiempo.
- **Qué pasa si falla la prueba**: Kubernetes destruye el contenedor bloqueado y crea una nueva instancia de reemplazo automáticamente.

---

## 4. Matriz de Errores y Diagnóstico en Kubernetes
=======
- **Por qué se coloca**: Evita enviar tráfico a contenedores que aún están inicializando (evita respuestas 502 Bad Gateway).

---

---

## 4. Conceptos Avanzados de Infraestructura en K8s

### A. Recursos y HPA (El Requisito Obligatorio)
- **Regla de Oro**: Para que un `HorizontalPodAutoscaler` (HPA) funcione, **ES OBLIGATORIO** declarar `resources.requests.cpu` en la especificación de los contenedores del Deployment.
- **Qué pasa si no se coloca**: `kubectl get hpa` mostrará `TARGETS: <unknown>/50%` y el autosescalador **NO escalará ningún pod** cuando suba la carga.

```yaml
resources:
  requests:
    cpu: "100m"     # 0.1 CPU virtual (Mínimo reservado)
    memory: "128Mi"
  limits:
    cpu: "500m"     # Máximo permitido antes de ser limitado
    memory: "256Mi" # Máximo permitido (Si lo excede -> OOMKilled)
```

### B. Mapeo de Puertos en Kubernetes
- **`port` (en el Service)**: Puerto expuesto hacia dentro del clúster (ej. `port: 80`).
- **`targetPort` (en el Service)**: Puerto interno donde escucha la aplicación dentro del Pod (ej. `targetPort: 8080`).
- **`containerPort` (en el Deployment)**: Documenta el puerto del contenedor (debe coincidir con `targetPort`).
- **`nodePort` (en Services de tipo NodePort)**: Puerto expuesto externamente en cada nodo del clúster (rango 30000-32767).

### C. Inyección de Configuración: ConfigMaps y Secrets
```yaml
envFrom:
  - configMapRef:
      name: web-config
  - secretRef:
      name: web-secret
```
- **ConfigMap**: Guarda configuraciones en texto plano (puertos, niveles de log).
- **Secret**: Guarda credenciales o tokens codificados en base64. Si una clave requerida por la app no existe en el Secret, el pod entrará en `CreateContainerConfigError`.

### D. Namespaces y DNS Interno
- Los pods se comunican entre namespaces distintos usando el FQDN (Fully Qualified Domain Name):
  `<nombre-servicio>.<nombre-namespace>.svc.cluster.local`
- **Ejemplo**: `web-service.prod.svc.cluster.local:8080`.

### E. PodDisruptionBudget (PDB)
Garantiza que un número mínimo de réplicas se mantenga activo durante tareas de mantenimiento del clúster (ej. evacuación de nodos).
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: webapp
```

---

## 5. Matriz de Errores y Diagnóstico Avanzado en Kubernetes
>>>>>>> d811b45 (Commit inicial)

| Error | Mensaje / Síntoma | Causa Raíz | Solución Paso a Paso |
| :--- | :--- | :--- | :--- |
| Endpoints vacíos | `ENDPOINTS: <none>` | Etiqueta en `template.metadata.labels` no coincide con `Service.spec.selector`. | 1. Ejecutar `kubectl describe svc web-service`.<br>2. Revisar selector (`app: webapp`).<br>3. Cambiar etiqueta del Pod a `app: webapp`. |
<<<<<<< HEAD
| Error de validación | `selector does not match template labels` | `matchLabels` del Deployment no coincide con `template.metadata.labels`. | Asegurar que `matchLabels` y `template.metadata.labels` tengan valores idénticos. |
| Caída de pods | `CrashLoopBackOff` | La aplicación dentro del contenedor colapsa al arrancar (ej. error de sintaxis JS). | 1. Ejecutar `kubectl logs <nombre-pod>`.<br>2. Inspeccionar la traza de excepción.<br>3. Corregir el código de la app. |
=======
| Validation Error | `selector does not match template labels` | `matchLabels` del Deployment no coincide con `template.metadata.labels`. | Asegurar que `matchLabels` y `template.metadata.labels` tengan valores idénticos. |
| CrashLoopBackOff | `CrashLoopBackOff` | La aplicación dentro del contenedor colapsa al arrancar o la sonda de salud falla. | 1. Ejecutar `kubectl logs <nombre-pod>`.<br>2. Revisar si la ruta de la `readinessProbe` devuelve 404.<br>3. Corregir código o ruta de sonda. |
| HPA sin métricas | `TARGETS: <unknown>/50%` | Falta la directiva `resources.requests.cpu` en los contenedores del Deployment. | Agregar el bloque `resources.requests.cpu` a cada contenedor en `deployment.yaml`. |
| Pod matado por memoria | `OOMKilled` (Exit Code 137) | El contenedor intentó usar más memoria RAM que la declarada en `resources.limits.memory`. | Incrementar `resources.limits.memory` (ej. de 256Mi a 512Mi) en el Deployment. |
| Error de imagen | `ImagePullBackOff` / `ErrImagePull` | El tag o nombre de la imagen no existe o el registro privado requiere credenciales. | 1. Verificar el tag en `spec.containers[].image`.<br>2. Agregar `imagePullSecrets` si el registro es privado. |
| Error de configuración | `CreateContainerConfigError` | El Deployment referencia un `ConfigMap` o `Secret` que no existe en el clúster. | Crear el `ConfigMap`/`Secret` faltante antes de aplicar el Deployment. |

>>>>>>> d811b45 (Commit inicial)
