# Proyecto de Orquestación Docker, Kubernetes, CI/CD y Alta Disponibilidad

Este repositorio contiene la arquitectura de referencia, código fuente, manifiestos y la documentación detallada para el diagnóstico, resolución de problemas y despliegue de aplicaciones en contenedores Docker, clústeres de Kubernetes y pipelines de GitHub Actions.

---

## Estructura General del Repositorio

```text
SIMULACIONXD/
├── Dockerfile                         # Archivo de construcción de imagen Docker (Puerto 8080)
├── server.js                          # Código fuente del servidor HTTP Node.js (Escucha en 0.0.0.0:8080)
├── test.js                            # Pruebas de integración automatizadas
├── package.json                       # Scripts de ejecución (npm start, npm test)
├── k8s.yaml                           # Manifiesto de Kubernetes (Deployment, Service, HPA)
├── .github/
│   └── workflows/
│       └── ci.yml                    # Pipeline de Integración Continua en GitHub Actions
└── documentacion/                     # Documentación técnica completa
    ├── README.md                      # Índice general de la documentación
    ├── inicio/
    │   └── guia-rapida.md            # Referencia de comprobación rápida y cuestionario de defensa oral
    ├── arquitectura/
    │   ├── docker.md                 # Conceptos y directivas de Docker
    │   ├── kubernetes.md             # Objetos y estrategias de Kubernetes
    │   └── integracion-continua.md   # Flujos y dependencias en CI/CD
    ├── patrones/                     # Plantillas estándar listas para producción
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── hpa.yaml
    │   ├── rolling-update.yaml
    │   ├── configmap.yaml
    │   ├── ingress.yaml
    │   ├── Dockerfile
    │   ├── .dockerignore
    │   ├── .gitignore
    │   ├── ci.yml
    │   └── package.json
    ├── operaciones/
    │   ├── comandos.md               # Cheatsheet de comandos CLI (PowerShell y Bash)
    │   ├── diagnostico.md            # Metodología de diagnóstico y aislamiento de fallas
    │   └── solucion-problemas.md     # Matriz de errores comunes y correcciones
    ├── practicas/
    │   └── notas-laboratorio.md      # Casos prácticos resueltos paso a paso y soluciones explicadas
    └── scripts/
        ├── verificar.ps1             # Asistente de diagnóstico automático en PowerShell
        └── verificar.sh              # Asistente de diagnóstico automático en Bash
```

---

## Resumen de Problemas Resueltos (Retos 1 al 3 y El Giro)

### 1. Reto 1: Contenedor Docker no responde
- **Diagnóstico**: La aplicación `server.js` escucha en el puerto `8080`, mientras que el `Dockerfile` inicial declaraba `EXPOSE 3000`.
- **Solución**: Se actualizó `Dockerfile` con `EXPOSE 8080` y se aseguró la escucha en `0.0.0.0`.

### 2. Reto 2: Servicio Kubernetes sin respuesta (Endpoints vacíos)
- **Diagnóstico**: El `Service` buscaba la etiqueta `app: webapp`, pero los Pods se crearon con `app: web`. Al no coincidir, `kubectl get endpoints` mostraba `<none>`.
- **Solución**: Se igualaron las etiquetas en `k8s.yaml` a `app: webapp`.

### 3. Reto 3: Pipeline despliega con pruebas fallidas
- **Diagnóstico**: El trabajo de despliegue en GitHub Actions se ejecutaba en paralelo sin verificar el resultado del trabajo de pruebas.
- **Solución**: Se añadió la directiva `needs: build-test` en la tarea `deploy` para cancelar el despliegue cuando las pruebas fallan.

### 4. El Giro: Alta Disponibilidad y Despliegue Zero-Downtime
- **Diagnóstico**: Pico de tráfico 3x y requisito de actualización sin caídas de servicio.
- **Solución**: Se incrementaron las réplicas a **6**, se configuró `RollingUpdate` con `maxUnavailable: 0`, se añadieron sondas `readinessProbe` y `livenessProbe`, y se habilitó un `HorizontalPodAutoscaler` (HPA).

---

## Asistente Automático de Diagnóstico (Scripts de Ayuda)

Si deseas verificar automáticamente el estado de tus archivos, puertos y configuraciones, puedes ejecutar el script asistente:

### En Windows (PowerShell):
```powershell
.\documentacion\scripts\verificar.ps1
```

### En Linux / macOS (Bash):
```bash
bash ./documentacion/scripts/verificar.sh
```

---

## Comandos Principales de Ejecución

### Docker
```powershell
# Construir imagen
docker build -t practice:v1 .

# Ejecutar contenedor en puerto 8080
docker run -d -p 8080:8080 --name app_container practice:v1

# Probar respuesta HTTP
curl.exe -i http://localhost:8080
```

### Kubernetes
```powershell
# Aplicar manifiestos
kubectl apply -f k8s.yaml

# Consultar endpoints del servicio
kubectl get endpoints web-service

# Ver estado del autoescalador
kubectl get hpa
```

### Pruebas Automatizadas
```powershell
npm test
```
