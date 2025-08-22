# Etapa de construcción
FROM node:18.20.2-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build   # genera /app/build

# Etapa de ejecución (sirve estático)
FROM nginx:1.26.0-alpine AS runtime

# curl para healthcheck
RUN apk add --no-cache curl

# Config mínima para servir SPA (sin TLS, sin upstream)
# (Se crea dentro de la imagen; no se usa tu nginx.conf)
RUN rm -f /etc/nginx/conf.d/default.conf && \
    cat > /etc/nginx/conf.d/default.conf <<'NGINX'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # React SPA: fallback a index.html
    location / {
        try_files $uri /index.html;
    }

    # (Opcional) compresión
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
NGINX

# Copiar la build de React
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

# Healthcheck interno
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -fsS http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
