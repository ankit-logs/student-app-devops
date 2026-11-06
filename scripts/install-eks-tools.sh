#!/usr/bin/env bash
# Install AWS CLI, kubectl and eksctl on an Ubuntu admin machine (x86_64).
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y curl unzip

# AWS CLI v2
if ! command -v aws >/dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
fi

# kubectl (latest stable)
if ! command -v kubectl >/dev/null; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi

# eksctl
if ! command -v eksctl >/dev/null; then
  curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    | tar xz -C /tmp
  sudo install -o root -g root -m 0755 /tmp/eksctl /usr/local/bin/eksctl
fi

aws --version
kubectl version --client
eksctl version
echo "Next: run 'aws configure' (or attach an IAM role to this machine)."
