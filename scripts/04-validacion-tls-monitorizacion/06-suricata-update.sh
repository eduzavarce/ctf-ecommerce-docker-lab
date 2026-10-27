#!/bin/bash
set -e

CONFIG_FILE="/etc/suricata/suricata.yaml"
RULE_FILE="/etc/suricata/rules/local.rules"

# Regla específica para la Actividad 18 (Detectar SYN hacia el puerto 443)
RULE='alert tcp any any -> $HOME_NET 443 (msg:"MF0489 - Conexion HTTPS observada"; flags:S; sid:1000002; rev:1;)'

echo "================================================================="
echo "[*] Automatización de Suricata para la Actividad 18"
echo "================================================================="

echo "[*] Escaneando interfaces de red activas..."
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")

INTERFACE=$(echo "$INTERFACES" | fzf --height=5 --reverse --prompt="Selecciona la interfaz para Suricata > ")

if [ -z "$INTERFACE" ]; then
    echo "[!] No se seleccionó ninguna interfaz. Saliendo."
    exit 1
fi

echo "[+] Interfaz seleccionada: $INTERFACE"

echo "[*] Detectando IP y subred del host..."
HOST_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | cut -d'/' -f1)
SUBNET_BASE=$(echo "$HOST_IP" | cut -d'.' -f1-3)
HOST_NET="${SUBNET_BASE}.0/24"
HOME_NET_VAL="[$HOST_NET]"

echo "[+] Red detectada para HOME_NET: $HOME_NET_VAL"

# Comprobar y añadir la regla en local.rules si no existe previamente
if ! sudo grep -q "sid:1000002" "$RULE_FILE" 2>/dev/null; then
    echo "[*] Añadiendo regla de detección HTTPS a $RULE_FILE..."
    echo "$RULE" | sudo tee -a "$RULE_FILE" > /dev/null
else
    echo "[+] La regla con sid:1000002 ya existe en $RULE_FILE."
fi

# Actualizar la interfaz y la red HOME_NET directamente en el suricata.yaml activo
echo "[*] Actualizando configuración en $CONFIG_FILE..."
sudo sed -i -E \
    -e "s|HOME_NET: \".*\"|HOME_NET: \"$HOME_NET_VAL\"|g" \
    -e "s|- interface: .*|- interface: $INTERFACE|g" \
    "$CONFIG_FILE"

echo "[*] Validando la configuración de Suricata..."
sudo suricata -T -c "$CONFIG_FILE"

echo "[*] Reiniciando el servicio Suricata..."
sudo systemctl restart suricata

echo "================================================================="
echo "[*] Estado actual del servicio Suricata:"
echo "================================================================="
sudo systemctl status suricata --no-pager