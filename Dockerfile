# syntax=docker/dockerfile:1
# Flutter 웹 애플리케이션 빌드
FROM flutter:3.19.0 AS builder

WORKDIR /app

# pubspec 파일 복사 및 의존성 설치
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 소스 코드 복사
COPY . .

# Flutter 웹 빌드
RUN flutter build web --release --web-renderer html

# Nginx를 사용하여 정적 파일 서빙
FROM nginx:alpine

# Flutter 빌드 결과물 복사
COPY --from=builder /app/build/web /usr/share/nginx/html

# SPA를 위한 Nginx 설정
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]