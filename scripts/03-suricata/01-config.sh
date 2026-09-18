#!/bin/bash
set -e

CONFIG_FILE="/etc/suricata/suricata.yaml"
RULE_FILE="/etc/suricata/rules/local.rules"

echo "[*] Detectando interfaces de red activas..."
# Obtener lista de interfaces excluyendo loopback
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")

# Si fzf está instalado, permitimos seleccionar; si no, cogemos la primera por defecto
if command -v fzf &> /dev/null; then
    INTERFACE=$(echo "$INTERFACES" | fzf --height=5 --reverse --prompt="Selecciona la interfaz para Suricata > ")
else
    INTERFACE=$(echo "$INTERFACES" | head -n 1)
fi

if [ -z "$INTERFACE" ]; then
    echo "[-] No se seleccionó ninguna interfaz. Saliendo."
    exit 1
fi
echo "[+] Interfaz seleccionada: $INTERFACE"

echo "[*] Detectando IP y subred del host..."
# Obtener la IP principal de la interfaz seleccionada y calcular la red /24
HOST_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | cut -d'/' -f1)
SUBNET_BASE=$(echo "$HOST_IP" | cut -d'.' -f1-3)
HOST_NET="${SUBNET_BASE}.0/24"

HOME_NET_VAL="[$HOST_NET, 172.20.10.0/24, 172.20.20.0/24]"
echo "[+] Redes configuradas para HOME_NET: $HOME_NET_VAL"

echo "[*] Verificando instalación de Suricata..."
if ! command -v suricata &> /dev/null; then
    sudo apt update && sudo apt install suricata -y
fi

echo "[*] Configurando suricata.yaml..."
if [ ! -f "${CONFIG_FILE}.bak" ]; then
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# # Actualizar HOME_NET
# sudo sed -i "s|^\s*HOME_NET: \".*\"|    HOME_NET: \"$HOME_NET_VAL\"|" "$CONFIG_FILE" || \
# sudo sed -i "s|^\s*HOME_NET: .*|    HOME_NET: \"$HOME_NET_VAL\"|" "$CONFIG_FILE"

# # Actualizar la interfaz de red en af-packet (reemplazando la interfaz anterior que estuviera configurada)
# sudo sed -i "s/interface: .*/interface: $INTERFACE/" "$CONFIG_FILE"

# echo "[*] Asegurando regla personalizada ICMP en $RULE_FILE..."
# RULE='alert icmp any any -> $HOME_NET any (msg:"ping detectado hacia la red protegida"; sid:1000001; rev:1;)'

# if ! sudo grep -q "sid:1000001" "$RULE_FILE" 2>/dev/null; then
#     echo "$RULE" | sudo tee -a "$RULE_FILE" > /dev/null
#     echo "[+] Regla añadida correctamente."
# else
#     echo "[i] La regla ya se encontraba configurada."
# fi

# echo "[*] Reiniciando y comprobando el estado de Suricata..."
# sudo systemctl restart suricata
# sudo systemctl status suricata --no-pager