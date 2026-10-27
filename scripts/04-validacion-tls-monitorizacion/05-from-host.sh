#!/bin/bash
set -e

# Cargar variables de entorno desde la raíz del repositorio
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="${DOMAIN_NAME:-portal.artimar.thm}"
SERVER_IP="${SERVER_ADDRESS:-172.16.43.137}"
CA_CERT_PATH="${CA_CERT:-docs/mf0489/validations/fase3/server/ca.crt}"

echo "================================================================="
echo "[*] Actividad 17: Lanzamiento de peticiones de prueba desde el cliente"
echo "[*] Dominio: $DOMAIN | Servidor IP: $SERVER_IP"
echo "================================================================="

# 17.2. Observar una petición HTTP (redirección esperada 301/308)
echo -e "\n[+] 1. Ejecutando petición de prueba HTTP (puerto 80)..."
curl -v \
  --resolve "${DOMAIN}:80:${SERVER_IP}" \
  "http://${DOMAIN}/mf0489-prueba-http" \
  -o /dev/null || true

# 17.3. Observar una petición HTTPS (cifrada y segura)
echo -e "\n[+] 2. Ejecutando petición de prueba HTTPS (puerto 443)..."
curl -v \
  --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_IP}" \
  "https://${DOMAIN}/mf0489-prueba-https" \
  -o /dev/null

echo "================================================================="
echo "[*] Peticiones de prueba de la Actividad 17 ejecutadas con éxito."
echo "================================================================="