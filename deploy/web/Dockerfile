FROM ghcr.io/cirruslabs/flutter:3.27.1 AS builder

WORKDIR /app
COPY tokerrgjik_mobile/ ./
RUN flutter pub get && flutter build web --release

FROM nginx:1.27-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
