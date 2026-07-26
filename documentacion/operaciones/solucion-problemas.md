# Guía de Análisis de Errores Comunes con Ejemplos de Código

Esta guía contiene los errores más frecuentes cometidos en configuraciones de Docker, Kubernetes y GitHub Actions, explicando la razón técnica del fallo, qué pasaría si no se soluciona, cómo identificarlo y la corrección exacta paso a paso.

---

<<<<<<< HEAD
## 1. Errores Comunes en Docker (Reto 1)

### Error 1.1: Discrepancia de Puertos (EXPOSE vs Código Fuente)

- **Por qué ocurre**: Ocurre cuando el desarrollador especifica una directiva `EXPOSE 3000` en el `Dockerfile`, pero el proceso Node.js en `server.js` fue programado para escuchar en el puerto `8080`.
- **Síntoma**: El contenedor inicia correctamente en `docker run`, pero al acceder en el navegador o mediante `curl http://localhost:3000` la conexión es rechazada (`ERR_CONNECTION_REFUSED`).
- **Qué pasa si no se corrige**: La aplicación nunca podrá recibir peticiones desde el exterior.
- **Cómo identificarlo**: Ejecutar `docker logs <id_contenedor>` y revisar qué puerto reporta la aplicación en sus registros de inicio.

#### Código Defectuoso (`server.js` vs `Dockerfile`):

```js
// server.js
const http = require('http');
const PORT = 8080; // El servidor escucha internamente en el puerto 8080

http.createServer((req, res) => {
  res.end('OK');
}).listen(PORT);
```

```dockerfile
# Dockerfile DEFECTUOSO
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# [ERROR]: Declara el puerto 3000, pero server.js escucha en 8080
EXPOSE 3000

CMD ["node", "server.js"]
```

#### Código Corregido (`Dockerfile`):

```dockerfile
# Dockerfile CORREGIDO (RETO 1)
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# [OK]: CAMBIAR DE 3000 A 8080 PARA COINCIDIR CON SERVER.JS
EXPOSE 8080

CMD ["node", "server.js"]
```

---

### Error 1.2: Vincular la Aplicación a Localhost (`127.0.0.1`)

- **Por qué ocurre**: La función `server.listen(8080, '127.0.0.1')` vincula el proceso a la interfaz de loopback interna del contenedor.
- **Qué pasa si no se corrige**: El contenedor se aísla de la red virtual de Docker y rechaza cualquier petición proveniente de la máquina host.
- **Solución**: Reemplazar `127.0.0.1` por `0.0.0.0` (todas las interfaces de red).

```js
// server.js CORREGIDO
const http = require('http');
const PORT = process.env.PORT || 8080;

// [OK]: CAMBIAR A '0.0.0.0' PARA ACEPTAR TRAFICO EXTERNO DEL CONTENEDOR
http.createServer((req, res) => {
  res.end('OK');
}).listen(PORT, '0.0.0.0');
```

---

## 2. Errores Comunes en Kubernetes (Reto 2)

### Error 2.1: Desconexión entre Servicio y Pods (Selector Incoherente)

- **Por qué ocurre**: El `Service` utiliza etiquetas Clave-Valor (`labels`) para descubrir Pods. Si `Service.spec.selector.app` busca `webapp`, pero la plantilla del Deployment genera Pods con `app: web`, el Servicio no encuentra a nadie.
- **Síntoma**: Los Pods están en estado `Running`, pero el Servicio no responde y la consulta `kubectl get endpoints web-service` muestra `ENDPOINTS: <none>`.
- **Cómo identificarlo**: Ejecutar `kubectl describe service web-service` y verificar la línea `Endpoints:`.

#### Código YAML Defectuoso (`k8s.yaml`):

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
        # [ERROR]: El pod tiene la etiqueta 'app: web'
        app: web
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
    # [ERROR]: El servicio busca 'app: webapp', pero el pod dice 'app: web'
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
```

#### Código YAML Corregido (`k8s.yaml`):

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
        # [OK]: CAMBIAR DE 'app: web' A 'app: webapp' PARA SINCRONIZAR CON EL SERVICIO
        app: webapp
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
    # [OK]: Coincide exactamente con el pod ('app: webapp')
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
```

---

## 3. Errores Comunes en GitHub Actions (Reto 3)

### Error 3.1: Ejecución del Despliegue con Pruebas Rotas (Falta de `needs`)

- **Por qué ocurre**: Los trabajos (`jobs`) en GitHub Actions se ejecutan en paralelo por defecto a menos que se defina la directiva `needs`.
- **Síntoma**: El trabajo de pruebas unitarias falla con código de salida `1`, pero el trabajo de despliegue se ejecuta inmediatamente y publica el código roto.
- **Solución**: Agregar `needs: build-test` en la definición del trabajo `deploy`.

```yaml
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  deploy:
    # [OK]: AGREGAR 'needs: build-test' PARA BLOQUEAR DESPLIEGUE SI FALLA TEST
    needs: build-test
    runs-on: ubuntu-latest
    steps:
      - run: echo "Desplegando..."
```

---

## 4. Errores Comunes en Despliegues de Alta Disponibilidad (El Giro)

### Error 4.1: Caída de Servicio Durante Actualización de Versión

- **Por qué ocurre**: Durante un despliegue, si se destruyen Pods activos antes de confirmar que las nuevas instancias están respondiendo solicitudes HTTP 200 OK, los usuarios experimentan errores `502 Bad Gateway`.
- **Solución para Zero-Downtime**:
  1. Configurar `maxUnavailable: 0` en `strategy.rollingUpdate`.
  2. Incluir `readinessProbe` con la ruta `/` y puerto `8080`.

```yaml
spec:
  # EL GIRO (TRAFICO MASIVO): CAMBIAR REPLICAS DE 2 A 6
  replicas: 6

  # EL GIRO (ZERO DOWNTIME): maxUnavailable: 0 GARANTIZA NINGUN POD CAIDO DURANTE TRANSICION
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0

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
        # EL GIRO: AGREGAR readinessProbe PARA VERIFICAR 200 OK ANTES DE ENVIAR TRAFICO
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 5
```
=======
## 1. Errores Comunes en Docker (Reto 1 & Variantes)

### Error 1.1: Discrepancia de Puertos (EXPOSE vs Código Fuente)
- **Por qué ocurre**: Ocurre cuando la directiva `EXPOSE` en el `Dockerfile` declara un puerto distinto al que realmente escucha el proceso interno.
- **Síntoma**: El contenedor inicia correctamente en `docker run`, pero al acceder mediante `curl http://localhost:3000` se obtiene `Connection refused`.

#### Ejemplos por Lenguaje:
- **Node.js**: `server.listen(8080)` -> `EXPOSE 8080`
- **Python (Flask / FastAPI)**: `app.run(host='0.0.0.0', port=5000)` -> `EXPOSE 5000`
- **Java (Spring Boot)**: `server.port=8080` -> `EXPOSE 8080`
- **Go**: `http.ListenAndServe(":8080", nil)` -> `EXPOSE 8080`

### Error 1.2: Vincular la Aplicación a Localhost (`127.0.0.1`)
- **Por qué ocurre**: `127.0.0.1` aísla el proceso al loopback del contenedor.
- **Solución**: Reemplazar `127.0.0.1` por `0.0.0.0` en el archivo principal de la aplicación.

---

## 2. Errores Comunes en Kubernetes (Reto 2 & Variantes)

### Error 2.1: Endpoints Vacíos (`ENDPOINTS: <none>`)
- **Por qué ocurre**: `Service.spec.selector.app` busca `webapp`, pero el Pod tiene `app: web`.
- **Solución**: Igualar `template.metadata.labels.app: webapp` en `k8s.yaml`.

### Error 2.2: Pod en `ImagePullBackOff` o `ErrImagePull`
- **Por qué ocurre**: El nombre de la imagen o tag especificado en `spec.containers[].image` no existe en el registro local o privado.
- **Cómo identificarlo**: Ejecutar `kubectl describe pod <pod_name>` e inspeccionar los eventos al final.
- **Solución**: Corregir el nombre de la imagen (ej: `practice:v1`) o construir la imagen localmente.

### Error 2.3: Pod en `CrashLoopBackOff`
- **Por qué ocurre**: La aplicación falla al iniciar (excepción en código, falta de dependencia o puerto/ruta errónea en la sonda de salud).
- **Cómo identificarlo**: Ejecutar `kubectl logs <pod_name>`.
- **Solución**: Corregir el código fuente de la app o ajustar la ruta/puerto en `readinessProbe` y `livenessProbe`.

### Error 2.4: Autosescalador HPA en Estado `<unknown>`
- **Por qué ocurre**: El objeto `HorizontalPodAutoscaler` no puede calcular el uso porcentual de CPU porque el `Deployment` no define la propiedad `resources.requests.cpu`.
- **Cómo identificarlo**: Ejecutar `kubectl get hpa` y observar la columna `TARGETS` mostrando `<unknown>/50%`.
- **Solución**: Agregar la sección `resources.requests` en el `Deployment`:
  ```yaml
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
  ```

### Error 2.5: Pod Interrumpido con `OOMKilled` (Exit Code 137)
- **Por qué ocurre**: El contenedor consumió más memoria RAM que el límite máximo asignado en `resources.limits.memory`.
- **Cómo identificarlo**: `kubectl describe pod <pod_name>` muestra `Reason: OOMKilled` y `Exit Code: 137`.
- **Solución**: Optimizar el uso de memoria en la aplicación o incrementar la cuota `memory` en `resources.limits`.

### Error 2.6: Desconexión de Puertos entre Service y Container (`targetPort` Mismatch)
- **Por qué ocurre**: El selector del `Service` encuentra los Pods, pero `targetPort` está configurado en un puerto donde el contenedor no está escuchando (ej. `targetPort: 3000` cuando la app corre en `8080`).
- **Síntoma**: Los Endpoints existen (`kubectl get endpoints`), pero al acceder al Service la petición se queda colgada o da `Connection refused`.
- **Solución**: Asegurar que `Service.spec.ports[].targetPort` coincida exactamente con `Deployment.spec.template.spec.containers[].ports[].containerPort`.

---

## 3. Errores Comunes en GitHub Actions (Reto 3 & Variantes)

### Error 3.1: Ejecución del Despliegue con Pruebas Rotas
- **Por qué ocurre**: Falta la directiva `needs: build-test` en el job `deploy`.
- **Solución**: Agregar `needs: build-test` bajo la declaración del job de despliegue en `.github/workflows/ci.yml`.

### Error 3.2: Fallo de Autenticación al Hacer Push de la Imagen
- **Por qué ocurre**: El job de despliegue intenta hacer `docker push` sin haberse autenticado previamente en el registro de imágenes.
- **Síntoma**: Log de GitHub Actions muestra `denied: requested access to the resource is denied`.
- **Solución**: Agregar el paso de autenticación con `docker/login-action@v3` usando credenciales de `secrets.DOCKER_USERNAME` y `secrets.DOCKER_PASSWORD`.

---

## 4. Estrategias de Despliegue para "El Giro"

### Opción 1: RollingUpdate (Zero-Downtime)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2
    maxUnavailable: 0
```

### Opción 2: Blue-Green Deployment
```yaml
# En k8s.yaml del Service, cambiar 'version: blue' por 'version: green'
spec:
  selector:
    app: webapp
    version: green
```

### Opción 3: Canary Deployment
```yaml
# Mantener 9 réplicas de la versión estable y 1 réplica de la versión canaria
# Servicio apunta a app: webapp (recibirá 90% tráfico estable y 10% canario)
```

>>>>>>> d811b45 (Commit inicial)
