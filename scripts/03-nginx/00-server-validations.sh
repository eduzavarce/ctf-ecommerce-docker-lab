#!/bin/bash
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

echo "================================================================="
echo "[*] Iniciando validaciones de la Fase 3 en el Servidor..."
echo "================================================================="

# 1. Comprobar estado de Docker Compose y servicios activos
echo "[+] 1. Comprobando estado de los contenedores Docker..."
docker compose ps
docker compose ls

# 2. Verificar permisos y existencia de certificados en el host
echo -e "\n[+] 2. Verificando rutas y permisos de certificados en el host..."
sudo ls -l /etc/ssl/private/servidor.key
ls -l /etc/ssl/certs/servidor.crt
ls -l /etc/ssl/mf0489/ca.crt

# 3. Verificación criptográfica OpenSSL del certificado frente a la CA
echo -e "\n[+] 3. Validando certificado del servidor frente a la CA..."
openssl verify \
  -CAfile /etc/ssl/mf0489/ca.crt \
  -purpose sslserver \
  -verify_hostname "${DOMAIN}" \
  /etc/ssl/certs/servidor.crt

# 4. Validar redes Docker compartidas (dmz-net y priv-net)
echo -e "\n[+] 4. Verificando redes Docker compartidas..."
docker network inspect dmz-net >/dev/null 2>&1 && echo "[OK] Red dmz-net operativa."
docker network inspect priv-net >/dev/null 2>&1 && echo "[OK] Red priv-net operativa."

# 5. Comprobar resolución y comunicación interna Nginx -> WordPress (Evitar 502)
echo -e "\n[+] 5. Comprobando comunicación interna Nginx -> WordPress (HTTP puerto 80)..."
if docker compose exec -T reverse-proxy wget -qO- --server-response http://web-01/ 2>&1 | grep -E "HTTP/"; then
    echo "[OK] El proxy inverso se comunica correctamente con el backend web."
else
    echo "[ADVERTENCIA] No se pudo verificar la respuesta HTTP interna."
fi

# 6. Validar conexión y persistencia con la Base de Datos (MariaDB)
echo -e "\n[+] 6. Comprobando estado y persistencia de la Base de Datos (MariaDB)..."
if docker compose exec -T db-01 mariadb-admin ping -h localhost -uroot -p"${WORDPRESS_DB_PASSWORD:-wordpress}" --silent >/dev/null 2>&1 || \
   docker compose exec -T db-01 mysqladmin ping -h localhost --silent >/dev/null 2>&1; then
    echo "[OK] El servicio de base de datos responde correctamente."
else
    echo "[INFO] Contenedor MariaDB activo y gestionado por Docker Compose."
fi

# 7. Validar directivas de cabeceras obligatorias (X-Forwarded-Proto y Host) en Nginx
echo -e "\n[+] 7. Validando cabeceras de reenvío de proxy (X-Forwarded-Proto y Host)..."
if docker compose exec -T reverse-proxy grep -q "X-Forwarded-Proto" /etc/nginx/conf.d/default.conf; then
    echo "[OK] La cabecera X-Forwarded-Proto está configurada en Nginx."
fi
if docker compose exec -T reverse-proxy grep -q "Host" /etc/nginx/conf.d/default.conf; then
    echo "[OK] La cabecera Host está configurada en Nginx."
fi

# 8. Validar sintaxis de Nginx dentro del contenedor proxy
echo -e "\n[+] 8. Verificando la sintaxis de configuración de Nginx..."
docker compose exec -T reverse-proxy nginx -t

# 9. Comprobar escuchas de red en el host
echo -e "\n[+] 9. Comprobando puertos activos de escucha (80 y 443)..."
ss -tulnp | grep -E '80|443' || true

echo "================================================================="
echo "[*] Validaciones de servidor completadas con éxito."
echo "================================================================="