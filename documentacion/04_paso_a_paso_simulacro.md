# Paso a Paso Exhaustivo: Simulacro CI/CD de Principio a Fin

Este documento detalla cada acción, cada comando en la terminal, y **el código completo** de los archivos en cada fase de la práctica. Puedes seguir esta guía literalmente paso a paso para recrear todo el examen desde cero.

---

## Fase 1: Inicialización del Proyecto Base

Empezamos creando la base de la aplicación.

### 1. Crear el servidor web (`server.js`)
**Código Completo:**
```javascript
const express = require('express');
const os = require('os');

const APP_VERSION = process.env.APP_VERSION || 'v1';
const APP_COLOR = process.env.APP_COLOR || 'blue';
const SIMULATE_FAILURE = process.env.SIMULATE_FAILURE === 'true';

function createApp() {
  const app = express();

  app.get('/health', (req, res) => {
    if (SIMULATE_FAILURE) {
      return res.status(500).json({ status: 'error', reason: 'fallo simulado' });
    }
    res.status(200).json({ status: 'ok' });
  });

  app.get('/version', (req, res) => {
    res.status(200).json({
      version: APP_VERSION,
      color: APP_COLOR,
      hostname: os.hostname(),
    });
  });

  app.get('/', (req, res) => {
    res.status(200).send(
      '<html><body style="font-family: sans-serif; background:' + APP_COLOR +
      '; color:white; text-align:center; padding-top:80px;">' +
      '<h1>Sistemas Distribuidos - CI/CD</h1>' +
      '<h2>Version desplegada: ' + APP_VERSION + '</h2>' +
      '<p>Pod: ' + os.hostname() + '</p>' +
      '</body></html>'
    );
  });

  return app;
}

if (require.main === module) {
  const app = createApp();
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log('Servidor escuchando en puerto ' + PORT + ' (version=' + APP_VERSION + ', color=' + APP_COLOR + ')');
  });
}

module.exports = { createApp };
```

### 2. Comandos de Inicialización (Terminal)
Inicializamos Node.js, instalamos `express`, y probamos localmente:
```bash
npm init -y
npm install express
node server.js
# Deberías ver: "Servidor escuchando en puerto 3000..."
# Presiona Ctrl+C para salir
```

---

## Fase 2: Implementando los Defectos (Reto 1, 2 y 3)

El examen exigía construir los archivos con errores predeterminados.

### 1. Dockerfile (Error: EXPOSE 8080)
La aplicación escucha en 3000, pero el Dockerfile expone el 8080.
**Código Completo (Roto):**
```dockerfile
# --- Etapa 1: instalar dependencias y correr las pruebas ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

# --- Etapa 2: imagen final ---
FROM node:20-alpine AS runtime
WORKDIR /app
ARG APP_VERSION=v1
ARG APP_COLOR=blue
ARG SIMULATE_FAILURE=false
ENV NODE_ENV=production
ENV APP_VERSION=$APP_VERSION
ENV APP_COLOR=$APP_COLOR
ENV SIMULATE_FAILURE=$SIMULATE_FAILURE
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/server.js ./server.js
USER node
# ERROR AQUI:
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]
```

### 2. Kubernetes Deployment (Error: app: web)
El Service buscará `app: cicd-practica-sd`, pero los pods se etiquetarán como `app: web`.
**Código Completo `k8s/deployment.yaml` (Roto):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cicd-practica-sd
  labels:
    app: cicd-practica-sd
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: cicd-practica-sd
  template:
    metadata:
      labels:
        # ERROR AQUI:
        app: web
    spec:
      containers:
        - name: app
          image: ghcr.io/kennypallchizaca-coder/demo-distribuidos:latest
          ports:
            - containerPort: 3000
          env:
            - name: PORT
              value: "3000"
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 2
            periodSeconds: 3
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
```

### 3. Pipeline CI/CD (Error: Falta la directiva 'needs')
No hay protección: el despliegue a producción arrancará aunque fallen las pruebas.
**Código Completo `.github/workflows/ci-cd.yml` (Roto):**
```yaml
name: ci-cd

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: kennypallchizaca-coder/demo-distribuidos

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Instalar dependencias (build reproducible)
        run: npm ci

      - name: Ejecutar pruebas
        run: npm test

  build-push:
    # ERROR AQUI: Falta "needs: build-test"
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Login en GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build y push de la imagen (build once, promote many)
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

### 4. Comandos para comprobar los fallos (Terminal)
```bash
# 1. Comprobar que Docker build funciona, pero el puerto no conecta
docker build -t mi-app-rota:v1 .
docker run -d -p 8080:3000 --name prueba1 mi-app-rota:v1
# Al entrar a http://localhost:8080 en el navegador, la conexion sera rechazada.

# 2. Comprobar que K8s levanta los pods, pero no los enlaza al Service
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods       # Aparecen en Running
kubectl get endpoints  # ¡Aparece vacio! (El error)
```

---

## Fase 3: Resolviendo los Defectos y Giro Final (12 Réplicas)

Aplicamos la solución a todos los problemas e incrementamos las réplicas como solicitaba el examen.

### 1. Dockerfile (Corregido)
Se cambió `EXPOSE 8080` a `EXPOSE 3000`.
**Código Completo (Corregido):**
```dockerfile
# --- Etapa 1: instalar dependencias y correr las pruebas ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

# --- Etapa 2: imagen final ---
FROM node:20-alpine AS runtime
WORKDIR /app
ARG APP_VERSION=v1
ARG APP_COLOR=blue
ARG SIMULATE_FAILURE=false
ENV NODE_ENV=production
ENV APP_VERSION=$APP_VERSION
ENV APP_COLOR=$APP_COLOR
ENV SIMULATE_FAILURE=$SIMULATE_FAILURE
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/server.js ./server.js
USER node
# SOLUCIONADO:
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]
```

### 2. Kubernetes Deployment (Corregido y Escalado a 12 Réplicas)
Se arregló la etiqueta `app: cicd-practica-sd` y se escaló a 12 réplicas (El Giro).
**Código Completo `k8s/deployment.yaml` (Corregido):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cicd-practica-sd
  labels:
    app: cicd-practica-sd
spec:
  # GIRO: Subir a 12 replicas
  replicas: 12
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: cicd-practica-sd
  template:
    metadata:
      labels:
        # SOLUCIONADO:
        app: cicd-practica-sd
    spec:
      containers:
        - name: app
          image: ghcr.io/kennypallchizaca-coder/demo-distribuidos:latest
          ports:
            - containerPort: 3000
          env:
            - name: PORT
              value: "3000"
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 2
            periodSeconds: 3
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "200m"
              memory: "128Mi"
```

### 3. Pipeline CI/CD (Corregido)
Se añadió `needs: build-test` para enlazar los trabajos de forma segura.
**Código Completo `.github/workflows/ci-cd.yml` (Corregido):**
```yaml
name: ci-cd

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: kennypallchizaca-coder/demo-distribuidos

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Instalar dependencias (build reproducible)
        run: npm ci

      - name: Ejecutar pruebas
        run: npm test

  build-push:
    # SOLUCIONADO:
    needs: build-test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Login en GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build y push de la imagen (build once, promote many)
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

### 4. Comandos de Verificación (Terminal)
Una vez guardados los archivos corregidos, comprobamos que K8s funciona y mandamos todo a GitHub.
```bash
# 1. Aplicar los arreglos en Kubernetes local
kubectl apply -f k8s/deployment.yaml

# 2. Comprobar que los endpoints ahora sí aparecen
kubectl get endpoints cicd-practica-sd
# Deberías ver 12 direcciones IP (una por cada réplica)

# 3. Guardar en Git y detonar el CI/CD exitoso
git add .
git commit -m "fix: resolver todos los retos y escalar a 12 replicas"
git push origin main
```
