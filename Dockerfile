FROM oven/bun:latest
WORKDIR /app

# Silenciar las advertencias interactivas de debconf en los logs de Coolify
ENV DEBIAN_FRONTEND=noninteractive

# Instalar libicu-dev (requerido por el sistema interno) 
# y Node.js (necesario porque el script de lanzamiento usa 'tsx' de Node)
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copiar absolutamente todo el proyecto
COPY . .

# Instalar todas las dependencias (necesitamos mantenerlas completas para ejecutar el script .ts)
RUN bun install --ignore-scripts

# Variables de entorno requeridas por AionUi
ENV PORT=3000
ENV NODE_ENV=production
ENV ALLOW_REMOTE=true
ENV DATA_DIR=/data

# Volumen para la base de datos SQLite y persistencia
VOLUME ["/data"]
EXPOSE 3000

# CAMBIO CLAVE: Arrancamos la aplicación usando el script oficial de producción remota
# que encontramos en tu package.json ("webui:prod:remote")
CMD ["bun", "run", "webui:prod:remote"]
