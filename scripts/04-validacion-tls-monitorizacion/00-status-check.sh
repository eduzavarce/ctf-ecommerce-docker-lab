#!/bin/bash

# Cargar variables de entorno desde la raíz del repositorio
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

# Asignar valores por defecto seguros basados en las variables cargadas o estándares del laboratorio
DOMAIN="${DOMAIN_NAME:-portal.artimar.thm}"
SERVER_IP="${SERVER_ADDRESS:-127.0.0.1}"
CA_CERT_PATH="../../docs/mf0489/validations/fase3/server/ca.crt"

echo "================================================================="
echo "[*] Actividad 15: Línea base de HTTPS y verificación TLS"
echo "[*] Dominio: $DOMAIN | Servidor IP: $SERVER_IP"
echo "[*] Certificado CA: $CA_CERT_PATH"
echo "================================================================="

# 15.1. Comprobar el estado de la infraestructura
echo -e "\n[+] 1. Comprobando estado de contenedores Docker..."
docker compose ps

echo -e "\n[+] 2. Comprobando puertos activos en escucha (ss)..."
sudo ss -ltnp

echo -e "\n[+] 3. Verificando la carga de configuración de Nginx..."
docker compose exec -T reverse-proxy nginx -t

# 15.3. Verificar la conexión HTTPS real con el certificado de la CA
echo -e "\n[+] 4. Verificando conexión HTTPS mediante curl (con validación de CA)..."
curl -v \
  --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_IP}" \
  "https://${DOMAIN}/" \
  -o /dev/null

echo -e "\n[+] 5. Verificando versión TLS, cipher suite y confianza con OpenSSL..."
openssl s_client \
  -connect "${SERVER_IP}:443" \
  -servername "$DOMAIN" \
  -CAfile "$CA_CERT_PATH" \
  -verify_hostname "$DOMAIN" \
  -verify_return_error \
  -brief </dev/null

echo "================================================================="
echo "[*] Verificaciones completadas con éxito."
echo "================================================================="
