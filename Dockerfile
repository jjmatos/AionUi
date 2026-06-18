FROM node:20-slim AS builder
WORKDIR /app

# Install bun
RUN npm install -g bun

# CORRECCIÓN 1: Copiamos todo el proyecto primero.
# Al ser un monorrepo, Bun necesita ver las carpetas de los workspaces 
# (como @aionui/web-host) desde el primer momento para no fallar.
COPY . .

# Install all dependencies (including devDeps for build)
RUN bun install --ignore-scripts

# Build renderer (no Electron needed) and server bundle
RUN bun run build:renderer:web
RUN node scripts/build-server.mjs

# ---- Runtime image ----
FROM oven/bun:latest AS runtime
WORKDIR /app

# CORRECCIÓN 2: Evita las advertencias molestas de debconf en los logs de Coolify
ENV DEBIAN_FRONTEND=noninteractive

# officecli (the Office preview component, auto-installed at runtime by the
# backend) is a .NET binary that aborts on startup without ICU, and Debian
# base images don't ship it. libicu-dev is version-agnostic so it keeps
# resolving the right libicuNN when the base image bumps Debian releases.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# CORRECCIÓN 3: Copiamos la estructura limpia del proyecto en el runtime
# para que 'bun install --production' pueda validar los workspaces sin romperse.
COPY . .

# Traemos los artefactos ya compilados desde el builder (sobrescribiendo las carpetas)
COPY --from=builder /app/dist-server ./dist-server
COPY --from=builder /app/out/renderer ./out/renderer

# Ahora sí, instalará únicamente las dependencias de producción de forma segura
RUN bun install --production --ignore-scripts

ENV PORT=3000
ENV NODE_ENV=production
ENV ALLOW_REMOTE=true
ENV DATA_DIR=/data

# SQLite data volume — mount with: -v $(pwd)/data:/data
VOLUME ["/data"]
EXPOSE 3000

CMD ["bun", "dist-server/server.mjs"]


