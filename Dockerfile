# Etapa de construcción
FROM node:18.20.2-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build   # CRA genera /app/build

# Etapa de ejecución
FROM nginx:1.26.0-alpine AS runtime

# Instalar curl para el healthcheck
RUN apk add --no-cache curl

# Quitar el default y usar nuestra config
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/app.conf

# Copiar la app estática generada por CRA
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -fsS http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
