#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$PROJECT_ROOT/.env" ]; then
    if [ -f "$PROJECT_ROOT/template.env" ]; then
        echo "[*] .env file not found. Please initialize it from template.env..."
        exit 1
    else
        echo "[!] Warning: Neither .env nor template.env found in $PROJECT_ROOT."
        exit 1
    fi
fi

set -a

source "$PROJECT_ROOT/.env"

set +a