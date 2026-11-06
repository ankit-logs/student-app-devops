# syntax=docker/dockerfile:1
# Build context is the repository root; the app source lives in ./app (see scripts/fetch-app.sh).

# ---- Stage 1: build the React (Vite) app ------------------------------------
FROM node:24-alpine AS build
WORKDIR /src
COPY app/frontend/package.json app/frontend/package-lock.json ./
RUN npm ci
COPY app/frontend/ .
# The browser calls /api on the same host; nginx forwards it to the backend.
# So the image no longer contains a server IP and works in any environment.
# (Real environment variables beat the app's own .env file in Vite.)
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# ---- Stage 2: nginx serves the build and proxies /api ----------------------
FROM nginx:1.27-alpine
ENV BACKEND_HOST=backend \
    BACKEND_PORT=8080
# The official nginx image fills ${BACKEND_HOST} / ${BACKEND_PORT} at start-up.
COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 80
