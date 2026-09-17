#!/bin/bash

echo "==> Downloading Docker installation script..."
sudo apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

echo "==> Adding user ($USER) to the docker group..."
sudo usermod -aG docker "$USER"

echo "==> Enabling Docker service on boot..."
sudo systemctl enable --now docker

echo "==> Verifying non-root Docker execution..."
sg docker -c "docker run --rm hello-world"

echo "==> Docker installation complete!"