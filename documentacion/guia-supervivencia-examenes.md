# Guía de Supervivencia: Diagnóstico de Exámenes CI/CD y Kubernetes

Esta guía está diseñada para ayudarte a resolver problemas en exámenes prácticos que tengan requisitos distintos o inesperados.

## Metodología de Diagnóstico Universal

Frente a un problema donde "la app no funciona", no intentes adivinar. Sigue esta cadena de diagnóstico desde adentro hacia afuera:

### 1. El Código y Docker
Si el fallo ocurre apenas compilas:
- **¿Falla npm install/ci?** Revisa si hay un desajuste entre `package.json` y `package-lock.json`. En CI siempre usa `npm ci`.
- **¿La imagen construye pero falla al correr?** Revisa el ENTRYPOINT o CMD del Dockerfile.
- **¿Error de permisos en Docker?** Verifica si estás usando un usuario sin privilegios (`USER node`) que está intentando escribir en carpetas root.
- **¿Docker Login Falla en GitHub Actions?** Es un problema de permisos. Ve a la configuración de tu repositorio en GitHub > Actions > General > Workflow permissions > Cambia a "Read and Write permissions".
- **¿Invalid Tag / Repository name must be lowercase?** Docker prohíbe las mayúsculas en los nombres de imagen. Asegúrate de usar minúsculas en tu `IMAGE_NAME` dentro del pipeline.

### 2. Kubernetes: Nivel Pod (El Motor)
Si el Pod no está en estado "Running":
- **ImagePullBackOff / ErrImagePull:** 
  Kubernetes no encuentra la imagen. Revisa si la escribiste bien, si olvidaste poner el hash exacto del tag, o si la imagen en el Registry es privada y K8s no tiene las credenciales (imagePullSecrets).
- **CrashLoopBackOff:** 
  La app inicia pero colapsa de inmediato. Ejecuta `kubectl logs <nombre-del-pod>` para leer el stacktrace del error.
- **OOMKilled:** 
  Out of Memory. El contenedor excedió su límite de RAM. En tu archivo `.yaml`, en la sección `resources.limits.memory`, necesitas subir la asignación (ej. de `128Mi` a `256Mi`).

### 3. Kubernetes: Nivel Service (El Balanceador)
Si el Pod está en "Running" pero no responde en el navegador:
- **¿El Pod está "Ready" (1/1)?** Si dice (0/1), falló el `readinessProbe`. Kubernetes lo considera enfermo y lo aísla. Revisa con `kubectl describe pod <nombre>` por qué falla el probe (¿es la ruta incorrecta? ¿responde 500?).
- **¿El Service tiene Endpoints?** Ejecuta `kubectl get endpoints <nombre-del-service>`. Si no hay direcciones IP en la respuesta, el selector del Service NO COINCIDE con la etiqueta (labels) del Pod en el Deployment.

---

## Estrategias de Despliegue Avanzadas (Giros Típicos)

A los profesores les gusta pedir estrategias de despliegue como requisitos sorpresa. Aquí tienes cómo reconocerlas y aplicarlas:

### Rolling Update (Por defecto)
- **Qué es:** Reemplazo progresivo. Cero cortes de servicio.
- **Cómo aplicarlo:**
  ```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1 # Cuántos pods pueden caerse a la vez
      maxSurge: 1       # Cuántos pods extras se pueden crear a la vez
  ```

### Recreate
- **Qué es:** Apaga todos los pods viejos antes de prender los nuevos. Causa *downtime* intencional pero previene problemas de caché o bases de datos bloqueadas.
- **Cómo aplicarlo:**
  ```yaml
  strategy:
    type: Recreate
  ```

### Autoscaling (HPA)
- **Qué es:** Aumentar pods automáticamente si sube el consumo de CPU.
- **Cómo aplicarlo (Comando rápido):**
  `kubectl autoscale deployment mi-app --cpu-percent=70 --min=2 --max=10`
