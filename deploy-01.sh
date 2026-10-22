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

echo ""
echo "=================================================="
echo "   PLEASE LOG OUT AND LOG IN AGAIN!"
echo "then run the following command:"
echo "   ./deploy-02.sh"
echo "=================================================="

