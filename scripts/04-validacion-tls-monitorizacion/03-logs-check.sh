#!/bin/bash
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

echo "================================================================="
echo " Verificación de Servidor e Interfaces para Suricata"
echo "================================================================="

echo "[+] 1. Identificando interfaces de red del sistema..."
ip -br address

echo -e "\n[+] 2. Comprobando el estado del servicio Suricata..."
sudo systemctl status suricata --no-pager || true

echo -e "\n[+] 3. Mostrando los registros recientes de Suricata (eve.json)..."
if [ -f /var/log/suricata/eve.json ]; then
    sudo tail -n 15 /var/log/suricata/eve.json
else
    echo "[INFO] El archivo /var/log/suricata/eve.json no se encuentra accesible."
fi
