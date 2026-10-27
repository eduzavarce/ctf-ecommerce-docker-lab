#!/bin/bash
set -e

# Cargar variables de entorno desde la raíz del repositorio
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="${DOMAIN_NAME:-portal.artimar.thm}"
SERVER_IP="${SERVER_ADDRESS:-172.16.43.137}"
CA_CERT_PATH="${CA_CERT:-docs/mf0489/validations/fase3/server/ca.crt}"

echo "================================================================="
echo "[*] Automatización y pruebas de correlación - Actividad 18"
echo "[*] Dominio: $DOMAIN | Servidor IP: $SERVER_IP"
echo "================================================================="

# 1. Aplicar cambios actualizando el contenedor reverse-proxy sin destruir volúmenes
echo "[+] 1. Recreando el contenedor reverse-proxy de forma segura con la nueva configuración..."
docker compose up -d --no-deps --force-recreate reverse-proxy

# 2. Validar sintaxis de Nginx dentro del contenedor
echo -e "\n[+] 2. Verificando la sintaxis de Nginx (nginx -t)..."
docker compose exec -T reverse-proxy nginx -t

# 3. Recargar Nginx de forma limpia
echo -e "\n[+] 3. Recargando la configuración en caliente (nginx -s reload)..."
docker compose exec -T reverse-proxy nginx -s reload

# 4. Lanzar la petición de prueba identificable (Actividad 18.3)
echo -e "\n[+] 4. Lanzando petición HTTPS de prueba para correlación (/mf0489-correlacion-01)..."
curl -v \
  --cacert "$CA_CERT_PATH" \
  --resolve "${DOMAIN}:443:${SERVER_IP}" \
  "https://${DOMAIN}/mf0489-correlacion-01" \
  -o /dev/null || true

# 5. Mostrar los registros generados en Nginx (con datos TLS)
echo -e "\n[+] 5. Comprobando los registros recientes de Nginx (con datos TLS):"
docker compose logs --tail=5 reverse-proxy

# 6. Comprobar alertas rápidas en Suricata (fast.log)
echo -e "\n[+] 6. Comprobando las alertas recientes en Suricata (fast.log):"
sudo tail -n 5 /var/log/suricata/fast.log || echo "[INFO] Sin registros en fast.log"

# 7. Comprobación estructurada en Suricata (eve.json) para la regla sid:1000002
echo -e "\n[+] 7. Verificando eventos estructurados en Suricata (eve.json) para sid:1000002..."
sudo jq -c 'select(.event_type == "alert" and .alert.signature_id == 1000002) | {timestamp, event_type, src_ip, dest_ip, alert: .alert.signature}' /var/log/suricata/eve.json | tail -n 3 || echo "[INFO] No se encontraron alertas estructuradas todavía."

echo "================================================================="
echo "[*] Proceso de validación y correlación completado."
echo "================================================================="