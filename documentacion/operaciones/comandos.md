# Comandos Frecuentes de CLI (PowerShell y Bash)

Documentación de referencia de comandos para Docker, Kubernetes (`kubectl`) y Git, adaptados tanto para PowerShell (Windows) como para Bash (Linux / macOS).

---

## 1. Comandos de Docker

Los comandos de Docker son idénticos en PowerShell y Bash, a excepción del encadenamiento de comandos en PowerShell.

```powershell
# Construcción de imagen
docker build -t <nombre_imagen>:<tag> .

# Listar imágenes locales
docker images

# Ejecutar contenedor en segundo plano con puerto expuesto
docker run -d -p <puerto_host>:<puerto_contenedor> --name <nombre_contenedor> <nombre_imagen>:<tag>

# Listar contenedores activos
docker ps

# Listar todos los contenedores (incluyendo detenidos)
docker ps -a

# Ver registros / logs de un contenedor
docker logs <id_contenedor>
docker logs -f --tail 100 <id_contenedor>

# Entrar a la terminal interactiva dentro del contenedor
docker exec -it <id_contenedor> sh

# Detener y eliminar contenedor
docker stop <id_contenedor>
docker rm <id_contenedor>
```

---

## 2. Comandos de Kubernetes (`kubectl`)

### Inspección General
```powershell
# Estado de Pods, Servicios, Deployments y Endpoints
kubectl get pods
kubectl get svc
kubectl get deployments
kubectl get endpoints
kubectl get hpa

# Inspección detallada de eventos
kubectl describe pod <nombre_pod>
kubectl describe svc <nombre_servicio>
kubectl describe deployment <nombre_deployment>

# Logs de ejecución
kubectl logs <nombre_pod>
kubectl logs -f <nombre_pod>
```

### Aplicar Manifiestos
```powershell
# Aplicar archivo YAML
kubectl apply -f manifiesto.yaml

# Validar sintaxis en seco (Dry Run)
kubectl apply --dry-run=client -f manifiesto.yaml

# Redirección de puertos local
kubectl port-forward svc/<nombre_servicio> 8080:80
```

### Escalado y Operaciones
```powershell
# Escalar réplicas manualmente
kubectl scale deployment/<nombre_deployment> --replicas=6

# Actualizar imagen en tiempo de ejecución
kubectl set image deployment/<nombre_deployment> <nombre_contenedor>=<nueva_imagen>:<tag>

# Estado del despliegue progresivo
kubectl rollout status deployment/<nombre_deployment>

# Revertir despliegue (Rollback)
kubectl rollout undo deployment/<nombre_deployment>
```

---

## 3. Diferencias de Sintaxis: PowerShell (Windows) vs Bash (Linux / Mac)

### A. Encadenar Varios Comandos
- **PowerShell**: Usar punto y coma `;`
  ```powershell
  git add . ; git commit -m "feat: cambios" ; git push
  ```
- **Bash**: Usar `&&`
  ```bash
  git add . && git commit -m "feat: cambios" && git push
  ```

### B. Pruebas de Tráfico con `curl`
- **PowerShell**: En PowerShell `curl` es un alias de `Invoke-WebRequest`. Se recomienda llamar a `curl.exe` explícitamente:
  ```powershell
  curl.exe -i http://localhost:8080
  ```
- **Bash**:
  ```bash
  curl -i http://localhost:8080
  ```

### C. Bucles Infinitos para Probar Tráfico en Vivo
- **PowerShell**:
  ```powershell
  while ($true) { curl.exe -s -o $null -w "%{http_code}`n" http://localhost:8080 ; Start-Sleep -Milliseconds 200 }
  ```
- **Bash**:
  ```bash
  while true; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080; sleep 0.2; done
  ```
