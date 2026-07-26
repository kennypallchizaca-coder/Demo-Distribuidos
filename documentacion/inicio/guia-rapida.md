<<<<<<< HEAD
# Guía Rápida de Referencia y Verificación

Documentación de consulta para la administración de aplicaciones en contenedores, clústeres de Kubernetes y flujos de trabajo de integración continua.

---

## Puntos Clave de Verificación

### 1. Aplicación y Contenedor (Docker - Reto 1)
- **Puerto de Escucha**: Verificar el puerto configurado en el código fuente (`server.js` -> `PORT = 8080`).
- **Declaración en Dockerfile**: Especificar el puerto mediante la directiva `EXPOSE 8080`.
  ```dockerfile
  # RETO 1: Si server.js escucha en 8080, cambiar EXPOSE 3000 por EXPOSE 8080
  EXPOSE 8080
  ```
- **Interfaz de Red**: La aplicación debe vincularse a `0.0.0.0` (todas las interfaces) para recibir tráfico del puente virtual de Docker.
- **Publicación de Puertos**: Mapear los puertos al ejecutar el contenedor: `docker run -d -p 8080:8080 app_imagen`.

### 2. Red y Enrutamiento (Kubernetes - Reto 2)
- **Coincidencia de Etiquetas**: El campo `spec.selector.app` del Servicio debe coincidir exactamente con `spec.template.metadata.labels.app` del Despliegue.
  ```yaml
  # RETO 2: Si el Service busca 'app: webapp', la plantilla del Pod DEBE decir 'app: webapp'
  spec:
    template:
      metadata:
        labels:
          app: webapp # CAMBIAR AQUI SI DECIA 'app: web'
  ```
- **Estado de los Endpoints**: Validar que el servicio contenga direcciones IP activas consultando `kubectl get endpoints web-service`.

### 3. Automatización de Flujos (CI/CD - Reto 3)
- **Dependencia de Trabajos**: Definir `needs: <nombre-trabajo-pruebas>` en el trabajo de despliegue para evitar ejecuciones automatizadas si las pruebas fallan.
  ```yaml
  # RETO 3: Agregar 'needs' en el job deploy para no desplegar si falla el test
  deploy:
    needs: construccion-pruebas # AGREGAR ESTA LINEA PARA BLOQUEAR DESPLIEGUE SI FALLA TEST
    runs-on: ubuntu-latest
  ```

### 4. Disponibilidad y Escalabilidad (El Giro)
- **Réplicas y Autoescalado**: Incrementar réplicas en el manifiesto YAML al ocurrir el giro de tráfico masivo.
  ```yaml
  # EL GIRO (TRAFICO TRIPLICADO Y ZERO DOWNTIME):
  spec:
    replicas: 6 # CAMBIAR DE 2 A 6 AQUI PARA EL GIRO
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 2
        maxUnavailable: 0 # CAMBIAR A 0 AQUI PARA CERO CAIDAS
  ```
- **Monitoreo de Salud**: Configurar sondas de disponibilidad (`readinessProbe`) y vida (`livenessProbe`).

---

## Comandos Frecuentes de Inspección

```bash
# Inspección de contenedores
docker logs -f <id_contenedor>
docker exec -it <id_contenedor> sh

# Inspección en Kubernetes
kubectl get endpoints <nombre_servicio>
kubectl describe pod <nombre_pod>
kubectl logs -f <nombre_pod>
```
=======
# Guía Rápida y Cuestionario de Defensa Oral del Examen

Documentación de referencia ejecutiva diseñada para entender el sistema de punta a punta y defender verbalmente ante el docente/evaluador por qué se realizó cada cambio en los archivos del examen.

---

## Matriz de Diagnóstico en 10 Segundos

Usa esta matriz durante el examen para identificar la causa raíz y la solución inmediata con solo ver la falla reportada:

| Síntoma en el Examen | Causa Raíz Probable | Solución Inmediata |
| :--- | :--- | :--- |
| `curl: Connection refused` (Docker) | `EXPOSE` en Dockerfile no coincide con el puerto real del código o la app no escucha. | Cambiar `EXPOSE` en Dockerfile al puerto real (ej. `8080`) y verificar `server.listen`. |
| `Empty response from server` | La app está vinculada a `127.0.0.1` (loopback interno) en lugar de `0.0.0.0`. | Reemplazar `127.0.0.1` por `0.0.0.0` en el archivo fuente de la aplicación. |
| `kubectl get endpoints` muestra `<none>` | El selector del Service (`spec.selector.app`) no coincide con la etiqueta del Pod. | Sincronizar `Service.spec.selector.app` con `Deployment.spec.template.metadata.labels.app`. |
| `selector does not match template labels` | El `matchLabels` del Deployment no coincide con las etiquetas de su propia plantilla. | Igualar `spec.selector.matchLabels` con `template.metadata.labels`. |
| Job `deploy` se ejecuta aunque falló `test` | Falta la directiva `needs: build-test` en la etapa de despliegue en GitHub Actions. | Agregar `needs: build-test` en la especificación del job `deploy` dentro de `.github/workflows/ci.yml`. |
| HPA muestra `TARGETS: <unknown>/50%` | El contenedor no tiene declarada la propiedad `resources.requests.cpu`. | Agregar el bloque `resources.requests.cpu: 100m` dentro del contenedor en el `Deployment`. |
| Pod cae en `OOMKilled` (Exit Code 137) | El proceso consumió más memoria RAM que el límite permitido en `resources.limits.memory`. | Aumentar el límite `resources.limits.memory` (ej. de 128Mi a 256Mi o 512Mi). |
| Interrupción de servicio al actualizar | No se usó `maxUnavailable: 0` o falta la sonda de disponibilidad `readinessProbe`. | Configurar `rollingUpdate.maxUnavailable: 0` y añadir `readinessProbe` apuntando a `/`. |

---

## Cuestionario de Defensa Oral para el Examen
*(Prepárate para responder estas preguntas cuando el profesor te evalúe)*

### Reto 1: Docker y Contenedores

#### Pregunta: *¿Por qué el contenedor aparecía en estado "Running" pero la aplicación no respondía al hacer curl?*
> **RESPUESTA TÉCNICA:**
> Ocurre por una discrepancia entre el puerto declarado en la directiva `EXPOSE` del `Dockerfile` (ej. 3000) y el puerto real en el que el proceso de la app está escuchando (ej. 8080). El contenedor está corriendo activamente el proceso Node, pero Docker redirige el tráfico a un puerto cerrado. Se corrigió cambiando `EXPOSE 8080` en el `Dockerfile`.

#### Pregunta: *¿Por qué es obligatorio configurar `0.0.0.0` en el código en lugar de `127.0.0.1` o `localhost`?*
> **RESPUESTA TÉCNICA:**
> En Docker, `127.0.0.1` hace referencia única y exclusivamente al loopback interno del contenedor. Si la app escucha en `127.0.0.1`, rechaza cualquier paquete de red proveniente del puente virtual de Docker (`eth0`). La dirección `0.0.0.0` indica que la aplicación escuchará en todas las interfaces de red disponibles, permitiendo aceptar tráfico externo redirigido desde la máquina host (`-p 8080:8080`).

#### Pregunta: *¿Por qué pusiste `COPY package*.json ./` antes de `COPY . .`?*
> **RESPUESTA TÉCNICA:**
> Para aprovechar el almacenamiento en caché de capas de Docker (*Layer Caching*). Como la descarga e instalación de paquetes con `npm install` es el proceso más lento, separar la copia del `package.json` permite que Docker reutilice esa capa guardada en caché mientras no cambien las dependencias, acelerando las siguientes construcciones de la imagen de minutos a segundos.

#### Pregunta: *¿Por qué usaste la sintaxis de arreglo `CMD ["node", "server.js"]` en vez de `CMD node server.js`?*
> **RESPUESTA TÉCNICA:**
> La sintaxis de arreglo activa la Forma Exec, haciendo que Node sea el proceso principal con PID 1. Esto permite que el contenedor reciba adecuadamente las señales del sistema como `SIGTERM` para cierres limpios. La forma de texto libre (*Shell Form*) lanza `/bin/sh -c` como PID 1, la cual ignora señales y causa apagues abruptos al actualizar contenedores.

---

### Reto 2: Kubernetes Service y Selectores

#### Pregunta: *¿Por qué los Pods estaban en estado "Running" pero el Service devolvía un error o no entregaba tráfico?*
> **RESPUESTA TÉCNICA:**
> Porque el `Service` filtra y enruta el tráfico usando etiquetas (*Labels*). El manifiesto inicial tenía `Service.spec.selector.app: webapp`, mientras que la plantilla del Pod en el Deployment decía `template.metadata.labels.app: web`. Al no haber coincidencia exacta entre la clave y el valor, la lista de `Endpoints` del servicio quedó totalmente vacía (`<none>`).

#### Pregunta: *¿Cómo comprobaste y solucionaste el fallo de los Endpoints?*
> **RESPUESTA TÉCNICA:**
> Ejecuté `kubectl get endpoints web-service` y comprobé que figuraba en `<none>`. Luego ejecuté `kubectl describe svc web-service` para verificar el selector configurado. La solución fue cambiar la etiqueta de la plantilla del Pod a `app: webapp` para sincronizarla con el selector del Servicio, haciendo que K8s asigne automáticamente las direcciones IP de los Pods detrás del Servicio.

#### Pregunta: *¿Cuál es la diferencia técnica entre `port`, `targetPort` y `containerPort`?*
> **RESPUESTA TÉCNICA:**
> - `port`: Es el puerto interno expuesto por el `Service` dentro del clúster (el puerto por el que otros servicios llaman al Service, ej. puerto 80).
> - `targetPort`: Es el puerto destino en los Pods al que el `Service` reenvía las peticiones (ej. puerto 8080).
> - `containerPort`: Es una declaración informativa en la especificación del Pod que indica en qué puerto escucha la aplicación dentro del contenedor (debe ser idéntico a `targetPort`).

---

### Reto 3: CI/CD y GitHub Actions

#### Pregunta: *¿Por qué el pipeline original ejecutaba el despliegue aunque las pruebas fallaran?*
> **RESPUESTA TÉCNICA:**
> En GitHub Actions, por defecto todos los `jobs` declarados dentro del bloque `jobs` se ejecutan simultáneamente en paralelo de forma independiente. Como el job `deploy` no especificaba ninguna relación de dependencia, se iniciaba al mismo tiempo que el job `build-test` sin importar si las pruebas pasaban o fallaban.

#### Pregunta: *¿Cómo detuviste el pipeline al romper una prueba a propósito?*
> **RESPUESTA TÉCNICA:**
> Agregué la directiva `needs: build-test` al inicio del job `deploy`. Esto construye un Grafo Dirigido Acíclico (DAG) que le indica a GitHub Actions que el job `deploy` requiere obligatoriamente la finalización exitosa (Exit Code `0`) de `build-test`. Al romper una prueba (`exit 1`), GitHub Actions marca `build-test` como `FAILED` y cambia el estado de `deploy` a `SKIPPED`, cancelando inmediatamente el despliegue a producción.

---

### El Giro: Escalabilidad y Zero-Downtime

#### Pregunta: *¿Cómo garantizaste que durante la actualización del sistema no existiera ningún corte de servicio perceptible (Zero-Downtime)?*
> **RESPUESTA TÉCNICA:**
> Configuré la estrategia `RollingUpdate` en el `Deployment` estableciendo `maxUnavailable: 0` y `maxSurge: 2` (o 1), junto con una sonda de disponibilidad `readinessProbe`.
> - `maxUnavailable: 0` obliga a que el 100% de los Pods requeridos se mantengan en línea respondiendo tráfico durante todo el despliegue.
> - `maxSurge: 2` permite a K8s crear 2 Pods nuevos con la versión actualizada primero.
> - La `readinessProbe` asegura que K8s no envíe tráfico a los nuevos Pods hasta que compruebe mediante solicitudes HTTP reales que la nueva aplicación ya cargó y responde exitosamente con estado 200.

#### Pregunta: *¿Por qué tuviste que definir `resources.requests.cpu` para que funcione el autosescalador (HPA)?*
> **RESPUESTA TÉCNICA:**
> El `HorizontalPodAutoscaler` calcula el porcentaje de uso de CPU comparando el consumo real de los Pods contra el valor de referencia reservado en `resources.requests.cpu`. Si esta directiva no está definida en el Deployment, el métrico relativo es imposible de calcular y el HPA queda congelado en estado `TARGETS: <unknown>/50%`, imposibilitando el escalado automático de los Pods.
>>>>>>> d811b45 (Commit inicial)
