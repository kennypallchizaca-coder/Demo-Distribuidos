# Resumen del Simulacro: ¿Qué hicimos y por qué?

Este documento explica paso a paso las soluciones aplicadas a los retos de tu simulacro de CI/CD, para que entiendas el razonamiento detrás de cada cambio y puedas aplicarlo en escenarios similares.

## Reto 1: El contenedor "corre" pero no responde
**El Problema:** La aplicación estaba programada para escuchar en el puerto `3000` internamente (en `server.js`), pero el `Dockerfile` tenía la instrucción `EXPOSE 8080`. 
**El Síntoma:** Docker construye la imagen y el contenedor corre sin arrojar error (porque el proceso Node está funcionando), pero al intentar acceder desde el navegador en el puerto mapeado, la conexión es rechazada.
**La Solución:** 
Se cambió la instrucción a `EXPOSE 3000` en el `Dockerfile`. 
**El "Por qué":** La directiva `EXPOSE` es la forma en la que el contenedor le comunica a Docker (y a Kubernetes) qué puerto debe estar abierto en la red interna del contenedor. Si expones un puerto en el que no hay nada escuchando, el tráfico llega a un callejón sin salida.

---

## Reto 2: Pods en Running, pero el Service no responde
**El Problema:** El manifiesto de Kubernetes (`deployment.yaml`) le asignó la etiqueta `app: web` a los pods, pero el balanceador de carga (`service.yaml`) estaba buscando pods con la etiqueta `app: cicd-practica-sd`.
**El Síntoma:** Kubernetes levanta los pods perfectamente (estado Running), pero el comando `kubectl get endpoints` muestra una lista vacía. El Service recibe tráfico pero no sabe a quién enviárselo.
**La Solución:**
Se corrigió el `deployment.yaml` para que la etiqueta en el bloque `template.metadata.labels` fuera exactamente `app: cicd-practica-sd`.
**El "Por qué":** En Kubernetes, los componentes no están conectados por su nombre, sino por **Etiquetas (Labels)**. El `Selector` del Service actúa como una consulta de base de datos ("dame las IPs de todos los pods que tengan la etiqueta X"). Si las etiquetas no coinciden exactamente, el Service se queda ciego.

---

## Reto 3: El pipeline despliega aunque fallen las pruebas
**El Problema:** En el archivo `.github/workflows/ci-cd.yml`, había dos trabajos independientes: `build-test` y `build-push`. Al no haber una restricción entre ellos, GitHub Actions los ejecutaba al mismo tiempo.
**El Síntoma:** Si el código tenía un error sintáctico y el trabajo `build-test` fallaba, el trabajo `build-push` ignoraba ese fallo, construía la imagen con el código roto y la mandaba a producción.
**La Solución:**
Se añadió la directiva `needs: build-test` dentro de la configuración del trabajo `build-push`.
**El "Por qué":** La directiva `needs` fuerza una ejecución secuencial. Obliga al trabajo de despliegue a bloquearse hasta recibir una confirmación de éxito ("verde") del trabajo de pruebas. Este es el pilar central del principio *Fail Fast* (falla rápido) en Integración Continua.

---

## El Giro Final: Despliegue sin cortes bajo alto tráfico
**El Problema:** El departamento de marketing triplicó el tráfico, y se requería desplegar una nueva versión de la app sin que los usuarios experimentaran caídas del servidor.
**La Solución:**
1. **Ajuste de Réplicas:** En `deployment.yaml` se pasó de `replicas: 4` a `replicas: 12`.
2. **Estrategia Zero-Downtime:** Se aseguró que el bloque `strategy` tuviera `type: RollingUpdate` con `maxUnavailable: 1` y `maxSurge: 1`. Además se validó que existiera un `readinessProbe`.
**El "Por qué":** 
- Multiplicar las réplicas distribuye el exceso de peticiones (balanceo de carga).
- El `RollingUpdate` le indica a Kubernetes que reemplace los pods de uno en uno (o de poco en poco). 
- El `readinessProbe` es la salvaguarda máxima: Kubernetes levanta un pod nuevo con la actualización, pero **no mata un pod viejo** hasta que el probe confirme devolviendo `HTTP 200` que el pod nuevo ya está 100% listo para recibir tráfico real.
