# Guía de Arquitectura y Configuración de Docker

Documento de referencia para comprender la estructura, directivas de construcción, redes y resolución de incidencias en contenedores Docker.

---

## 1. Conceptos Fundamentales

### Imagen (Image)
- **Para qué sirve**: Es una plantilla ejecutable e inmutable que contiene el sistema de archivos base, el código fuente de la aplicación, librerías y variables de entorno.
- **Por qué se utiliza**: Permite que la aplicación se ejecute exactamente igual en cualquier entorno (laptop del desarrollador, servidor de pruebas o Kubernetes) eliminando el problema de "en mi máquina sí funciona".
- **Alternativas**: Instalar la aplicación directamente en la máquina virtual o servidor físico.
- **Por qué Docker es más recomendable**: Aísla dependencias y consume significativamente menos recursos que una máquina virtual completa.

### Contenedor (Container)
- **Para qué sirve**: Es la instancia viva y en ejecución de una imagen.
- **Qué pasa si se detiene**: El proceso de la aplicación finaliza. Si no se configuraron volúmenes persistentes, los datos guardados en el contenedor en tiempo de ejecución se pierden.

---

## 2. Explicación Detallada de Directivas del Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
```

### Directiva: `FROM node:20-alpine`
- **Función de la línea**: Define la imagen base sobre la cual se construirá la aplicación.
- **Por qué se coloca**: Proporciona el entorno de ejecución de Node.js v20 sobre una distribución Linux Alpine minimalista.
- **Qué pasa si se elimina**: El build falla inmediatamente porque Docker exige declarar una imagen base con `FROM`.
- **Qué pasa si se cambia por `node:20`**: Funciona, pero la imagen pesará ~1 GB en lugar de ~180 MB.
- **Cuándo conviene utilizarla**: Siempre. Se recomienda usar variantes `-alpine` en producción por seguridad y ligereza.

### Directiva: `WORKDIR /app`
- **Función de la línea**: Establece el directorio de trabajo interno dentro del contenedor donde se ejecutarán los siguientes comandos (`COPY`, `RUN`, `CMD`).
- **Por qué se coloca**: Para mantener orden dentro del sistema de archivos del contenedor y evitar copiar archivos en la raíz (`/`).
- **Qué pasa si se elimina**: Los archivos se copiarán en el directorio raíz (`/`), lo que genera desorden y posibles conflictos de permisos.

### Directiva: `COPY package*.json ./` y `RUN npm install`
- **Función de las líneas**: Copian primero únicamente los archivos de dependencias e instalan los paquetes de Node.js.
- **Por qué se coloca en dos pasos (antes de `COPY . .`)**: Aprovecha la memoria caché de capas de Docker. Si el código fuente cambia pero `package.json` no cambia, Docker reutiliza la capa de `npm install` sin volver a descargar dependencias.
- **Qué pasa si se invierte el orden (`COPY . .` primero y luego `npm install`)**: Cada pequeño cambio en un archivo JS obligará a ejecutar `npm install` desde cero, ralentizando la construcción.

### Directiva: `EXPOSE 8080`
- **Función de la línea**: Documenta e indica que el contenedor escuchará en el puerto 8080.
- **Por qué se coloca**: Sirve como comunicación explícita para desarrolladores y sistemas de orquestación sobre qué puerto utiliza el proceso interno.
- **Qué pasa si se cambia a un puerto incorrecto (ej. `EXPOSE 3000` cuando la app escucha en 8080)**:
  - **SÍNTOMA DE FALLA**: El contenedor inicia en estado active (`Running`), pero al realizar peticiones por el puerto expuesto se obtiene el error `Connection refused`.
- **Qué pasa si se elimina**: El contenedor funcionará si se mapea el puerto manualmente en `docker run -p 8080:8080`, pero se pierde la documentación interna del puerto.

### Directiva: `CMD ["node", "server.js"]`
- **Función de la línea**: Define el comando por defecto que se ejecutará cuando el contenedor inicie.
- **Por qué se coloca con sintaxis de arreglo `["node", "server.js"]` (Forma Exec)**: Permite que el proceso `node` reciba correctamente las señales del sistema operativo (como `SIGTERM` para apagados limpios).
- **Qué pasa si se elimina**: El contenedor iniciará pero se detendrá inmediatamente al no tener un proceso principal continuo que ejecutar.

---

## 3. Configuración de Redes y Vincular Interfaz (Host Binding)

```js
// Código en server.js
const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor escuchando en puerto ${PORT}`);
});
```

### Vincular a `0.0.0.0` vs `127.0.0.1`
- **Por qué se vincula a `0.0.0.0`**: La dirección `0.0.0.0` significa "escuchar en todas las interfaces de red disponibles". Permite que el servidor acepte peticiones provenientes del puente de red virtual de Docker (`eth0`).
- **Qué pasa si se vincula a `127.0.0.1`**:
  - **SÍNTOMA DE FALLA**: Desde la máquina host o el navegador al acceder a `http://localhost:8080` se recibe `Empty response` o `Connection reset`.
  - **Explicación**: `127.0.0.1` dentro del contenedor hace referencia únicamente al loopback interno del contenedor. Ningún tráfico externo redirigido desde el host puede ingresar a esa interfaz.

---

<<<<<<< HEAD
## 4. Diagnóstico de Errores Comunes en Docker
=======
## 4. Conceptos Avanzados y Directivas de Producción

### Multi-Stage Builds (Construcción Multietapa)
- **Para qué sirve**: Permite separar la etapa de compilación/construcción (builder) de la etapa final de ejecución.
- **Por qué se utiliza**: Reduce drásticamente el tamaño de la imagen final y elimina herramientas de compilación que representan vulnerabilidades de seguridad.
- **Ejemplo**:
```dockerfile
# Etapa 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Etapa 2: Ejecución Producción
FROM node:20-alpine AS runner
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
USER node
EXPOSE 8080
CMD ["node", "dist/server.js"]
```

### Directiva: `ENTRYPOINT` vs `CMD` (Exec vs Shell Form)
- **Forma Exec (Recomendada)**: `CMD ["node", "server.js"]` o `ENTRYPOINT ["node", "server.js"]`. El proceso corre como PID 1 y recibe señales del sistema como `SIGTERM` para cierres limpios.
- **Forma Shell (Trampa)**: `CMD node server.js`. Arranca un subshell `/bin/sh -c` que ignora `SIGTERM`, haciendo que el contenedor no responda correctamente al apagarse o actualizarse.

### Directivas: `ARG` vs `ENV`
- **`ARG` (Build-time)**: Variables disponibles únicamente durante `docker build` (ej. `ARG NODE_ENV=production`). No persisten en el contenedor final.
- **`ENV` (Runtime)**: Variables persistentes en tiempo de ejecución (ej. `ENV PORT=8080`). Se pueden sobrescribir con `docker run -e PORT=9090`.

### Directiva: `USER node` (Principio de Menor Privilegio)
- Evita ejecutar el contenedor como usuario `root`. Previene vulnerabilidades donde un atacante puede tomar control del sistema host.

### Directiva: `HEALTHCHECK`
- Declara una prueba periódica ejecutada internamente por Docker para verificar el estado de la app.
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/ || exit 1
```

---

## 5. Diagnóstico de Errores Comunes y Avanzados en Docker
>>>>>>> d811b45 (Commit inicial)

| Error | Mensaje / Síntoma | Causa Raíz | Solución Paso a Paso |
| :--- | :--- | :--- | :--- |
| Puertos no coincidentes | `curl: (7) Failed to connect` | `EXPOSE` en Dockerfile no coincide con `PORT` en `server.js`. | 1. Revisar `server.js` (`PORT=8080`).<br>2. Cambiar `EXPOSE 8080` en Dockerfile.<br>3. Ejecutar `docker run -p 8080:8080`. |
| Binding a localhost | `Empty response from server` | Servidor configurado con `server.listen(8080, '127.0.0.1')`. | Cambiar la dirección IP de escucha en el código fuente a `0.0.0.0`. |
| Archivos no ignorados | Build extremadamente lento | Directorio `node_modules` local se está copiando al contenedor. | Crear archivo `.dockerignore` e incluir `node_modules`. |
<<<<<<< HEAD
=======
| Proceso ignora apagar | `docker stop` tarda 10 segundos y mata con `SIGKILL` | `CMD` escrito en Forma Shell (`CMD node server.js`). | Cambiar a Forma Exec: `CMD ["node", "server.js"]`. |
| Permisos denegados | `EACCES: permission denied` | Se usó `USER node` pero el directorio `/app` es propiedad de `root`. | Agregar `RUN chown -R node:node /app` antes de `USER node`. |
| Multi-stage incompleto | `Cannot find module '/app/dist'` | La directiva `COPY --from=builder` tiene la ruta origen o destino incorrecta. | Verificar las rutas absolutas creadas en la etapa `builder`. |
>>>>>>> d811b45 (Commit inicial)
