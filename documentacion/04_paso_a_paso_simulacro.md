# Paso a Paso del Simulacro: Archivos con Errores vs Corregidos

Esta guía documenta exactamente lo que hicimos en el repositorio paso a paso. Muestra el código tal como estaba cuando presentaba la falla (el "antes") y el código modificado con la solución definitiva (el "después").

---

## 1. Reto 1: El contenedor que no responde (Puerto incorrecto)

**El Problema:** El código de la aplicación de la clase (`server.js`) levanta el servidor escuchando internamente en el puerto `3000`. Sin embargo, el archivo `Dockerfile` intentaba exponer a la red de Docker el puerto `8080`.

### ❌ Dockerfile (Con Error)
```dockerfile
# ... (código anterior omitido)
COPY --from=build /app/server.js ./server.js
USER node
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]
```

### ✅ Dockerfile (Corregido)
```diff
  COPY --from=build /app/server.js ./server.js
  USER node
- EXPOSE 8080
+ EXPOSE 3000
  HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
  CMD ["node", "server.js"]
```

---

## 2. Reto 2: Servicio ciego (Desajuste de Etiquetas)

**El Problema:** Los pods en Kubernetes se levantaban correctamente, pero al intentar acceder a la web no cargaba nada. Esto pasaba porque el Deployment le ponía la etiqueta `app: web` a sus pods, pero el Service (el balanceador de carga) estaba buscando a quién enviarle el tráfico usando la etiqueta `app: cicd-practica-sd`.

### ❌ k8s/deployment.yaml (Con Error)
```yaml
# ...
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
# ...
```

### ✅ k8s/deployment.yaml (Corregido)
```diff
    template:
      metadata:
        labels:
-         app: web
+         app: cicd-practica-sd
      spec:
        containers:
```

---

## 3. Reto 3: El pipeline frágil (Falta de dependencia)

**El Problema:** El pipeline en `.github/workflows/ci-cd.yml` tenía dos trabajos independientes. Para que sea verdaderamente CI/CD, el trabajo de despliegue (`build-push`) nunca debe arrancar si el de pruebas (`build-test`) falla. Como no estaban enlazados, un despliegue defectuoso llegaba a producción.

### ❌ ci-cd.yml (Con Error)
```yaml
  build-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
```

### ✅ ci-cd.yml (Corregido)
```diff
  build-push:
+   needs: build-test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
```

*(Para demostrar esto en el repositorio, rompimos intencionalmente el archivo `server.test.js` haciendo que esperara un `404` en vez de un `200`. Al correr el CI/CD, el trabajo `build-test` falló y bloqueó a `build-push`, demostrando que el pipeline ahora sí es seguro. Luego restauramos la prueba a `200`).*

---

## 4. El Giro Final: Avalancha de Tráfico (Escalamiento)

**El Escenario:** Marketing lanza una campaña sin avisar y el tráfico se va a triplicar. Hay que soportar esa avalancha de usuarios y hacer un despliegue que no corte la conexión de nadie (Zero-Downtime).

**La Solución:** Subir las réplicas del deployment de 4 a 12, garantizando que el despliegue es escalonado gracias a la estrategia `RollingUpdate` (que ya estaba en el archivo base, pero que ahora surte efecto masivo).

### ❌ k8s/deployment.yaml (Estado Inicial)
```yaml
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

### ✅ k8s/deployment.yaml (Estado Escalado)
```diff
  spec:
-   replicas: 4
+   replicas: 12
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 1
        maxSurge: 1
```
