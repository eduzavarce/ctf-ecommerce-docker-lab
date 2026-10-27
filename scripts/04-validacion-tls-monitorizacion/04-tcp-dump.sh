#!/bin/bash

# Cargar variables de entorno desde la raíz del repositorio
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

echo "================================================================="
echo "[*] Herramienta interactiva de captura con tcpdump (Actividad 17)"
echo "================================================================="

echo "[*] Escaneando interfaces de red activas..."
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")

INTERFACE=$(echo "$INTERFACES" | fzf --height=5 --reverse --prompt="Selecciona la interfaz de red > ")

if [ -z "$INTERFACE" ]; then
    echo "[!] No se seleccionó ninguna interfaz. Saliendo."
    exit 1
fi

echo "[+] Interfaz seleccionada: $INTERFACE"

echo "[*] Seleccionando puerto de monitorización..."
PORT_CHOICE=$(echo -e "80 (HTTP)\n443 (HTTPS)" | fzf --height=4 --reverse --prompt="Selecciona el puerto > ")

if [ -z "$PORT_CHOICE" ]; then
    echo "[!] No se seleccionó ningún puerto. Saliendo."
    exit 1
fi

PORT=$(echo "$PORT_CHOICE" | awk '{print $1}')

echo "[+] Puerto seleccionado: $PORT"
echo "[*] Iniciando tcpdump en la interfaz $INTERFACE para el puerto $PORT..."
echo "[*] Presiona Ctrl+C para detener la captura."
echo "================================================================="

sudo tcpdump -i "$INTERFACE" -nn -s 0 -A "tcp port $PORT"