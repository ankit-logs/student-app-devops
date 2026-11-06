#!/usr/bin/env bash
# Download the application source (React frontend + Spring Boot backend) into ./app.
# The source belongs to its original author and is used here only as the build input.
# It is git-ignored, so it is never committed to this repository.
#
# Options:  APP_REPO  (default: https://github.com/prathamnandgirwar/student-app-k8s.git)
#           APP_REF   branch or tag to use (default: main)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
APP_REPO="${APP_REPO:-https://github.com/prathamnandgirwar/student-app-k8s.git}"
APP_REF="${APP_REF:-main}"

if [ -d app/.git ]; then
  git -C app fetch --depth 1 origin "$APP_REF"
  git -C app checkout -q FETCH_HEAD
else
  git clone --depth 1 --branch "$APP_REF" "$APP_REPO" app
fi
echo "Application source ready in ./app (commit $(git -C app rev-parse --short HEAD))"
