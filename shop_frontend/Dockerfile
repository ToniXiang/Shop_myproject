# 使用支援 Dart 3.32.4 的 Flutter 映像
FROM instrumentisto/flutter:3.32.4 AS build

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web

FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
