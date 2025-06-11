# syntax=docker/dockerfile:1
# Flutter 웹 애플리케이션 빌드
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS builder

WORKDIR /app

# pubspec 파일 복사 (컨텍스트가 reward 디렉토리이므로 reward_app 하위 경로 참조)
COPY reward_app/pubspec.yaml reward_app/pubspec.lock ./

# reward_common 패키지를 상위 디렉토리에 복사 (pubspec.yaml의 ../reward_common 경로에 맞춤)
COPY reward_common ../reward_common

# 의존성 설치
RUN flutter pub get

# 소스 코드 복사 (컨텍스트가 reward이므로 reward_app 디렉토리를 현재 디렉토리로)
COPY reward_app ./

# Flutter 웹 빌드
RUN flutter build web --release --web-renderer html

# Nginx를 사용하여 정적 파일 서빙
FROM nginx:alpine

# Flutter 빌드 결과물 복사
COPY --from=builder /app/build/web /usr/share/nginx/html

# SPA를 위한 Nginx 설정
RUN echo 'server { \
    listen 46151; \
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

EXPOSE 46151

CMD ["nginx", "-g", "daemon off;"]