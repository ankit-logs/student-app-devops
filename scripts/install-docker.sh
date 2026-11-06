#!/usr/bin/env bash
# Install Docker and Docker Compose on Ubuntu (EC2).
# Uses group membership instead of 'chmod 777 /var/run/docker.sock',
# which would let any user on the machine control Docker (and so the host).
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y docker.io git curl

sudo systemctl enable --now docker

# Allow the current user to run docker without sudo (takes effect after logging in again).
sudo usermod -aG docker "$USER"

# Compose v2 plugin: use the Ubuntu package if available, otherwise download the binary.
if ! docker compose version >/dev/null 2>&1; then
  if ! sudo apt-get install -y docker-compose-v2; then
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -fsSL \
      "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  fi
fi

echo
sudo docker --version
sudo docker compose version
echo "Log out and back in (or run 'newgrp docker') so 'docker' works without sudo."
