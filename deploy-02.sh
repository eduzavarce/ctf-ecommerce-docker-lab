#!/bin/bash
 docker compose up -d

./scripts/01-suricata/00-install.sh
./scripts/01-suricata/01-config.sh

echo ""
echo "=================================================="
echo "   DEPLOY PROCESS COMPLETED SUCCESSFULLY!"
echo "=================================================="