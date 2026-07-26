# Guía de Arquitectura de Integración y Despliegue Continuo (CI/CD)

Documento de referencia para comprender la estructura de pipelines en GitHub Actions, control de dependencias entre trabajos y prevención de despliegues no deseados.

---

## 1. Estructura de Flujos en GitHub Actions

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
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test

  deploy:
    needs: build-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t app:${{ github.sha }} .
```

---

## 2. Explicación Detallada Línea por Línea

### Evento Detonador: `on.push.branches: [main]`
- **Para qué sirve**: Especifica qué evento del repositorio activa la ejecución automática del pipeline.
- **Por qué se coloca**: Para asegurar que cada vez que un desarrollador integre cambios a la rama principal (`main`), el código sea compilado, probado y desplegado automáticamente.
- **Alternativas**: `pull_request` (se ejecuta al abrir un PR antes de fusionar código).

### Trabajo: `build-test`
- **Para qué sirve**: Agrupa los pasos encargados de descargar el código, instalar dependencias y ejecutar las pruebas unitarias/integración.
- **Línea `runs-on: ubuntu-latest`**: Define el sistema operativo de la máquina virtual limpia donde correrá el proceso.
- **Paso `npm ci`**: Instala las dependencias exactamente como están declaradas en `package-lock.json`. Es más rápido y confiable en CI/CD que `npm install`.
- **Paso `npm test`**: Ejecuta el script de pruebas de la aplicación.
  - **Mecanismo de Control**: Si las pruebas pasan, `npm test` retorna un código de salida `0` (éxito). Si una prueba falla, retorna un código `!= 0` (error).

---

## 3. La Clave del Bloqueo: Dependencias de Trabajos (`needs`)

### Línea: `deploy.needs: build-test` (Reto 3)
- **Para qué sirve**: Establece una dependencia estricta que exige que el trabajo `build-test` se complete exitosamente (código `0`) **antes** de iniciar el trabajo `deploy`.
- **Por qué se coloca**: En GitHub Actions, por defecto todos los `jobs` se ejecutan simultáneamente en paralelo. Sin `needs`, el trabajo `deploy` arranca al mismo tiempo que `build-test`.
- **Qué pasa si se elimina `needs`**:
  - **SÍNTOMA DE FALLA (RETO 3)**: Si las pruebas fallan (`npm test` saliendo con código 1), el job `build-test` se marca como fallido, pero el job `deploy` continúa su ejecución y despliega código defectuoso a producción.
- **Qué pasa cuando `needs` está configurado correctamente**:
  - Si `npm test` falla, GitHub Actions marca `build-test` como `FAILED` y cambia automáticamente el estado del job `deploy` a `SKIPPED` (Cancelado/Omitido), bloqueando el despliegue.

---

<<<<<<< HEAD
## 4. Diagnóstico de Errores Comunes en CI/CD
=======
---

## 4. Patrones Avanzados en Pipelines CI/CD

### A. Autenticación Segura en Registros y Clústeres
Para subir imágenes a Docker Hub o aplicar manifiestos en K8s, se inyectan credenciales desde GitHub Secrets:
```yaml
- name: Autenticación en Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}

- name: Configurar KUBECONFIG
  run: |
    mkdir -p ~/.kube
    echo "${{ secrets.KUBECONFIG_BASE64 }}" | base64 -d > ~/.kube/config
```

### B. Rollback Automático ante Fallos de Despliegue
Si el paso de despliegue o la verificación posterior falla, se activa un paso de recuperación usando la condición `if: failure()`:
```yaml
  deploy:
    needs: build-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: kubectl set image deployment/web-deployment web=registry/app:${{ github.sha }}
      - name: Verificar despliegue
        run: kubectl rollout status deployment/web-deployment --timeout=60s
      - name: Rollback automático en caso de falla
        if: failure()
        run: kubectl rollout undo deployment/web-deployment
```

### C. Optimización de Caché
Acelera el pipeline reutilizando los paquetes descargados anteriormente:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

---

## 5. Diagnóstico de Errores Comunes y Avanzados en CI/CD
>>>>>>> d811b45 (Commit inicial)

| Error | Síntoma | Causa Raíz | Solución Paso a Paso |
| :--- | :--- | :--- | :--- |
| Despliegue con tests rotos | El job `deploy` se ejecuta a pesar de que `npm test` falló. | El job `deploy` no incluye la directiva `needs: build-test`. | 1. Abrir `.github/workflows/ci.yml`.<br>2. Agregar `needs: build-test` bajo la definición del job `deploy`. |
| Script de prueba inadecuado | `npm test` pasa en verde a pesar de haber errores en el código. | `package.json` tiene un comando dummy como `"test": "echo ok"`. | Escribir pruebas reales en JS que ejecuten `process.exit(1)` ante fallos. |
| Fallo en instalación de paquetes | `npm ci` falla durante el build. | El archivo `package-lock.json` no fue subido al repositorio Git. | Ejecutar `npm install` localmente y hacer commit de `package-lock.json`. |
<<<<<<< HEAD
=======
| Error de autenticación | `denied: requested access to the resource is denied` | Falta el paso de `docker login` o el token en GitHub Secrets venció. | Configurar `secrets.DOCKER_PASSWORD` y agregar `docker/login-action@v3`. |
| Timeout en despliegue | `kubectl rollout status timed out` | La nueva versión de la imagen entra en `CrashLoopBackOff` o falla la `readinessProbe`. | Inspeccionar los logs del pod con `kubectl logs` y aplicar `kubectl rollout undo`. |

>>>>>>> d811b45 (Commit inicial)
