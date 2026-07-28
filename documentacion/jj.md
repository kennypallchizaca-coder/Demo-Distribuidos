# Documentación de Práctica: Docker, Kubernetes y CI/CD

El presente documento expone la resolución técnica detallada de los 4 retos prácticos de la práctica. Se ha estructurado cumpliendo exactamente con las **Evidencias obligatorias** requeridas en la rúbrica de la práctica.

---

## Punto de Partida: Evidencia inicial obligatoria

1. **Captura o registro de la instalación de dependencias:**
   Ejecuta en tu terminal:
   ```bash
   npm install
   ```
   *(Colocar captura aquí)*

2. **Captura o registro de la ejecución exitosa de las pruebas iniciales:**
   Ejecuta en tu terminal:
   ```bash
   npm test
   ```
   *(Colocar captura aquí)*

3. **Captura o registro de la aplicación respondiendo localmente:**
   Ejecuta en tu terminal:
   ```bash
   npm start
   ```
   Y en otra terminal comprueba:
   ```bash
   curl -s http://localhost:8080/health
   ```
   *(Colocar captura aquí)*

---

## Reto 1 - Docker: Contenedor activo, aplicación inaccesible

### Diagnóstico del Problema y Solución Técnica
La aplicación en `server.js` estaba configurada internamente para escuchar en el puerto `8080`. Sin embargo, el archivo `dockerfile` original exponía erróneamente el puerto `3000`. Al existir esta discrepancia, la redirección de red desde la máquina anfitriona hacia el contenedor fallaba. La solución fue modificar el `EXPOSE` a `8080`.

**Antes (`dockerfile` original con el error):**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

**Después (`dockerfile` restaurado/corregido):**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Reto 1: Se expone el puerto 8080 (el mismo que usa server.js) 
EXPOSE 8080
CMD ["node", "server.js"]
```

### Evidencias Obligatorias del Reto 1

1. **Captura o registro del intento fallido de acceso inicial:**
   Para evidenciar el error original, cambia temporalmente tu `dockerfile` a `EXPOSE 3000` y ejecuta:
   ```bash
   docker build -t app-roto:latest .
   docker run -d -p 3000:3000 --name roto app-roto:latest
   curl http://localhost:3000
   ```
   *(Saldrá error connection refused. Colocar captura aquí)*

2. **Captura o registro que permita identificar el problema:**
   Abre el archivo `server.js` y toma una captura de la línea `const PORT = process.env.PORT || 8080;` demostrando que el código Node exige el puerto 8080.
   *(Colocar captura aquí)*

3. **Captura o registro del archivo corregido:**
   Restaura tu `dockerfile` a `EXPOSE 8080` y tómale captura al código.
   ```dockerfile
   FROM node:20-alpine
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   # Reto 1: Se expone el puerto 8080 (el mismo que usa server.js) 
   EXPOSE 8080
   CMD ["node", "server.js"]
   ```
   *(Colocar captura del archivo `dockerfile` corregido aquí)*

4. **Captura o registro de la construcción de la imagen:**
   Ejecuta en tu terminal con el dockerfile ya corregido:
   ```bash
   docker build -t app-ejemplo-evaluacion:latest .
   ```
   *(Colocar captura aquí)*

5. **Captura o registro del contenedor en ejecución:**
   Ejecuta en tu terminal:
   ```bash
   docker run -d --name reto1-demo -p 8080:8080 app-ejemplo-evaluacion:latest
   docker ps
   ```
   *(Colocar captura de `docker ps` mostrando el puerto 8080 activo aquí)*

6. **Captura o registro de la aplicación respondiendo correctamente desde la máquina anfitriona:**
   Ejecuta en tu terminal:
   ```bash
   curl -s http://localhost:8080/health
   ```
   *(Colocar captura del JSON exitoso aquí)*

---

## Reto 2 - Kubernetes: Pods listos, Service sin tráfico

### Diagnóstico del Problema y Solución Técnica
Las etiquetas asignadas a los pods (`app: web`) en el Deployment no coincidían con el selector de búsqueda del Service (`app: webapp`). Debido a esto, el Service no encontraba ningún destino válido (endpoints vacíos). Se unificaron las etiquetas en el manifiesto asegurando que ambas usen `app: web`.

**Antes (`kubernetes.yaml` original con el error en el Service):**
```yaml
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
```

**Después (`kubernetes.yaml` restaurado/corregido):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    # Reto 2: Se asegura que el selector coincida con los pods
    app: web  
  ports:
  - port: 80
    targetPort: 8080
```

### Evidencias Obligatorias del Reto 2

**Paso previo indispensable (si usas Minikube):**
Dado que construiste la imagen localmente en tu computadora en el Reto 1, debes inyectarla dentro del clúster de Minikube antes de aplicar el manifiesto para que Kubernetes la encuentre y no arroje el error `ErrImagePull`.
```bash
minikube image load app-ejemplo-evaluacion:latest
```

1. **Captura o registro de la aplicación del manifiesto inicial:**
   Para evidenciar el error, cambia temporalmente en `kubernetes.yaml` (en la zona del Service) el `app: web` por `app: webapp`. Luego ejecuta:
   ```bash
   kubectl apply -f kubernetes.yaml
   ```
   *(Colocar captura aquí)*

2. **Captura o registro de los pods en estado Running:**
   Ejecuta en tu terminal:
   ```bash
   kubectl get pods
   ```
   *(Colocar captura aquí)*

3. **Captura o registro del service sin endpoints o sin destinos válidos:**
   Ejecuta en tu terminal:
   ```bash
   kubectl describe service web-service
   ```
   *(Colocar captura mostrando que "Endpoints:" dice `<none>` aquí)*

4. **Captura o registro del manifiesto corregido:**
   Restaura `kubernetes.yaml` para que todo diga `app: web` y tómale captura al código.
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: web-service
   spec:
     selector:
       # Reto 2: Se asegura que el selector coincida con los pods
       app: web  
     ports:
     - port: 80
       targetPort: 8080
   ```
   *(Colocar captura del yaml corregido aquí)*

5. **Captura o registro del service con endpoints poblados:**
   Aplica el archivo corregido y describe el servicio:
   ```bash
   kubectl apply -f kubernetes.yaml
   kubectl describe service web-service
   ```
   *(Colocar captura mostrando las IPs en "Endpoints" aquí)*

6. **Captura o registro de una petición exitosa hacia la aplicación usando el servicio de Kubernetes:**
   Ejecuta el port-forward:
   ```bash
   kubectl port-forward service/web-service 8080:80
   ```
   Y en otra terminal comprueba:
   ```bash
   curl -s http://localhost:8080/health
   ```
   *(Colocar captura de las terminales o del navegador aquí)*

---

## Reto 3 - CI/CD: Despliegue ejecutado aunque las pruebas fallen

### Diagnóstico del Problema y Solución Técnica
El pipeline ejecutaba de forma asíncrona los trabajos `build-test` y `build-push`. Al no existir una dependencia declarada, el despliegue llegaba al registro incluso si el código estaba roto. Se solucionó añadiendo la directiva `needs: build-test` para obligar al paso final a esperar.

**Antes (`ci-cd.yml` original con el error):**
```yaml
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm test

  build-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Build y push de la imagen
```

**Después (`ci-cd.yml` restaurado/corregido):**
```yaml
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm test

  build-push:
    # Reto 3: Se añade 'needs' para evitar que se ejecute si test falla
    needs: build-test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Build y push de la imagen
```

### Evidencias Obligatorias del Reto 3

1. **Captura o registro del pipeline inicial:**
   Abre el archivo `.github/workflows/ci-cd.yml` y **borra temporalmente** la línea que dice `needs: build-test` para dejarlo como venía originalmente. Toma captura de este código:
   **Código original (defectuoso):**
   ```yaml
     build-push:
       runs-on: ubuntu-latest
       permissions:
   ```
   *(Colocar captura de código del pipeline original sin el 'needs' aquí)*

2. **Captura o registro de una prueba fallida provocada intencionalmente:**
   Abre tu archivo `server.js` y modifica la línea 7 para romper la prueba de la ruta de salud.
   **Código original (sano):**
   ```javascript
     if (req.url === '/' || req.url === '/health') {
   ```
   **Código modificado (roto intencionalmente):**
   ```javascript
     if (req.url === '/ruta-rota') {
   ```
   Luego ejecuta localmente en la terminal:
   ```bash
   npm test
   ```
   *(Colocar captura del error arrojado en la consola local aquí)*

3. **Captura o registro que demuestre el comportamiento defectuoso del pipeline inicial:**
   Asegúrate de no tener el `needs: build-test` en tu pipeline y con el `server.js` roto, sube los cambios:
   ```bash
   git add .
   git commit -m "Simulando pipeline defectuoso"
   git push origin main
   ```
   *(Ir a GitHub Actions y colocar captura mostrando que el "deploy" o "build-push" avanzó a pesar de que "test" falló)*

4. **Captura o registro del archivo de workflow corregido:**
   Abre nuevamente `.github/workflows/ci-cd.yml` y restaura el código añadiendo la instrucción `needs: build-test`. Toma captura del archivo modificado:
   **Código modificado (arreglado):**
   ```yaml
     build-push:
       # Reto 3: Se condiciona el despliegue al resultado exitoso de las pruebas
       needs: build-test
       runs-on: ubuntu-latest
   ```
   *(Colocar captura de código de tu yaml corregido aquí)*

5. **Captura o registro de una ejecución con pruebas fallidas donde el despliegue no se ejecute:**
   Con tu `server.js` aún roto, pero el pipeline ya corregido (con `needs`), sube a GitHub:
   ```bash
   git add .
   git commit -m "Probando workflow corregido bloqueando error"
   git push origin main
   ```
   *(Ir a GitHub Actions y colocar captura mostrando que "test" falla y, por tanto, "deploy" aparece cancelado o con un símbolo gris de omitido)*

6. **Captura o registro de una ejecución final exitosa con pruebas aprobadas y despliegue ejecutado:**
   Restaura `server.js` eliminando el error intencional de la línea 7 para que las pruebas vuelvan a pasar.
   **Código modificado (roto intencionalmente):**
   ```javascript
     if (req.url === '/ruta-rota') {
   ```
   **Código restaurado (sano):**
   ```javascript
     if (req.url === '/' || req.url === '/health') {
   ```
   Haz commit y push:
   ```bash
   git add .
   git commit -m "Solución definitiva Reto 3 con pruebas pasando"
   git push origin main
   ```
   *(Ir a GitHub Actions y colocar captura mostrando todo el flujo secuencial verde: test exitoso seguido de deploy exitoso)*

---

## Reto 4 - Operación: Escalamiento y despliegue sin interrupción

### Diagnóstico del Problema y Solución Técnica
Se requería preparar la aplicación para triplicar su tráfico base y garantizar futuras versiones sin caídas. En `kubernetes.yaml`, se escalaron las réplicas de 2 a 6 y se implementó la estrategia `RollingUpdate` con `maxUnavailable: 1`.

**Antes (`kubernetes.yaml` estado original del Deployment):**
```yaml
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
```

**Después (`kubernetes.yaml` modificado con estrategia y escalamiento):**
```yaml
spec:
  # Reto 4: Escalamiento de 2 a 6 replicas (el triple de trafico)
  replicas: 6
  # Reto 4: Estrategia de Rolling Update para cero interrupciones
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

### Evidencias Obligatorias del Reto 4

1. **Captura o registro del estado inicial del Deployment:**
   Para evidenciar el inicio, pon `replicas: 2` en tu yaml temporalmente, aplica y ejecuta:
   ```bash
   kubectl apply -f kubernetes.yaml
   kubectl get deployments
   ```
   *(Colocar captura mostrando 2/2 réplicas listas aquí)*

2. **Captura o registro del cambio aplicado para soportar mayor tráfico:**
   Cambia en el yaml a `replicas: 6` y toma captura al código.
   ```yaml
   spec:
     # Reto 4: Escalamiento de 2 a 6 replicas (el triple de trafico)
     replicas: 6
   ```
   *(Colocar captura de código aquí)*

3. **Captura o registro de la estrategia de despliegue utilizada:**
   Añade el bloque de RollingUpdate al yaml y toma captura al código.
   ```yaml
     # Reto 4: Estrategia de Rolling Update para cero interrupciones
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxUnavailable: 1
         maxSurge: 1
   ```
   *(Colocar captura de código aquí)*

4. **Captura o registro de tráfico de prueba durante el despliegue:**
   Aplica los cambios (`kubectl apply -f kubernetes.yaml`), asegúrate de que el port-forward esté activo, y en otra terminal ejecuta un bucle infinito:
   ```bash
   while true; do curl -s http://localhost:8080/health; sleep 0.5; done
   ```
   *(Colocar captura de las peticiones fluyendo de forma continua aquí)*

5. **Captura o registro que demuestre que la aplicación siguió respondiendo durante o después de la actualización:**
   Sin detener el bucle del paso anterior, actualiza la imagen forzando un despliegue:
   ```bash
   kubectl set image deployment/web-deployment web=app-ejemplo-evaluacion:v2
   kubectl rollout status deployment/web-deployment
   ```
   *(Colocar captura donde se vean ambas terminales: una mostrando el "rollout" paso a paso terminando pods, y la otra con el bucle `curl` sin arrojar ningún error de conexión)*

---

## Preguntas de Repaso (Teoría y Conceptos)

*(Aquí se mantienen las mismas 5 respuestas teóricas ya generadas anteriormente en el documento...)*

**1. ¿Por qué el Dockerfile ejecuta `npm test` dentro del build...?**
La ejecución de pruebas en la etapa de construcción no es redundante, es la aplicación del principio arquitectónico de *Fail Fast*. Automatizarlo en el Dockerfile asegura que la imagen construida sea una fuente inmutable de la verdad. Si un desarrollador omite las pruebas locales, la creación de la imagen fallará, garantizando la calidad del artefacto antes de ser subido.

**2. En el Paso 6, ¿qué habría pasado si `maxUnavailable` fuera igual a 4...?**
Si `maxUnavailable` fuera igual al total de réplicas, Kubernetes tendría la orden de eliminar todos los contenedores antiguos a la vez antes de asegurar que los nuevos están listos, provocando un *Downtime* o caída total del servicio durante el proceso de actualización.

**3. El pipeline de este ejercicio no tiene aprobación humana antes de llegar a Kubernetes... ¿Continuous Delivery o Continuous Deployment?**
El modelo implementado es **Continuous Delivery (Entrega Continua)**. El pipeline compila, prueba y empaqueta el artefacto dejándolo *listo para producción*, pero la instanciación en Kubernetes exige intervención humana consciente (`kubectl set image`). En Continuous Deployment, esta última acción sería automática.

**4. En el Paso 7, ¿qué ocurrió exactamente con el pod que quedó a medio actualizar...?**
El contenedor fue instanciado exitosamente (*Running*), pero como se inyectó una falla deliberada, no superó la prueba `readinessProbe`. Al no estar *Ready*, el Service impidió enrutar tráfico hacia él, aislando la falla. Kubernetes retiene este contenedor defectuoso intencionalmente en lugar de borrarlo para permitir la inspección de logs.

**5. Si en vez de readinessProbe no hubiera ningún probe configurado...?**
Sin un `readinessProbe`, el *Service* funciona a ciegas: habría considerado al contenedor listo en el instante preciso de su inicio y comenzaría a enviarle tráfico de forma inmediata. Los usuarios habrían sido derivados hacia contenedores defectuosos experimentando errores (500) hasta ejecutarse un Rollback manual.