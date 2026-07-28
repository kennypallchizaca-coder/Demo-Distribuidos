# Cheat Sheet: Comandos Operativos y Ejemplos Prácticos

Este manual contiene los comandos esenciales que necesitarás ejecutar durante el examen para construir, verificar y administrar tus despliegues. Todos incluyen ejemplos prácticos.

---

## 1. Docker: Construcción y Pruebas Locales

Antes de mandar nada a Kubernetes, es crucial saber manipular la imagen localmente.

### Construir la imagen de Docker
Útil para verificar que el `Dockerfile` no tiene errores de sintaxis antes de subirlo.
**Comando base:**
```bash
docker build -t <nombre-imagen>:<tag> .
```
**Ejemplo Práctico (Pasando variables ARG):**
```bash
docker build -t mi-app:v1 --build-arg APP_VERSION=v2 --build-arg APP_COLOR=red .
```
*(Nota: El `.` al final indica que el Dockerfile está en el directorio actual).*

### Ejecutar el contenedor localmente (Prueba)
Sirve para verificar que la app expone el puerto correcto y arranca sin colapsar.
**Comando base:**
```bash
docker run -d --name <nombre-instancia> -p <puerto-host>:<puerto-contenedor> <nombre-imagen>:<tag>
```
**Ejemplo Práctico:**
```bash
docker run -d --name prueba-local -p 8080:3000 mi-app:v1
```
*(Luego puedes probar en tu navegador entrando a `http://localhost:8080`).*

### Ver logs de un contenedor fallido
Si el contenedor arranca pero la app interna colapsa.
**Ejemplo Práctico:**
```bash
docker logs prueba-local
```

### Entrar al contenedor (Troubleshooting)
Ideal para confirmar qué archivos se copiaron o en qué puerto está escuchando internamente.
**Ejemplo Práctico:**
```bash
docker exec -it prueba-local sh
```

---

## 2. Kubernetes: Inspección y Diagnóstico

### Ver el estado global
Muestra todos los Pods, Services y Deployments de un solo vistazo.
**Ejemplo Práctico:**
```bash
kubectl get all
```

### Ver si el Service conectó con los Pods (Súper Importante)
Si la app no responde en la web, siempre revisa esto. Si sale vacío, los "labels" del Pod no coinciden con el "selector" del Service.
**Comando base:**
```bash
kubectl get endpoints <nombre-del-servicio>
```
**Ejemplo Práctico:**
```bash
kubectl get endpoints cicd-practica-sd
```
*Salida esperada:* `10.244.0.5:3000, 10.244.0.6:3000`

### Investigar un Pod con problemas (Ej: CrashLoopBackOff)
Muestra los eventos recientes del Pod, por qué fallaron los Probes o si falta memoria.
**Comando base:**
```bash
kubectl describe pod <nombre-del-pod>
```
**Ejemplo Práctico:**
```bash
kubectl describe pod cicd-practica-sd-7f8d9b4c-kx2ab
```

### Leer logs en vivo de un Pod de Kubernetes
**Ejemplo Práctico:**
```bash
kubectl logs -f cicd-practica-sd-7f8d9b4c-kx2ab
```

---

## 3. Kubernetes: Operaciones de Despliegue (CD)

### Forzar la actualización de una imagen (Continuous Delivery)
Si no tienes GitHub Actions o quieres desplegar a mano.
**Comando base:**
```bash
kubectl set image deployment/<nombre-deploy> <nombre-contenedor>=<nueva-imagen:tag>
```
**Ejemplo Práctico:**
```bash
kubectl set image deployment/cicd-practica-sd app=ghcr.io/kennypallchizaca-coder/demo-distribuidos:v2
```

### Monitorear el progreso de la actualización (Rolling Update)
Te permite ver en vivo cómo se van apagando los pods viejos y encendiendo los nuevos.
**Ejemplo Práctico:**
```bash
kubectl rollout status deployment/cicd-practica-sd
```

### Emergencia: Deshacer el despliegue (Rollback)
Si inyectaste un bug a producción, esto te devuelve a la versión sana anterior instantáneamente.
**Ejemplo Práctico (Deshacer el último cambio):**
```bash
kubectl rollout undo deployment/cicd-practica-sd
```

**Ejemplo Práctico (Volver a una versión específica):**
```bash
kubectl rollout history deployment/cicd-practica-sd
kubectl rollout undo deployment/cicd-practica-sd --to-revision=2
```

---

## 4. Minikube (Entorno Local)

Si estás usando Minikube para levantar Kubernetes en tu máquina, estos te salvarán:

### Obtener la URL pública de tu aplicación
**Ejemplo Práctico:**
```bash
minikube service cicd-practica-sd --url
```

### Forzar a Minikube a usar la imagen de tu Docker local
A veces Minikube no encuentra tu imagen local. Debes cargarla explícitamente en el clúster.
**Ejemplo Práctico:**
```bash
minikube image load mi-app:v1
```

---

## 5. Git: Limpieza de Emergencia
Si por alguna razón metiste basura en el historial y necesitas forzar el código actual hacia GitHub destruyendo la historia de la nube.
**Ejemplo Práctico:**
```bash
git push -f origin main
```
