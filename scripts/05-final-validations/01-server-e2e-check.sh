#!/bin/bash
set -e

# Cargar variables de entorno si están disponibles
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

echo "================================================================="
echo "[*] Fase 5 - Verificación de Extremo a Extremo (Lado Servidor)"
echo "================================================================="

CHECKS_PASSED=0
TOTAL_CHECKS=4

# 1. Comprobar estado de los contenedores Docker
echo -e "\n[+] 1. Comprobando estado de la orquestación Docker..."
if docker compose ps --format "{{.Service}} {{.State}}" | grep -q "running"; then
    echo "  [OK] Los contenedores de la orquestación están activos y corriendo."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ERROR: Hay contenedores detenidos o con problemas."
fi

# 2. Comprobar sintaxis y estado de Nginx
echo -e "\n[+] 2. Verificando configuración del Reverse Proxy (Nginx)..."
if docker compose exec -T reverse-proxy nginx -t >/dev/null 2>&1; then
    echo "  [OK] Sintaxis de Nginx correcta."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ERROR: Falló la validación de sintaxis de Nginx."
fi

# 3. Comprobación del servicio Suricata IDS
echo -e "\n[+] 3. Verificando estado del servicio Suricata IDS..."
if systemctl is-active --quiet suricata; then
    echo "  [OK] El servicio Suricata está activo y operativo."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ADVERTENCIA: El servicio Suricata no está activo en el sistema."
fi

# 4. Comprobación de puertos en escucha en el host
echo -e "\n[+] 4. Verificando puertos expuestos (80 y 443)..."
if ss -tlnp | grep -E ':(80|443)\b' >/dev/null 2>&1; then
    echo "  [OK] Puertos 80 y 443 escuchando correctamente en el host."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ADVERTENCIA: No se detectaron los puertos web escuchando."
fi

echo "================================================================="
echo "[*] Resultado Servidor: $CHECKS_PASSED / $TOTAL_CHECKS verificaciones superadas."
echo "================================================================="
