# ---- Stage 1: Builder ----
FROM node:20-slim AS builder
WORKDIR /app

# Instalar bun de forma global
RUN npm install -g bun

# COPIA COMPLETA: Crucial para que Bun detecte la estructura del monorrepo
COPY . .

# Instalar todas las dependencias (incluyendo devDependencies para compilar)
RUN bun install --ignore-scripts

# Compilación unificada: Este script genera el servidor y la interfaz web integrada
RUN node scripts/build-server.mjs


# ---- Stage 2: Runtime ----
FROM oven/bun:latest AS runtime
WORKDIR /app

# Silenciar las advertencias interactivas de debconf en los logs de Coolify
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema necesarias para componentes internos de la app
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar la estructura del monorrepo para validar dependencias de producción
COPY . .

# Traer los artefactos limpios y compilados desde el Stage de Builder
COPY --from=builder /app/dist-server ./dist-server
COPY --from=builder /app/out/renderer ./out/renderer

# Instalar únicamente las dependencias de producción de manera segura
RUN bun install --production --ignore-scripts

# Variables de entorno por defecto para el contenedor
ENV PORT=3000
ENV NODE_ENV=production
ENV ALLOW_REMOTE=true
ENV DATA_DIR=/data

# Volumen para la base de datos SQLite y persistencia
VOLUME ["/data"]
EXPOSE 3000

# Comando de inicio de la aplicación
CMD ["bun", "dist-server/server.mjs"]
