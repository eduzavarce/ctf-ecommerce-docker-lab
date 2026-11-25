#!/bin/bash
set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"

DOMAIN="$DOMAIN_NAME"
CA_DIR="$HOME/ca_root-pki/ca"

echo "[*] Preparing CA environment for domain: $DOMAIN in $CA_DIR..."
umask 077

for path in "$CA_DIR" "$CA_DIR/private" "$CA_DIR/solicitudes" "$CA_DIR/emitidos"; do
    if [ -e "$path" ] && [ ! -d "$path" ]; then
        echo "[!] ERROR: Expected a directory at '$path', but found a non-directory path."
        exit 1
    fi
done

mkdir -p "$CA_DIR"/{private,solicitudes,emitidos}
cd "$CA_DIR"

for path in private/ca.key ca.crt servidor.ext solicitudes/servidor.csr emitidos/servidor.crt; do
    if [ -d "$path" ]; then
        echo "[!] ERROR: Expected a file at '$CA_DIR/$path', but found a directory."
        echo "[!] Move the directory aside and retry; this script will not overwrite it."
        exit 1
    fi
done

if [ ! -f "private/ca.key" ]; then
    echo "[*] Generating CA private key (RSA 4096 with AES-256)..."
    openssl genpkey -algorithm RSA -out private/ca.key -pkeyopt rsa_keygen_bits:4096 -aes-256-cbc
    chmod 600 private/ca.key
else
    echo "[+] CA private key already exists."
fi

if [ ! -f "ca.crt" ]; then
    echo "[*] Generating self-signed root CA certificate (10 years)..."
    openssl req -x509 -new \
      -sha256 \
      -days 3650 \
      -key private/ca.key \
      -out ca.crt \
      -subj "/C=ES/O=Art i Mar Cambrils/CN=Art i Mar Root CA" \
      -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
      -addext "keyUsage=critical,keyCertSign,cRLSign" \
      -addext "subjectKeyIdentifier=hash"
else
    echo "[+] ca.crt certificate already exists."
fi

echo "[*] Verifying CA certificate validity..."
openssl verify -CAfile ca.crt ca.crt

echo "[*] Preparing server extension file (servidor.ext)..."
cat <<EOF > servidor.ext
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${DOMAIN}
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

if [ -f "solicitudes/servidor.csr" ]; then
    echo "[*] Signing received request for $DOMAIN..."
    openssl x509 -req \
      -in solicitudes/servidor.csr \
      -CA ca.crt \
      -CAkey private/ca.key \
      -CAcreateserial \
      -out emitidos/servidor.crt \
      -days 365 \
      -sha256 \
      -extfile servidor.ext

    echo "[+] Certificate emitidos/servidor.crt successfully generated."
fi
