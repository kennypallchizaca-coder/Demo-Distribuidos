# Cheat Sheet: Comandos Esenciales (CI/CD y DevOps)

Esta lista contiene exclusivamente comandos útiles, libres de adornos, listos para copiar, pegar o adaptar durante tu evaluación práctica.

## Git y GitHub CLI
**Sobrescribir el historial remoto por completo (Push forzado)**
Útil cuando debes deshacer un error crítico en el pipeline que ensució la historia.
```bash
git push -f origin main
```

**Ver el historial resumido con códigos hash (Ideal para tags de Docker)**
```bash
git log --oneline -n 5
```

## Docker Local
**Construir imagen usando variables y forzar que no use caché**
```bash
docker build --no-cache -t mi-app:v1 --build-arg APP_VERSION=v2 .
```

**Verificar por qué falló un contenedor recién creado**
```bash
docker logs <id_contenedor>
```

**Entrar al shell de un contenedor en ejecución (para revisar puertos o archivos)**
```bash
docker exec -it <id_contenedor> sh
```

## Kubernetes (kubectl)
**Ver el estado global (qué está fallando a simple vista)**
```bash
kubectl get all
```

**Diagnóstico profundo de un Pod (Muestra los Probes, Límites y Eventos)**
```bash
kubectl describe pod <nombre-del-pod>
```

**Leer los logs en vivo de un Pod que está fallando**
```bash
kubectl logs -f <nombre-del-pod>
```

**Comprobar que el balanceador de carga encontró a los pods**
```bash
kubectl get endpoints <nombre-del-service>
```

**Actualizar la imagen de un Deployment al vuelo (El disparador del CD)**
```bash
kubectl set image deployment/<nombre-deploy> <nombre-contenedor>=<nueva-imagen:tag>
```

**Monitorear un despliegue (Rolling Update) en tiempo real**
```bash
kubectl rollout status deployment/<nombre-deploy>
```

**Deshacer un despliegue roto (Rollback inmediato)**
```bash
kubectl rollout undo deployment/<nombre-deploy>
```

**Ver el historial de revisiones antes de hacer Rollback**
```bash
kubectl rollout history deployment/<nombre-deploy>
```
