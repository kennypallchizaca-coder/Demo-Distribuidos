# Notas Técnicas de Laboratorios y Casos Prácticos

<<<<<<< HEAD
Documento de referencia con la resolución detallada de escenarios de laboratorio, mostrando el código defectuoso de origen, los errores generados y la corrección paso a paso.
=======
Documento de referencia con la resolución detallada de escenarios de laboratorio, mostrando el código defectuoso de origen, la explicación técnica del fallo, el procedimiento de diagnóstico, la corrección paso a paso y la justificación para la defensa del examen.
>>>>>>> d811b45 (Commit inicial)

---

## Caso Práctico 1: El Contenedor que "Corre" pero no Responde (Docker)

### 1. Escenario Inicial y Código Defectuoso
Al construir la imagen y ejecutar el contenedor, la aplicación aparece activa en `docker ps`, pero no responde al realizar solicitudes HTTP.

#### Archivo `server.js` de Origen:
```javascript
const http = require('http');
const PORT = 8080; // El proceso Node escucha internamente en el puerto 8080

http.createServer((req, res) => {
  res.end('OK');
}).listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on port ${PORT}`);
});
```

#### Archivo `Dockerfile` Defectuoso:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3000 # [ERROR]: Declara el puerto 3000 mientras que server.js escucha en 8080

CMD ["node", "server.js"]
```

<<<<<<< HEAD
### 2. Diagnóstico y Comando de Error
- **Comando de prueba ejecutado**: `docker run -d -p 3000:3000 practice:v1`
=======
### 2. Explicación Técnica del Fallo
- **Por qué ocurre**: La directiva `EXPOSE 3000` le indica a Docker que el contenedor escuchará en el puerto 3000. Sin embargo, el código Node.js en `server.js` está programado para abrir el socket en el puerto `8080`.
- **Impacto**: Cuando ejecutas `docker run -p 3000:3000`, Docker redirige el tráfico del host al puerto 3000 interno del contenedor, donde ningún proceso está escuchando, resultando en rechazo de conexión.

### 3. Diagnóstico y Registro de Salida
- **Comando ejecutado**: `docker run -d -p 3000:3000 practice:v1`
>>>>>>> d811b45 (Commit inicial)
- **Resultado observado**:
  ```bash
  curl -i http://localhost:3000
  # curl: (7) Failed to connect to localhost port 3000: Connection refused
  ```
<<<<<<< HEAD
- **Revisión de registros**: `docker logs app_container` muestra `Server listening on port 8080`.

### 3. Solución Aplicada
Se corrigió la directiva `EXPOSE` en el `Dockerfile` cambiándola a `8080`.
=======
- **Revisión de logs**: `docker logs <id_contenedor>` muestra `Server listening on port 8080`.

### 4. Solución Aplicada
Se cambió la directiva `EXPOSE` en el `Dockerfile` a `8080`.
>>>>>>> d811b45 (Commit inicial)

#### Archivo `Dockerfile` Corregido:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

<<<<<<< HEAD
EXPOSE 8080 # [OK]: Expone el puerto correcto 8080
=======
EXPOSE 8080 # [OK]: Sincronizado con el puerto 8080 de server.js
>>>>>>> d811b45 (Commit inicial)

CMD ["node", "server.js"]
```

<<<<<<< HEAD
=======
### 5. Justificación para la Defensa del Examen
- **Pregunta del docente**: *¿Por qué el contenedor figuraba en estado Running si no respondía a curl?*
- **Respuesta exacta**: *El proceso Node se ejecutaba correctamente dentro del sistema de archivos aislado, por lo que el contenedor no colapsaba. Sin embargo, existía un desbalance entre el puerto expuesto por Dockerfile (3000) y el puerto de escucha del proceso (8080). La solución fue corregir EXPOSE 8080 y mapear el puerto 8080 del host.*

>>>>>>> d811b45 (Commit inicial)
---

## Caso Práctico 2: Pods en Estado Running pero Servicio Sin Respuesta (Kubernetes)

### 1. Escenario Inicial y Manifiesto Defectuoso
<<<<<<< HEAD
Todos los pods figuran en estado `Running` al ejecutar `kubectl get pods`. Sin embargo, las peticiones HTTP al `Service` fallan.
=======
Todos los Pods figuran en estado `Running` al ejecutar `kubectl get pods`. Sin embargo, las peticiones HTTP dirigidas al `Service` fallan con error de timeout o servicio no disponible.
>>>>>>> d811b45 (Commit inicial)

#### Manifiesto `k8s.yaml` Defectuoso:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
<<<<<<< HEAD
        app: web   # [ERROR]: Etiqueta del pod es 'app: web'
=======
        app: web   # [ERROR]: Etiqueta asignada al Pod es 'app: web'
>>>>>>> d811b45 (Commit inicial)
    spec:
      containers:
      - name: web
        image: practice:v1
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
<<<<<<< HEAD
    app: webapp  # [ERROR]: El selector busca 'app: webapp' y no encuentra pods
=======
    app: webapp  # [ERROR]: El selector busca 'app: webapp' y no encuentra coincidencia
>>>>>>> d811b45 (Commit inicial)
  ports:
  - port: 80
    targetPort: 8080
```

<<<<<<< HEAD
### 2. Diagnóstico y Registro de Salida
=======
### 2. Explicación Técnica del Fallo
- **Por qué ocurre**: Los objetos `Service` en Kubernetes no descubren Pods por nombre ni por IP fija, sino mediante consultas de etiquetas (*Label Selectors*).
- **Impacto**: El `Service` buscaba Pods con la clave `app: webapp`. Como el `Deployment` creaba Pods etiquetados como `app: web`, el filtro no devolvió ninguna coincidencia, dejando la lista de Endpoints vacía.

### 3. Diagnóstico y Registro de Salida
>>>>>>> d811b45 (Commit inicial)
- **Comando de diagnóstico**: `kubectl get endpoints web-service`
- **Salida obtenida**:
  ```text
  NAME          ENDPOINTS
<<<<<<< HEAD
  web-service   <none>    # Endpoints vacíos por incoherencia de etiquetas
  ```

### 3. Solución Aplicada
Se cambió la etiqueta de la plantilla del pod a `app: webapp`.
=======
  web-service   <none>    # Endpoints vacíos por desalineación de etiquetas
  ```

### 4. Solución Aplicada
Se corrigió la etiqueta en la plantilla del Pod (`template.metadata.labels`) cambiando `app: web` por `app: webapp`.
>>>>>>> d811b45 (Commit inicial)

#### Manifiesto `k8s.yaml` Corregido:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
<<<<<<< HEAD
        app: webapp  # [OK]: Sincronizado con selector 'app: webapp'
=======
        app: webapp  # [OK]: Coincide con selector 'app: webapp'
>>>>>>> d811b45 (Commit inicial)
    spec:
      containers:
      - name: web
        image: practice:v1
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
<<<<<<< HEAD
    app: webapp  # [OK]: Coincide exactamente con las etiquetas del pod
=======
    app: webapp  # [OK]: Filtro sincronizado
>>>>>>> d811b45 (Commit inicial)
  ports:
  - port: 80
    targetPort: 8080
```

<<<<<<< HEAD
=======
### 5. Justificación para la Defensa del Examen
- **Pregunta del docente**: *¿Por qué el Service no entregaba tráfico si los Pods estaban en estado Running?*
- **Respuesta exacta**: *Porque en Kubernetes los Pods se asocian al Service mediante etiquetas de red. La etiqueta del Pod decía app: web mientras que el selector del Service buscaba app: webapp. Al inspeccionar kubectl get endpoints web-service vi que aparecía <none>. Al sincronizar ambas etiquetas a app: webapp, Kubernetes pobló automáticamente las IP de los Pods detras del servicio.*

>>>>>>> d811b45 (Commit inicial)
---

## Caso Práctico 3: Pipeline que Despliega con Pruebas Rotas (CI/CD)

### 1. Escenario Inicial y Workflow Defectuoso
<<<<<<< HEAD
Se simula el fallo de una prueba en `package.json` (`"test": "exit 1"`). Al hacer `git push`, el pipeline ejecuta la etapa de despliegue a pesar de la falla.
=======
Se simula el fallo de una prueba unitaria modificando el script de test (`"test": "exit 1"`). Al subir el código con `git push`, el pipeline ejecuta la etapa de despliegue a pesar del fallo en la etapa de pruebas.
>>>>>>> d811b45 (Commit inicial)

#### Flujo `.github/workflows/ci.yml` Defectuoso:
```yaml
name: ci-cd
on:
  push:
    branches: [main]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
<<<<<<< HEAD
      - run: npm test # Este paso falla con exit status 1

  deploy:
    runs-on: ubuntu-latest # [ERROR]: Falta 'needs: build-test'
=======
      - run: npm test # [FALLO]: Retorna exit status 1

  deploy:
    runs-on: ubuntu-latest # [ERROR]: No declara relación de dependencia con build-test
>>>>>>> d811b45 (Commit inicial)
    steps:
      - run: docker build -t app:${{ github.sha }} .
```

<<<<<<< HEAD
### 2. Solución Aplicada
Se agregó la cláusula `needs: build-test` en la tarea `deploy`.
=======
### 2. Explicación Técnica del Fallo
- **Por qué ocurre**: En GitHub Actions, por defecto todos los trabajos (*jobs*) declarados en el archivo YAML se ejecutan de manera simultánea e independiente en máquinas virtuales paralelas.
- **Impacto**: Sin una regla de dependencia explícita, el trabajo `deploy` se inicia inmediatamente al recibir el evento de push, sin esperar el resultado ni el estado de salida de `build-test`.

### 3. Diagnóstico y Registro de Salida
- **Comando de prueba**: Romper la prueba cambiando la aserción en `server.test.js` o forzando `exit 1` en `package.json`.
- **Salida en GitHub Actions**: Job `build-test` se marca en rojo (`FAILED`), pero el job `deploy` se marca en verde (`SUCCESS`) y aplica los cambios en el clúster.

### 4. Solución Aplicada
Se agregó la directiva `needs: build-test` al job `deploy`.
>>>>>>> d811b45 (Commit inicial)

#### Flujo `.github/workflows/ci.yml` Corregido:
```yaml
name: ci-cd
on:
  push:
    branches: [main]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  deploy:
<<<<<<< HEAD
    needs: build-test # [OK]: Cancela deploy si build-test falla
=======
    needs: build-test # [OK]: Cancela el despliegue si build-test falla
>>>>>>> d811b45 (Commit inicial)
    runs-on: ubuntu-latest
    steps:
      - run: docker build -t app:${{ github.sha }} .
```

<<<<<<< HEAD
=======
### 5. Justificación para la Defensa del Examen
- **Pregunta del docente**: *¿Cómo funciona la directiva `needs` en GitHub Actions?*
- **Respuesta exacta**: *Crea una dependencia en el Grafo Dirigido Acíclico (DAG) del workflow. Al colocar needs: build-test en el job deploy, GitHub Actions evalúa el código de salida del job previo. Si npm test devuelve un Exit Code distinto de 0 (error), el job build-test falla y automaticamente marca el job deploy como SKIPPED, bloqueando el despliegue.*

>>>>>>> d811b45 (Commit inicial)
---

## Caso Práctico 4: Escalado y Despliegue Zero-Downtime (El Giro)

### 1. Requerimientos de Producción
<<<<<<< HEAD
Tráfico triplicado. El próximo despliegue no debe causar caídas perceptibles en el servicio.
=======
Se espera un incremento del triple de tráfico y se exige que el despliegue de una nueva versión no genere ninguna caída perceptible de servicio (Zero-Downtime).

### 2. Explicación Técnica de la Solución
- **Para absorber el tráfico**: Se incrementan las réplicas de 2 a 6.
- **Para cero caídas**: Se utiliza la estrategia `RollingUpdate` con `maxUnavailable: 0` y `maxSurge: 2`.
  - `maxUnavailable: 0` garantiza que el 100% de los Pods activos sigan respondiendo peticiones durante la transición.
  - `maxSurge: 2` permite a Kubernetes crear 2 Pods nuevos con la versión actualizada antes de apagar los Pods con la versión antigua.
- **Sonda de disponibilidad (`readinessProbe`)**: Asegura que el servicio no enrute tráfico a los nuevos Pods hasta que la aplicación haya completado su arranque interno y responda HTTP 200.
>>>>>>> d811b45 (Commit inicial)

#### Configuración Corregida de Alta Disponibilidad (`k8s.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
<<<<<<< HEAD
  replicas: 6 # Réplicas incrementadas a 6
=======
  replicas: 6 # Réplicas incrementadas para alta disponibilidad
>>>>>>> d811b45 (Commit inicial)
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
<<<<<<< HEAD
      maxUnavailable: 0 # Garantiza que el 100% de los pods activos sigan atendiendo tráfico
=======
      maxUnavailable: 0 # Garantiza cero pods indisponibles durante actualización
>>>>>>> d811b45 (Commit inicial)
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
        readinessProbe: # Habilita tráfico solo cuando la app responde HTTP 200
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
<<<<<<< HEAD
=======
```

---

## Caso Práctico 5: Escenario Avanzado de Examen Complejo

### 1. Escenario Inicial
Se solicita desplegar la aplicación garantizando:
1. Autoescalado dinámico por CPU sin errores de métricas.
2. Inyección segura de secretos y variables de entorno.
3. Despliegue con rollback automático si la nueva versión falla.
4. Demostración empírica de Zero-Downtime bajo carga simulada.

### 2. Manifiesto Completo de Producción (`k8s-avanzado.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: webapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
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
        resources:
          requests:
            cpu: 100m       # OBLIGATORIO PARA QUE HPA PUEDA CALCULAR METRICAS
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
>>>>>>> d811b45 (Commit inicial)
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```
<<<<<<< HEAD
=======

### 3. Ejecución de Prueba de Carga y Verificación de Cero Caídas
1. En una terminal, iniciar el generador de tráfico:
   ```bash
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080; sleep 0.1; done
   ```
2. En otra terminal, aplicar la actualización de la versión:
   ```bash
   kubectl set image deployment/web-deployment web=practice:v3
   ```
3. Observar la salida de `curl`: Si todas las líneas muestran `200` y no hay errores `502`, la actualización se realizó con cero caídas perceptibles.
4. Verificar el autosescalado:
   ```bash
   kubectl get hpa web-hpa
   # Salida esperada: TARGETS 45%/50% REPLICAS 3 -> 6
   ```

---

## Catálogo Completo de Errores en Exámenes: Explicación Técnica y Solución Paso a Paso

### 1. Errores Frecuentes en Docker

#### Error 1.1: Puerto Expuesto no Coincide con el Código Fuente
- **Dónde está el error**: En la directiva `EXPOSE` del `Dockerfile` (ejemplo: `EXPOSE 3000`) cuando el código en `server.js` abre el puerto en `8080`.
- **Explicación técnica**: Dockerfile es la plantilla de construcción. Si `EXPOSE` no coincide con el puerto real de escucha del proceso, la redirección del puerto host `-p 3000:3000` envía paquetes a un socket no abierto dentro del contenedor.
- **Síntoma**: `curl: (7) Failed to connect to localhost port 3000: Connection refused`.
- **Solución paso a paso**:
  1. Revisar el puerto de escucha en el código fuente (`server.js`: `const PORT = 8080`).
  2. Editar `Dockerfile` y cambiar la línea a `EXPOSE 8080`.
  3. Reconstruir la imagen: `docker build -t app:v1 .`.
  4. Ejecutar el contenedor: `docker run -d -p 8080:8080 app:v1`.
- **Justificación para el examen**: *Se corrige EXPOSE para sincronizar la declaración de red del contenedor con el puerto real en el que el proceso Node crea el servidor HTTP.*

#### Error 1.2: Servidor Escuchando Únicamente en Localhost (`127.0.0.1`)
- **Dónde está el error**: En la llamada al método de escucha en el código de la app (ejemplo: `server.listen(8080, '127.0.0.1')`).
- **Explicación técnica**: La dirección `127.0.0.1` aísla el servidor al loopback interno del contenedor. Ninguna petición externa que ingrese por la interfaz virtual del contenedor (`eth0`) será aceptada.
- **Síntoma**: `Empty response from server` o `Connection reset by peer`.
- **Solución paso a paso**:
  1. Abrir `server.js` (o archivo equivalente).
  2. Cambiar la IP de escucha a `'0.0.0.0'`:
     ```javascript
     server.listen(PORT, '0.0.0.0', () => {
       console.log(`Servidor listo en puerto ${PORT}`);
     });
     ```
- **Justificación para el examen**: *Vincular la aplicación a 0.0.0.0 le permite escuchar en todas las interfaces de red del contenedor, aceptando el tráfico enrutado desde el host.*

#### Error 1.3: Proceso Principal Ignora Señales de Apagado (Forma Shell vs Exec)
- **Dónde está el error**: En la directiva `CMD` escrita en formato de texto libre (ejemplo: `CMD node server.js`).
- **Explicación técnica**: Al usar Forma Shell, Docker ejecuta `/bin/sh -c "node server.js"`. La shell corre como PID 1 y no reenvía señales del sistema operativo (`SIGTERM`) al proceso hijo `node`.
- **Síntoma**: Al ejecutar `docker stop`, el contenedor tarda 10 segundos en responder y termina de forma abrupta por desbordamiento de tiempo (`SIGKILL`).
- **Solución paso a paso**:
  1. Editar el `Dockerfile`.
  2. Cambiar la línea a Forma Exec (sintaxis de arreglo JSON):
     ```dockerfile
     CMD ["node", "server.js"]
     ```
- **Justificación para el examen**: *La Forma Exec asigna PID 1 directamente al proceso de la app, permitiendo recibir señales de apagado limpio (Graceful Shutdown).*

#### Error 1.4: Falta de Archivo `.dockerignore`
- **Dónde está el error**: Ausencia del archivo `.dockerignore` en el directorio raíz del proyecto.
- **Explicación técnica**: `docker build` envía todo el contenido del directorio de trabajo al demonio de Docker como contexto de construcción. Sin `.dockerignore`, se envían gigabytes de la carpeta local `node_modules`.
- **Síntoma**: Construcción extremadamente lenta y fallos por binarios incompatibles entre Windows y Linux.
- **Solución paso a paso**:
  1. Crear un archivo llamado `.dockerignore` en la raíz del proyecto.
  2. Agregar el contenido:
     ```text
     node_modules
     .git
     npm-debug.log
     ```
- **Justificación para el examen**: *Evita transferir archivos innecesarios al contexto de build, optimizando el tiempo de construcción de minutos a segundos.*

---

### 2. Errores Frecuentes en Kubernetes

#### Error 2.1: Desalineación entre Selector del Servicio y Etiquetas del Pod
- **Dónde está el error**: En `Service.spec.selector` vs `Deployment.spec.template.metadata.labels`.
- **Explicación técnica**: Kubernetes enlaza de forma dinámica los Servicios con los Pods mediante filtros de etiquetas (Labels). Si los pares clave-valor no coinciden de forma idéntica, el controlador Endpoint no asigna direcciones IP al Servicio.
- **Síntoma**: `kubectl get endpoints` devuelve `<none>`. Las peticiones HTTP al Servicio responden `503 Service Unavailable`.
- **Solución paso a paso**:
  1. Ejecutar `kubectl describe svc web-service` para verificar el selector configurado (ejemplo: `app=webapp`).
  2. Editar el `Deployment` en `k8s.yaml` e igualar la etiqueta del Pod:
     ```yaml
     template:
       metadata:
         labels:
           app: webapp
     ```
- **Justificación para el examen**: *Se sincronizan las etiquetas para que el filtro del Service reconozca a los Pods del Deployment y pueble la lista de Endpoints con sus direcciones IP internas.*

#### Error 2.2: Desalineación entre MatchLabels del Deployment y su Plantilla
- **Dónde está el error**: En `Deployment.spec.selector.matchLabels` vs `Deployment.spec.template.metadata.labels`.
- **Explicación técnica**: El Deployment exige que su selector `matchLabels` sea exactamente igual a las etiquetas declaradas en la plantilla de Pods que él mismo va a administrar.
- **Síntoma**: Al aplicar el archivo YAML con `kubectl apply`, la API de Kubernetes retorna `ValidationError: selector does not match template labels`.
- **Solución paso a paso**:
  1. Editar el manifiesto del `Deployment`.
  2. Igualar los valores de ambos bloques:
     ```yaml
     spec:
       selector:
         matchLabels:
           app: webapp
       template:
         metadata:
           labels:
             app: webapp
     ```
- **Justificación para el examen**: *Kubernetes rechaza manifiestos donde el selector del Deployment difiera de la plantilla de Pods para evitar crear Pods huérfanos.*

#### Error 2.3: Incoherencia entre `targetPort` del Service y Puerto Real del Contenedor
- **Dónde está el error**: En `Service.spec.ports[].targetPort` apuntando a un puerto distinto de `containerPort`.
- **Explicación técnica**: `port` es el puerto de entrada del Servicio dentro del clúster; `targetPort` es el puerto de destino en los Pods. Si `targetPort` es incorrecto, el Servicio reenvía el tráfico a un puerto cerrado dentro del Pod.
- **Síntoma**: Endpoints poblados con IPs, pero las solicitudes HTTP devuelven `Connection refused` o no responden.
- **Solución paso a paso**:
  1. Verificar el puerto en el que escucha la app dentro del contenedor (ejemplo: 8080).
  2. Configurar `targetPort` con el mismo valor en el `Service`:
     ```yaml
     spec:
       ports:
       - port: 80
         targetPort: 8080
     ```
- **Justificación para el examen**: *Se asegura que el servicio redirija el tráfico entrante del puerto 80 exactamente al puerto 8080 donde la aplicación responde dentro del pod.*

#### Error 2.4: HPA Congelado en Estado `<unknown>/50%`
- **Dónde está el error**: En la especificación del contenedor en el `Deployment`, al omitir el bloque `resources.requests.cpu`.
- **Explicación técnica**: El `HorizontalPodAutoscaler` calcula la métrica relativa de consumo dividiendo el uso real de CPU entre la solicitud reservada (`requests.cpu`). Sin este parámetro base, la división por cero o valor nulo es imposible de calcular.
- **Síntoma**: `kubectl get hpa` muestra `TARGETS: <unknown>/50%` y el autosescalador no crea réplicas adicionales ante picos de tráfico.
- **Solución paso a paso**:
  1. Editar el `Deployment`.
  2. Declarar las solicitudes de recursos en el contenedor:
     ```yaml
     resources:
       requests:
         cpu: "100m"
         memory: "128Mi"
     ```
- **Justificación para el examen**: *Es obligatorio definir las solicitudes de recursos para establecer la línea base que le permite al HPA calcular el porcentaje de utilización y activar el autosescalado.*

#### Error 2.5: Pods en `CrashLoopBackOff` por Sondas de Salud Misconfiguradas
- **Dónde está el error**: En la propiedad `path` o `port` de `readinessProbe` o `livenessProbe` apuntando a un endpoint inexistente (ejemplo: `/health` en vez de `/`).
- **Explicación técnica**: Kubernetes realiza solicitudes HTTP a la ruta especificada. Si la aplicación devuelve un código HTTP 404 o timeout, K8s asume que el contenedor está defectuoso y lo reinicia en bucle o rehúsa asignarle tráfico.
- **Síntoma**: Pods en estado `CrashLoopBackOff` o `0/1 Running`.
- **Solución paso a paso**:
  1. Ejecutar `kubectl describe pod <nombre-pod>` y revisar la sección `Events` al final.
  2. Verificar los endpoints activos en el código fuente de la app.
  3. Corregir la ruta de la sonda en el manifiesto YAML:
     ```yaml
     readinessProbe:
       httpGet:
         path: /
         port: 8080
     ```
- **Justificación para el examen**: *Se corrige la ruta de la sonda para que retorne HTTP 200 OK cuando la app esté lista, permitiendo que K8s habilite el Pod para recibir tráfico.*

#### Error 2.6: Pods Matados por Exceso de Memoria (`OOMKilled`)
- **Dónde está el error**: Asignar un límite de memoria demasiado reducido en `resources.limits.memory` (ejemplo: `32Mi`).
- **Explicación técnica**: Cuando un contenedor intenta consumir más memoria RAM que la declarada en su límite, el kernel de Linux del nodo activa el recolector OOM (Out Of Memory Killer) y termina el proceso de forma inmediata.
- **Síntoma**: `kubectl describe pod` muestra `Reason: OOMKilled`, `Exit Code: 137`.
- **Solución paso a paso**:
  1. Aumentar la cuota de memoria en el manifiesto `Deployment`:
     ```yaml
     resources:
       limits:
         memory: "256Mi"
     ```
- **Justificación para el examen**: *Se ajustan los límites de recursos para darle el margen operativo de RAM que requiere el entorno de ejecución de Node/Java/Python.*

---

### 3. Errores Frecuentes en CI/CD (GitHub Actions)

#### Error 3.1: Despliegue Ejecutándose tras Fallo de Pruebas Unitarias
- **Dónde está el error**: En el archivo `.github/workflows/ci.yml`, al omitir la regla `needs: build-test` en el job `deploy`.
- **Explicación técnica**: En GitHub Actions los jobs corren en paralelo por defecto. Sin `needs`, el job de despliegue no tiene orden de precedencia y se ejecuta independientemente del estado de éxito o error del job de pruebas.
- **Síntoma**: `npm test` falla (Exit Code 1), pero el job `deploy` se ejecuta en verde y actualiza el entorno de producción con código defectuoso.
- **Solución paso a paso**:
  1. Abrir `.github/workflows/ci.yml`.
  2. Agregar `needs: build-test` bajo la declaración del job `deploy`:
     ```yaml
     jobs:
       build-test:
         runs-on: ubuntu-latest
         steps:
           - uses: actions/checkout@v4
           - run: npm ci
           - run: npm test

       deploy:
         needs: build-test
         runs-on: ubuntu-latest
         steps:
           - run: docker build -t app:${{ github.sha }} .
     ```
- **Justificación para el examen**: *Establece una dependencia estricta en el pipeline. Si npm test falla (Exit Code != 0), GitHub Actions omite (SKIPPED) el job de despliegue, protegiendo producción.*

#### Error 3.2: Fallo de Instalación en CI/CD por Falta de `package-lock.json`
- **Dónde está el error**: Ejecutar `npm ci` en el pipeline sin haber incluido el archivo `package-lock.json` en el repositorio Git.
- **Explicación técnica**: A diferencia de `npm install`, el comando `npm ci` exige la presencia obligatoria de `package-lock.json` para garantizar la instalación determinista y exacta de las dependencias.
- **Síntoma**: El job `build-test` falla en el paso `npm ci` con `npm ERR! The npm ci command can only install with an existing package-lock.json`.
- **Solución paso a paso**:
  1. Ejecutar `npm install` localmente para generar `package-lock.json`.
  2. Verificar que `package-lock.json` no esté en `.gitignore`.
  3. Hacer commit y push del archivo: `git add package-lock.json && git commit -m "fix: add package-lock.json"`.
- **Justificación para el examen**: *Se asegura la presencia del archivo de candado de dependencias para permitir instalaciones reproducibles y rápidas en entornos de CI/CD.*

---

### 4. Errores Frecuentes en "El Giro" (Alta Disponibilidad y Cero Caídas)

#### Error 4.1: Caída de Servicio Durante la Actualización de Pods
- **Dónde está el error**: En la estrategia de actualización del Deployment, al dejar `maxUnavailable: 1` cuando solo hay 1 réplica, o no definir `readinessProbe`.
- **Explicación técnica**: Si Kubernetes apaga el Pod antiguo antes de que el Pod nuevo haya completado su arranque e inicialización interna, las peticiones HTTP que ingresen durante ese intervalo de tiempo rebotan con errores de conexión.
- **Síntoma**: Al hacer peticiones continuas con `curl` mientras se aplica `kubectl apply`, la terminal registra respuestas `HTTP 502 Bad Gateway` o `Connection refused`.
- **Solución paso a paso**:
  1. Configurar la estrategia `RollingUpdate` con `maxUnavailable: 0` y `maxSurge: 2`:
     ```yaml
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxSurge: 2
         maxUnavailable: 0
     ```
  2. Agregar la sonda `readinessProbe` en la especificación del contenedor para validar respuestas HTTP 200 antes de dirigir tráfico.
- **Justificación para el examen**: *Configurar maxUnavailable: 0 obliga a K8s a mantener el 100% de la capacidad respondiendo tráfico, y readinessProbe asegura que los Pods nuevos solo reciban clientes cuando estén totalmente operativos.*
>>>>>>> d811b45 (Commit inicial)
