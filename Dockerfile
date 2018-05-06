FROM nginx:latest

ARG BUILD_DIR="Release"
RUN mkdir app
ADD $BUILD_DIR /usr/share/nginx/html
