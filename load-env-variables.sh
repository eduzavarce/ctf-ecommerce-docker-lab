#!/bin/bash
# Helper script to automatically load and export every variable from the .env file

# Determine the absolute path of the project root (where this script resides)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If .env does not exist, initialize it from template.env
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    if [ -f "$PROJECT_ROOT/template.env" ]; then
        echo "[*] .env file not found. Please initialize it from template.env..."
        exit 1
    else
        echo "[!] Warning: Neither .env nor template.env found in $PROJECT_ROOT."
        exit 1
    fi
fi

# Enable automatic export for all variables defined or sourced hereafter
set -a

# Source the .env file so every variable inside it is loaded and exported
source "$PROJECT_ROOT/.env"

# Disable automatic export mode
set +a