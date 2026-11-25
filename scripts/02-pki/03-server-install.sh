#!/bin/bash
set -eo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/load-env-variables.sh"
DOMAIN="$DOMAIN_NAME"
WORK_DIR="$HOME/mf0489"

echo "[*] Checking received certificates in $WORK_DIR..."
cd "$WORK_DIR"

if [ ! -f "servidor.crt" ] || [ ! -f "ca.crt" ]; then
    echo "[!] ERROR: 'servidor.crt' or 'ca.crt' not found in $WORK_DIR."
    echo "[!] Please ensure the signing script has successfully returned the files from the CA."
    exit 1
fi

if [ ! -f "servidor.key" ] && [ ! -f /etc/ssl/private/servidor.key ]; then
    echo "[!] ERROR: No server private key found in $WORK_DIR or /etc/ssl/private."
    echo "[!] The server private key is required to verify the certificate match."
    exit 1
fi

for path in servidor.key servidor.crt ca.crt /etc/ssl/private/servidor.key /etc/ssl/certs/servidor.crt /etc/ssl/mf0489/ca.crt; do
    if [ -d "$path" ]; then
        echo "[!] ERROR: Expected a file at '$path', but found a directory."
        echo "[!] Move the directory aside and retry; this script will not install into it."
        exit 1
    fi
    if [ -e "$path" ] && [ ! -f "$path" ]; then
        echo "[!] ERROR: '$path' exists but is not a regular file."
        exit 1
    fi
done

echo "[*] Installing certificates into final system paths (/etc/ssl)..."
sudo mkdir -p -m 755 /etc/ssl/mf0489

if [ -f "$HOME/mf0489/servidor.key" ]; then
    sudo install -o root -g root -m 600 "$HOME/mf0489/servidor.key" /etc/ssl/private/servidor.key
fi
sudo install -o root -g root -m 644 "$HOME/mf0489/servidor.crt" /etc/ssl/certs/servidor.crt

sudo install -o root -g root -m 644 ca.crt /etc/ssl/mf0489/ca.crt


echo "[*] Verifying permissions in /etc/ssl..."
sudo ls -l /etc/ssl/private/servidor.key
ls -l /etc/ssl/certs/servidor.crt
sudo ls -l /etc/ssl/mf0489/ca.crt

echo "[*] Running trust chain verifications with OpenSSL..."
echo "[1] Expected verification (Success):"
sudo openssl verify -CAfile /etc/ssl/mf0489/ca.crt -purpose sslserver -verify_hostname "$DOMAIN" /etc/ssl/certs/servidor.crt

echo "[2] Hostname mismatch verification (Expected failure):"
openssl verify -CAfile /etc/ssl/mf0489/ca.crt -purpose sslserver -verify_hostname "wrong-server.test" /etc/ssl/certs/servidor.crt || true

echo "[*] Checking correspondence between private key and certificate..."
KEY_HASH=$(sudo openssl pkey -in /etc/ssl/private/servidor.key -pubout -outform DER | openssl dgst -sha256 | awk '{print $2}')
CRT_HASH=$(openssl x509 -in /etc/ssl/certs/servidor.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 | awk '{print $2}')

echo "Private key hash: $KEY_HASH"
echo "Certificate hash:    $CRT_HASH"

if [ "$KEY_HASH" != "$CRT_HASH" ]; then
    echo "[!] ERROR: Private key and certificate do not match."
    exit 1
fi

echo "[+] Public keys match successfully!"
rm -f "$WORK_DIR/servidor.key"
echo "[+] Temporary private key copy removed from $WORK_DIR."
