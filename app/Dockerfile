# --- Stage 1: blog/posts/*.md dosyalarını HTML'e çevir ---
FROM node:24-alpine AS blog-builder

WORKDIR /build

#install dependencies first so this layer is cached between builds
COPY blog/package.json blog/package-lock.json ./
RUN npm ci

#generate blog pages into /build/dist
COPY blog/ ./
RUN node build.js

# --- Stage 2: siteyi nginx ile sun ---
#declare the base image
FROM nginx:alpine

#install htpasswd
RUN apk add --no-cache apache2-utils

#set a work directory
WORKDIR /usr/share/nginx/html

#copy files
COPY index.html style.css mediaqueries.css blog.css script.js theme.js ./
COPY assets ./assets

#copy generated blog pages (node is not part of the final image)
COPY --from=blog-builder /build/dist ./blog

COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --chmod=755 nginx/40-basic-auth.sh /docker-entrypoint.d/40-basic-auth.sh

ENV APP_ENV=dev

#expose nginx port
EXPOSE 80

#command
CMD [ "nginx", "-g", "daemon off;" ]
