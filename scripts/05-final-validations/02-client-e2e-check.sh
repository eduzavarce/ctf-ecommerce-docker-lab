#!/bin/bash
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="${DOMAIN_NAME:-portal.artimar.thm}"
SERVER_IP="${SERVER_ADDRESS:-172.16.43.137}"
CA_CERT_PATH="${CA_CERT:-docs/mf0489/validations/fase3/server/ca.crt}"

echo "================================================================="
echo "[*] Fase 5 - Verificación de Extremo a Extremo (Perspectiva Cliente)"
echo "[*] Dominio: $DOMAIN | Servidor IP: $SERVER_IP"
echo "================================================================="

CHECKS_PASSED=0
TOTAL_CHECKS=4

# 1. Comprobación de redirección HTTP a HTTPS
echo -e "\n[+] 1. Comprobando redirección perimetral HTTP -> HTTPS..."
REDIRECT_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --resolve "${DOMAIN}:80:${SERVER_IP}" \
  "http://${DOMAIN}/")

if [ "$REDIRECT_CODE" -eq 301 ] || [ "$REDIRECT_CODE" -eq 302 ]; then
    echo "  [OK] Redirección HTTP a HTTPS funcionando (Código: $REDIRECT_CODE)."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ERROR: Redirección HTTP inesperada (Código: $REDIRECT_CODE)."
fi

# 2. Verificación de confianza TLS utilizando el certificado CA (--cacert)
echo -e "\n[+] 2. Validando cadena de confianza HTTPS frente a la CA..."
if curl -s --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_IP}" \
  "https://${DOMAIN}/" -o /dev/null; then
    echo "  [OK] Certificado validado correctamente con la CA (Sin errores de confianza)."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ERROR: Falló la validación de confianza TLS con el certificado CA."
fi

# 3. Verificación criptográfica con OpenSSL (Server Name Indication y FQDN)
echo -e "\n[+] 3. Comprobando negociación TLS y FQDN mediante OpenSSL..."
if echo | openssl s_client -connect "${SERVER_IP}:443" -servername "$DOMAIN" -CAfile "$CA_CERT_PATH" 2>/dev/null | grep -q "Verification: OK"; then
    echo "  [OK] OpenSSL confirmó 'Verification: OK' para el dominio $DOMAIN."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ADVERTENCIA: La verificación estricta de OpenSSL no devolvió OK."
fi

# 4. Respuesta funcional de la aplicación web (WordPress)
echo -e "\n[+] 4. Comprobando respuesta de la aplicación web (WordPress)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_IP}" \
  "https://${DOMAIN}/")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 302 ] || [ "$HTTP_CODE" -eq 404 ]; then
    echo "  [OK] Aplicación web accesible por HTTPS (Código HTTP: $HTTP_CODE)."
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  [!] ADVERTENCIA: Código de respuesta HTTP inesperado: $HTTP_CODE"
fi

echo "================================================================="
echo "[*] Resultado Cliente: $CHECKS_PASSED / $TOTAL_CHECKS verificaciones superadas."
echo "================================================================="
