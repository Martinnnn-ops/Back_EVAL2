# ============================================================
# Dockerfile del Backend — API REST Node.js + Express
# ============================================================
# Multi-stage build:
#   Stage 1 (deps):       instala dependencias con todas las herramientas
#   Stage 2 (production): imagen final, mínima y sin herramientas de build
#
# Beneficios del multi-stage:
#   • Imagen final ~180 MB en vez de ~900 MB
#   • Sin compiladores ni cachés en producción (más seguro)
#   • Más rápido al hacer pull en la EC2
# ============================================================


# ─── STAGE 1: Instalar dependencias ─────────────────────────
# Usamos "alpine" porque es la versión más liviana de Node 18
FROM node:18-alpine AS deps

# Carpeta de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo los manifiestos de dependencias PRIMERO.
# Truco de cacheo: si package.json no cambia, Docker reutiliza
# esta capa y NO vuelve a instalar las dependencias.
COPY package*.json ./

# Instalar dependencias de producción:
#   • --omit=dev excluye devDependencies (nodemon)
#   • Usamos "npm install" en vez de "npm ci" porque el repo
#     no tiene package-lock.json. Si lo agregas en el futuro,
#     cambia esta línea a: RUN npm ci --omit=dev (más rápido y reproducible)
RUN npm install --omit=dev


# ─── STAGE 2: Imagen final de producción ────────────────────
FROM node:18-alpine AS production

WORKDIR /app

# Crear grupo y usuario sin privilegios de root
# Principio de mínimo privilegio: si alguien entra al contenedor,
# no tendrá permisos de administrador.
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

# Traer las dependencias ya instaladas desde el stage anterior
COPY --from=deps /app/node_modules ./node_modules

# Copiar el código de la aplicación
# --chown asegura que los archivos pertenezcan al usuario no-root
COPY --chown=nodeuser:nodejs . .

# Eliminar archivos que no se necesitan en producción
# (.git, .env, README, etc. por si .dockerignore falló)
RUN rm -rf .git .env* *.md

# Cambiar al usuario sin privilegios para todo lo que venga después
USER nodeuser

# Documentar el puerto que usa la app (no lo publica, solo informa)
EXPOSE 3000

# Healthcheck: Docker verifica cada 30s que la app responde.
# Usamos GET / porque solo testea que Express está vivo
# (no depende de MySQL, que tiene su propio healthcheck).
#
#   --interval=30s   → revisar cada 30 segundos
#   --timeout=10s    → si tarda más de 10s, considera que falló
#   --start-period   → da 15s al iniciar antes de empezar a chequear
#   --retries=3      → 3 fallos seguidos para marcarlo "unhealthy"
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Comando que se ejecuta al arrancar el contenedor
# Equivale a "npm start" pero llama a node directamente (más liviano)
CMD ["node", "server.js"]
