#!/bin/bash
set -e

# Load project environment variables centrally
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="$DOMAIN_NAME"
CA_DIR="$HOME/ca_root-pki/ca"

echo "[*] Accessing CA directory: $CA_DIR..."
if [ ! -d "$CA_DIR" ]; then
    echo "[!] ERROR: CA directory not found at $CA_DIR. Please run CA setup first."
    exit 1
fi
cd "$CA_DIR"

CSR_FILE="solicitudes/servidor.csr"
CRT_FILE="emitidos/servidor.crt"

if [ ! -f "$CSR_FILE" ]; then
    echo "[!] ERROR: CSR file not found at '$CA_DIR/$CSR_FILE'."
    exit 1
fi

echo "[*] Preparing server extension file (servidor.ext) for domain: $DOMAIN..."
cat <<EOF > servidor.ext
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${DOMAIN}
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

echo "[*] Signing CSR for domain '$DOMAIN' using CA root credentials..."
openssl x509 -req \
  -in "$CSR_FILE" \
  -CA ca.crt \
  -CAkey private/ca.key \
  -CAcreateserial \
  -out "$CRT_FILE" \
  -days 365 \
  -sha256 \
  -extfile servidor.ext

echo "[+] Certificate generated successfully at '$CRT_FILE'."

echo "[*] Automatically transferring signed certificate and CA root back to server ($SERVER_ADDRESS)..."
scp "$CRT_FILE" "ca.crt" "${SERVER_USER}@${SERVER_ADDRESS}:~/mf0489/"

echo "[+] SUCCESS: Certificates sent back to the server's working directory (~/mf0489/)."