#!/bin/bash
set -e

if [ ! -f .env ]; then
    echo "CRITICAL ERROR: .env file is required but not found."
		echo "Please create a .env file based on the .env.example template."
    exit 1
fi

./scripts/00-initial-setup/00-create-folders.sh
./scripts/00-initial-setup/01-install-docker.sh
./scripts/00-initial-setup/02-install-dependencies.sh

docker compose up -d

./scripts/01-suricata/00-install.sh
./scripts/01-suricata/01-config.sh

echo ""
echo "=================================================="
echo "   DEPLOY PROCESS COMPLETED SUCCESSFULLY!"
echo "=================================================="