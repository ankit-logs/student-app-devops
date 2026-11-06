#!/usr/bin/env bash
# Build both images for Kubernetes (linux/amd64) and push them to Docker Hub.
#
# Usage:  DOCKERHUB_USER=dubey23 TAG=1.0.0 bash scripts/build-push.sh
# Log in first:  docker login -u <your-user>
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
DOCKERHUB_USER="${DOCKERHUB_USER:?Set DOCKERHUB_USER, for example: DOCKERHUB_USER=dubey23}"
TAG="${TAG:-1.0.0}"
[ -d app/backend ] || bash scripts/fetch-app.sh

docker build --platform linux/amd64 -f docker/backend.Dockerfile \
  -t "$DOCKERHUB_USER/student-backend:$TAG" .
docker build --platform linux/amd64 -f docker/frontend.Dockerfile \
  -t "$DOCKERHUB_USER/student-frontend:$TAG" .

docker push "$DOCKERHUB_USER/student-backend:$TAG"
docker push "$DOCKERHUB_USER/student-frontend:$TAG"
echo "Pushed $DOCKERHUB_USER/student-backend:$TAG and $DOCKERHUB_USER/student-frontend:$TAG"
echo "Make sure the image names in k8s/backend.yaml and k8s/frontend.yaml match."
