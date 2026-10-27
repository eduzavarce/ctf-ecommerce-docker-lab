#!/bin/bash
set -e

# Cargar variables de entorno desde la raíz del repositorio
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

# Asignar valores por defecto seguros basados en las variables cargadas
DOMAIN="${DOMAIN_NAME:-portal.artimar.thm}"
SERVER_IP="${SERVER_ADDRESS:-172.16.43.137}"
CA_CERT_PATH="${CA_CERT:-../../docs/mf0489/validations/fase3/server/ca.crt}"

echo "================================================================="
echo "[*] Actividad 16: Auditoría y Ajuste de TLS"
echo "[*] Dominio: $DOMAIN | Servidor IP: $SERVER_IP"
echo "================================================================="

# 16.1. Revisar los protocolos permitidos en la configuración activa de Nginx
echo -e "\n[+] 1. Comprobando directivas ssl_protocols en la configuración activa (nginx -T)..."
docker compose exec -T reverse-proxy nginx -T | grep -i "ssl_protocols" || echo "[INFO] Directiva no encontrada de forma directa en el grep."

# 16.2. Negociar TLS 1.2 desde el cliente
echo -e "\n[+] 2. Probando conexión forzando TLS 1.2..."
openssl s_client \
  -connect "${SERVER_IP}:443" \
  -servername "$DOMAIN" \
  -CAfile "$CA_CERT_PATH" \
  -verify_hostname "$DOMAIN" \
  -verify_return_error \
  -tls1_2 -brief </dev/null && echo "[OK] Negociación TLS 1.2 exitosa."

# Negociar TLS 1.3 desde el cliente
echo -e "\n[+] 3. Probando conexión forzando TLS 1.3..."
openssl s_client \
  -connect "${SERVER_IP}:443" \
  -servername "$DOMAIN" \
  -CAfile "$CA_CERT_PATH" \
  -verify_hostname "$DOMAIN" \
  -verify_return_error \
  -tls1_3 -brief </dev/null && echo "[OK] Negociación TLS 1.3 exitosa."

# 16.3. Comprobar protocolo obsoleto (TLS 1.1 - Prueba negativa esperada a fallo)
echo -e "\n[+] 4. Probando protocolo obsoleto TLS 1.1 (debe fallar o ser rechazado)..."
if openssl s_client \
  -connect "${SERVER_IP}:443" \
  -servername "$DOMAIN" \
  -tls1_1 -brief </dev/null; then
    echo "[ADVERTENCIA] TLS 1.1 respondió positivamente (revisar configuración)."
else
    echo "[OK] Correcto: La conexión con TLS 1.1 fue rechazada o falló como se esperaba."
fi

echo "================================================================="
echo "[*] Auditoría de protocolos TLS completada."
echo "================================================================="
