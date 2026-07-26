# Guía de Diagnóstico y Análisis de Infraestructura

Metodología estándar para el aislamiento y resolución de incidencias en contenedores, clústeres y flujos de integración.

---

## Diagnóstico en Entornos Docker (Reto 1)

### Incidencia: El contenedor ejecuta pero no responde a solicitudes HTTP

```text
[Verificar Código Fuente] ---> Host binding = 0.0.0.0 & PORT = 8080
            │
            ▼
[Verificar Dockerfile] ---> EXPOSE 8080 (Coincidir con puerto del codigo)
            │
            ▼
[Verificar Mapeo CLI] ---> docker run -p 8080:8080
```

1. **Revisar código fuente del servidor**:
   - Confirmar binding en `0.0.0.0` y no en `127.0.0.1`.
2. **Revisar archivo de construcción (`Dockerfile`)**:
   - Verificar la directiva `EXPOSE 8080`.
   ```dockerfile
   # RETO 1: Si server.js escucha en 8080, cambiar EXPOSE 3000 a 8080 AQUI
   EXPOSE 8080
   ```
3. **Validar estado de red del contenedor**:
   ```bash
   docker logs <nombre_contenedor>
   docker exec -it <nombre_contenedor> netstat -tlpn
   curl -i http://localhost:8080
   ```

---

## Diagnóstico en Kubernetes (Reto 2 y El Giro)

### Incidencia: Pods en estado Running pero el Servicio no entrega tráfico

1. **Inspeccionar estado del Servicio**:
   ```bash
   kubectl get svc
   kubectl describe svc <nombre_servicio>
   ```
2. **Validar Endpoints asociados**:
   ```bash
   kubectl get endpoints <nombre_servicio>
   ```
   - Si la columna `ENDPOINTS` muestra `<none>`, las etiquetas no coinciden.
3. **Verificar consistencia de selectores**:
   - Confirmar que `Service.spec.selector.app` coincida exactamente con `Deployment.spec.template.metadata.labels.app`.
   ```yaml
   # RETO 2: Sincronizar etiquetas en el manifiesto
   apiVersion: apps/v1
   kind: Deployment
   spec:
     template:
       metadata:
         labels:
           app: webapp # CAMBIAR AQUI SI DECIA 'app: web'
   ```

### Preparación para "El Giro" (Tráfico Triplicado y Cero Caídas)

```yaml
# EL GIRO: Ajuste en Deployment para alta disponibilidad
spec:
  replicas: 6 # CAMBIAR AQUI DE 2 A 6 PARA ABSORBER EL TRIPLE DE TRAFICO
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0 # CAMBIAR AQUI A 0 PARA GARANTIZAR CERO CAIDAS
```

<<<<<<< HEAD
=======
### Comprobación de Zero-Downtime y Generación de Tráfico (El Giro)

Para demostrar en vivo que el despliegue o escalado no interrumpe el servicio, ejecuta este bucle de prueba desde tu terminal:

```bash
# Script de verificación continua HTTP (Muestra código de estado cada 200ms)
while true; do curl -s -o /dev/null -w "Estado HTTP: %{http_code} | Tiempo: %{time_total}s\n" http://localhost:8080; sleep 0.2; done
```
*Si durante la actualización del Deployment (`kubectl apply`) todas las respuestas son `200` y no hay ningún `502` o `Connection Refused`, has demostrado Zero-Downtime exitosamente.*

### Comandos de Diagnóstico Avanzado en Kubernetes

```bash
# 1. Verificar métricas de consumo en tiempo real de los Pods (CPU y RAM)
kubectl top pods

# 2. Verificar estado del Autosescalador de Pods (HPA)
kubectl get hpa

# 3. Buscar la causa raíz de Pods en CrashLoopBackOff u OOMKilled
kubectl describe pod <nombre-pod> | grep -E "State:|Last State:|Exit Code:|Reason:"

# 4. Inspeccionar eventos recientes del clúster ordenados por fecha
kubectl get events --sort-by='.metadata.creationTimestamp'

# 5. Probar conectividad DNS y HTTP desde DENTRO del clúster
kubectl run test-pod --rm -i --tty --image=alpine -- sh
# Dentro del pod temporal:
# apk add curl
# curl http://web-service.default.svc.cluster.local:80
```

>>>>>>> d811b45 (Commit inicial)
---

## Diagnóstico en Pipelines de CI/CD (Reto 3)

### Incidencia: El pipeline despliega a pesar de errores en las pruebas

1. **Revisar la jerarquía de trabajos**:
   - Inspeccionar la propiedad `needs` en el archivo de flujo (`.github/workflows/ci.yml`).
2. **Verificar estructura del flujo**:
   ```yaml
   jobs:
     construccion-pruebas:
       runs-on: ubuntu-latest
       steps:
         - run: npm test

     despliegue:
       needs: construccion-pruebas # RETO 3: AGREGAR ESTA LINEA PARA BLOQUEAR DEPLOY EN CASO DE ERROR
       runs-on: ubuntu-latest
       steps:
         - run: echo "Desplegando..."
   ```
<<<<<<< HEAD
=======

>>>>>>> d811b45 (Commit inicial)
