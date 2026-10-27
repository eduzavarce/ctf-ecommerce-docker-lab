#!/bin/bash
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"


DOMAIN="portal.artimar.thm"
SERVER_ADDRESS="${SERVER_ADDRESS:-192.168.1.39}"
CA_CERT_PATH="${CA_CERT_PATH:-../../docs/mf0489/validations/fase3/server/ca.crt}"



echo "================================================================="
echo "[*] Iniciando validaciones de cliente para el dominio: $DOMAIN"
echo "[*] IP del Servidor Objetivo: $SERVER_ADDRESS"
echo "================================================================="

# 1. Prueba de redirección HTTP -> HTTPS
echo -e "\n[+] 1. Probando redirección HTTP (puerto 80) a HTTPS..."
curl -I \
  --resolve "${DOMAIN}:80:${SERVER_ADDRESS}" \
  "http://${DOMAIN}/"

# 2. Verificación de acceso HTTPS con la CA (Sin ignorar confianza)
echo -e "\n[+] 2. Probando conexión HTTPS segura con validación de CA (--cacert)..."
curl -v \
  --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_ADDRESS}" \
  "https://${DOMAIN}/" \
  -o /dev/null

# 3. Verificación avanzada de TLS mediante OpenSSL s_client
echo -e "\n[+] 3. Ejecutando verificación avanzada TLS con OpenSSL..."
openssl s_client \
  -connect "${SERVER_ADDRESS}:443" \
  -servername "$DOMAIN" \
  -CAfile "$CA_CERT_PATH" \
  -verify_hostname "$DOMAIN" \
  -verify_return_error \
  -brief \
  </dev/null

echo "================================================================="
echo "[*] Validaciones de cliente completadas."
echo "================================================================="