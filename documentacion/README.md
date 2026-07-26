<<<<<<< HEAD
# Guía General de la Documentación del Proyecto

Este directorio contiene la documentación técnica completa, patrones de diseño, guías de diagnóstico, scripts de ayuda y automatización, y referencia de comandos para el desarrollo, contenedores con Docker, orquestación en Kubernetes e integración continua con GitHub Actions.

---

## Estructura General del Directorio

```text
documentacion/
├── README.md                          # Guía general del directorio y mapa de navegación
├── inicio/
│   └── guia-rapida.md                # Puntos de verificación rápida y referencia inicial
├── arquitectura/
│   ├── docker.md                     # Conceptos de contenedores, Dockerfile y redes
│   ├── kubernetes.md                 # Objetos K8s, estrategias de despliegue y sondas
│   └── integracion-continua.md       # Pipelines en GitHub Actions y dependencias entre jobs
├── patrones/
│   ├── deployment.yaml               # Plantilla estándar de Deployment en Kubernetes
│   ├── service.yaml                  # Plantilla estándar de Service en Kubernetes
│   ├── hpa.yaml                      # Plantilla de HorizontalPodAutoscaler (HPA v2)
│   ├── rolling-update.yaml           # Plantilla de despliegue Zero-Downtime
│   ├── configmap.yaml                # Plantilla de ConfigMap y Secret
│   ├── ingress.yaml                  # Plantilla de enrutamiento Ingress
│   ├── Dockerfile                    # Plantilla de construcción de imagen Docker
│   ├── .dockerignore                 # Archivo de exclusión para Docker build
│   ├── .gitignore                    # Archivo de exclusión para Git
│   ├── ci.yml                        # Workflow ejecutable en GitHub Actions
│   └── package.json                  # Definición de dependencias y scripts de prueba
├── operaciones/
│   ├── comandos.md                   # Referencia de comandos CLI (PowerShell y Bash)
│   ├── diagnostico.md                # Metodología de diagnóstico y aislamiento de fallas
│   └── solucion-problemas.md         # Matriz de errores comunes y corrección código a código
├── practicas/
│   └── notas-laboratorio.md          # Resolución de casos de estudio paso a paso
└── scripts/
    ├── verificar.ps1                 # Script asistente de diagnóstico automático en PowerShell
    └── verificar.sh                  # Script asistente de diagnóstico automático en Bash
=======
# Portal General de Documentación y Defensa del Examen

Bienvenido al centro de documentación técnica y preparación para la evaluación del examen simulado y de alta complejidad en Docker, Kubernetes, CI/CD con GitHub Actions y Alta Disponibilidad.

---

## Metodología de Uso de la Documentación

Esta documentación ha sido diseñada con un doble propósito: resolver los problemas técnicos paso a paso y proporcionar los argumentos exactos para defender cada cambio verbalmente ante el evaluador.

```text
                                DOCUMENTACIÓN DEL PROYECTO
                                            │
         ┌──────────────────────────────────┼──────────────────────────────────┐
         ▼                                  ▼                                  ▼
   INICIO RÁPIDO                       ARQUITECTURA                       OPERACIONES
   ├── guía-rápida.md                  ├── docker.md                      ├── diagnóstico.md
   └── (Matriz & Cuestionario)         ├── kubernetes.md                  ├── solución-problemas.md
                                       └── integración-continua.md        └── comandos.md
                                            │
                                            ▼
                                    PRÁCTICAS Y CASOS
                                    └── notas-laboratorio.md
>>>>>>> d811b45 (Commit inicial)
```

---

<<<<<<< HEAD
## Asistente de Verificación Automática (Scripts de Ayuda)

Si cometiste un error en un comando o deseas comprobar de forma automática si tu entorno y tus archivos cumplen con los Retos 1, 2, 3 y El Giro, puedes ejecutar el script de verificación según tu sistema operativo:

### En Windows (PowerShell):
```powershell
.\documentacion\scripts\verificar.ps1
```

### En Linux / macOS (Bash):
```bash
bash ./documentacion/scripts/verificar.sh
```

El script revisará automáticamente:
1. Si la aplicación Node responde correctamente en HTTP 8080 (Reto 1).
2. Si el Servicio de Kubernetes tiene direcciones IP en sus Endpoints (Reto 2).
3. Si los scripts de prueba `npm test` pasan correctamente (Reto 3).
4. Si las réplicas están configuradas a 6 y la estrategia `RollingUpdate` usa `maxUnavailable: 0` (El Giro).

---

## Contenido Detallado por Archivo

### 1. Directorio `inicio/`

#### `inicio/guia-rapida.md`
- **Contenido**: Resumen ejecutivo de los 4 pilares fundamentales (Docker, Kubernetes, CI/CD y Alta Disponibilidad).
- **Para qué sirve**: Consulta rápida de 5 minutos para revisar los puntos de verificación críticos.

---

### 2. Directorio `arquitectura/`

#### `arquitectura/docker.md`
- **Contenido**: Explicación conceptual y técnica de imágenes, contenedores, redes y directivas de un `Dockerfile`.

#### `arquitectura/kubernetes.md`
- **Contenido**: Desglose línea por línea de los manifiestos de Kubernetes (`Deployment`, `Service`, `Endpoints`, `HPA`).

#### `arquitectura/integracion-continua.md`
- **Contenido**: Arquitectura de pipelines de automatización en GitHub Actions.

---

### 3. Directorio `patrones/`

Plantillas de código limpio y sin comentarios en formato de producción para su uso directo (`deployment.yaml`, `service.yaml`, `hpa.yaml`, `rolling-update.yaml`, `Dockerfile`, etc.).

---

### 4. Directorio `operaciones/`

#### `operaciones/comandos.md`
- **Contenido**: Listado de comandos esenciales para Docker, Kubernetes y Git para **PowerShell** y **Bash**.

#### `operaciones/diagnostico.md`
- **Contenido**: Algoritmo secuencial de aislamiento de problemas.

#### `operaciones/solucion-problemas.md`
- **Contenido**: Matriz completa de errores comunes con código de falla y corrección.

---

### 5. Directorio `practicas/`

#### `practicas/notas-laboratorio.md`
- **Contenido**: Casos de estudio prácticos resueltos detalladamente.
=======
## Mapa de Navegación

### 1. Inicio Rápido y Defensa Oral
- [guia-rapida.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/inicio/guia-rapida.md): Matriz de resolución en 10 segundos y el Cuestionario de Defensa Oral con las respuestas exactas a las preguntas conceptuales sobre Reto 1, Reto 2, Reto 3 y El Giro.

### 2. Guías de Arquitectura (Fundamentos Técnicos)
- [docker.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/arquitectura/docker.md): Directivas del `Dockerfile`, binding en `0.0.0.0`, multi-stage builds, Form Exec vs Shell Form, `ARG` vs `ENV` y seguridad sin root (`USER node`).
- [kubernetes.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/arquitectura/kubernetes.md): Objetos K8s, sincronización de etiquetas, estrategias `RollingUpdate`, `Blue-Green`, `Canary`, sondas `readiness`/`liveness`, requisito obligatorio de HPA (`resources.requests`) y namespaces.
- [integracion-continua.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/arquitectura/integracion-continua.md): Estructura de GitHub Actions, bloqueo por dependencias (`needs: build-test`), secretos de autenticación y rollback automático ante fallos de despliegue (`if: failure()`).

### 3. Operaciones, Comandos y Solución de Problemas
- [diagnostico.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/operaciones/diagnostico.md): Algoritmo de resolución de problemas, comandos CLI de inspección rápida (`kubectl top`, `kubectl describe`) y script bucle `curl` en una línea para demostrar Zero-Downtime.
- [solucion-problemas.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/operaciones/solucion-problemas.md): Matriz completa de códigos de error (`CrashLoopBackOff`, `OOMKilled`, `TARGETS: <unknown>/50%`, `ENDPOINTS: <none>`) y su corrección exacta.
- [comandos.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/operaciones/comandos.md): Hoja de trucos con todos los comandos de Docker, K8s, Git y PowerShell/Bash necesarios.

### 4. Prácticas y Casos de Estudio
- [notas-laboratorio.md](file:///c:/Users/kenny/OneDrive/Documents/SIMULACIONXD/documentacion/practicas/notas-laboratorio.md): Resolución completa de los Casos Prácticos 1 al 4 (Simulacro base) y Caso Práctico 5 (Escenario Avanzado de Examen Complejo).

---

## Asistente de Verificación Automática (Scripts)

Antes de entregar tu examen, ejecuta el script de comprobación automática según tu sistema operativo para asegurarte de que todo funciona de punta a punta:

- **En Windows (PowerShell):**
  ```powershell
  .\documentacion\scripts\verificar.ps1
  ```
- **En Linux / macOS (Bash):**
  ```bash
  bash ./documentacion/scripts/verificar.sh
  ```
>>>>>>> d811b45 (Commit inicial)
