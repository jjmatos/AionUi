FROM oven/bun:latest
WORKDIR /app

# Silenciar advertencias de debconf
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema esenciales + herramientas de descarga
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev nodejs curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copiar absolutamente todo el proyecto
COPY . .

# CORRECCIÓN CLAVE: Quitamos '--ignore-scripts' para permitir que el script 
# 'postinstall.js' descargue el binario 'aioncore' correcto para tu arquitectura ARM.
RUN bun install

# Otorgar permisos de ejecución por si acaso a los binarios descargados
RUN chmod -R +x resources/bundled-aioncore/ 2>/dev/null || true

# Variables de entorno requeridas
ENV PORT=3000
ENV NODE_ENV=production
ENV ALLOW_REMOTE=true
ENV DATA_DIR=/data

# Volumen para persistencia de datos
VOLUME ["/data"]
EXPOSE 3000

# Arrancamos la aplicación
CMD ["bun", "run", "webui:prod:remote"]
