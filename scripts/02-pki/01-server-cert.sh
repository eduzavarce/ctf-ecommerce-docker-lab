#!/bin/bash
set -e

# Load project environment variables centrally
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="$DOMAIN_NAME"
WORK_DIR="$HOME/mf0489"

echo "[*] Preparing temporary directory $WORK_DIR for domain: $DOMAIN..."
umask 077
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ ! -f "servidor.key" ] && [ ! -f "/etc/ssl/private/servidor.key" ]; then
    echo "[*] Generating server private key (RSA 3072)..."
    openssl genpkey -algorithm RSA -out servidor.key -pkeyopt rsa_keygen_bits:3072
    chmod 600 servidor.key
fi

if [ ! -f "servidor.csr" ]; then
    echo "[*] Generating CSR with SAN for ${DOMAIN}..."
    openssl req -new \
      -sha256 \
      -key servidor.key \
      -out servidor.csr \
      -subj "/CN=${DOMAIN}" \
      -addext "subjectAltName=DNS:${DOMAIN}"
fi

echo "[*] Verifying generated CSR..."
openssl req -in servidor.csr -text -noout -verify

echo "[*] Automatically transferring 'servidor.csr' to CA machine ($CA_MACHINE_ADDRESS)..."
scp servidor.csr "${CA_MACHINE_USER}@${CA_MACHINE_ADDRESS}:~/ca_root-pki/ca/solicitudes/"

echo "[+] SUCCESS: CSR sent to CA. You can now execute the signing script on the CA machine."