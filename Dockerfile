# Etapa de construcción
FROM node:18.20.2-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Etapa de ejecución
FROM nginx:1.26.0-alpine AS runtime

# Eliminar solo default.conf
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuración personalizada
COPY nginx.conf /etc/nginx/conf.d/

# Copiar la app estática generada
COPY --from=builder /app/dist /usr/share/nginx/html

# Healthcheck para Docker
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:80 || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]