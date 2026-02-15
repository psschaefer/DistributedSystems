FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
# --web-renderer was removed in Flutter 3.24+; default is CanvasKit
RUN flutter build web --release

FROM nginx:alpine
ARG NGINX_CONF=nginx.conf

COPY --from=build /app/build/web /usr/share/nginx/html
COPY ${NGINX_CONF} /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
