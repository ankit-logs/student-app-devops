#!/usr/bin/env bash
# Plain `docker run` version of the deployment (no Compose).
# It performs the same steps as the walkthrough: network, volume, MariaDB,
# backend, frontend. Passwords come from .env, never from this file.
#
# Usage:  bash docker/run-with-docker.sh up        # build and start everything
#         bash docker/run-with-docker.sh down      # remove the containers (data is kept)
#         bash docker/run-with-docker.sh purge     # also delete the database volume
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ -f .env ] || { echo "Missing .env. Run: cp .env.example .env  and edit it." >&2; exit 1; }
set -a
# shellcheck disable=SC1091
. ./.env
set +a
: "${DB_PASSWORD:?Set DB_PASSWORD in .env}"
: "${DB_ROOT_PASSWORD:?Set DB_ROOT_PASSWORD in .env}"
DB_NAME="${DB_NAME:-student_db}"
DB_USER="${DB_USER:-admin}"

NETWORK=student-network
VOLUME=student-db-data

up() {
  [ -d app/backend ] || { echo "App source not found. Run: bash scripts/fetch-app.sh" >&2; exit 1; }

  docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK"
  docker volume inspect "$VOLUME" >/dev/null 2>&1 || docker volume create "$VOLUME"

  echo "==> Starting MariaDB"
  docker run -d --name db \
    --network "$NETWORK" --restart unless-stopped \
    -e MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
    -e MARIADB_DATABASE="$DB_NAME" \
    -e MARIADB_USER="$DB_USER" \
    -e MARIADB_PASSWORD="$DB_PASSWORD" \
    -v "$VOLUME":/var/lib/mysql \
    --health-cmd='healthcheck.sh --connect --innodb_initialized' \
    --health-interval=10s --health-timeout=5s --health-retries=10 \
    mariadb:11.4

  echo "==> Waiting for MariaDB to become healthy"
  until [ "$(docker inspect -f '{{.State.Health.Status}}' db)" = "healthy" ]; do sleep 3; done

  echo "==> Building and starting the backend"
  docker build -f docker/backend.Dockerfile -t student-backend:local .
  docker run -d --name student-backend \
    --network "$NETWORK" --restart unless-stopped \
    -e SPRING_DATASOURCE_URL="jdbc:mariadb://db:3306/$DB_NAME" \
    -e SPRING_DATASOURCE_USERNAME="$DB_USER" \
    -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
    student-backend:local

  echo "==> Building and starting the frontend (port 80)"
  docker build -f docker/frontend.Dockerfile -t student-frontend:local .
  docker run -d --name student-frontend \
    --network "$NETWORK" --restart unless-stopped \
    -e BACKEND_HOST=student-backend -e BACKEND_PORT=8080 \
    -p 80:80 student-frontend:local

  echo "Done. Open http://<this-server-ip>/  (check logs with: docker logs -f student-backend)"
}

down() {
  docker rm -f student-frontend student-backend db 2>/dev/null || true
  docker network rm "$NETWORK" 2>/dev/null || true
}

case "${1:-}" in
  up)    up ;;
  down)  down ;;
  purge) down; docker volume rm "$VOLUME" 2>/dev/null || true ;;
  *)     echo "Usage: $0 {up|down|purge}" >&2; exit 1 ;;
esac
