#!/bin/bash
set -e

# Cargar variables de entorno si están disponibles
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [ -f "$REPO_ROOT/load-env-variables.sh" ]; then
    source "$REPO_ROOT/load-env-variables.sh"
fi

echo "================================================================="
echo "[*] Fase 5 - Auditoría de Git, Archivos Sensibles y Estructura"
echo "================================================================="

# Variables de control
ERRORS_FOUND=0

# Función auxiliar para reportar fallos
report_error() {
    echo -e " [!] ERROR: $1"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
}

# 1. Comprobar que estamos dentro de un repositorio Git activo
echo -e "\n[+] 1. Verificando estado del repositorio Git..."
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "  [OK] Repositorio Git detectado."
else
    report_error "No se detectó un repositorio Git en esta carpeta."
fi

# 2. Comprobar la existencia y reglas básicas de .gitignore
echo -e "\n[+] 2. Verificando archivo .gitignore..."
if [ -f ".gitignore" ]; then
    echo "  [OK] Archivo .gitignore presente."

    PATTERNS=(".env" "*.key" "*.sql")
    for PATTERN in "${PATTERNS[@]}"; do
        if grep -q "$PATTERN" .gitignore; then
            echo "  [OK] Regla '$PATTERN' configurada en .gitignore."
        else
            echo "  [WARN] La regla '$PATTERN' no se encontró explícitamente en .gitignore."
        fi
    done
else
    report_error "No existe el archivo .gitignore en la raíz."
fi

# 3. Comprobar la existencia del archivo de variables de plantilla (.env.example / template.env)
echo -e "\n[+] 3. Verificando plantilla de variables de entorno..."
if [ -f "template.env" ] || [ -f ".env.example" ]; then
    echo "  [OK] Archivo de plantilla de variables presente."
else
    report_error "No se encontró template.env ni .env.example en la raíz del proyecto."
fi

# 4. Auditoría de archivos rastreados en Git (git ls-files) en busca de secretos/claves
echo -e "\n[+] 4. Auditando archivos rastreados en Git (búsqueda de secretos)..."
TRACKED_KEYS=$(git ls-files | grep -E '\.(key|p12|pfx|pem|crt\.key)$' || true)
if [ -n "$TRACKED_KEYS" ]; then
    report_error "Se encontraron claves privadas rastreadas en el historial de Git:\n$TRACKED_KEYS"
else
    echo "  [OK] No se encontraron claves privadas (.key, .p12, .pfx) rastreadas por Git."
fi

TRACKED_ENV=$(git ls-files | grep -E '(^|/)\.env$' || true)
if [ -n "$TRACKED_ENV" ]; then
    report_error "Se encontró un archivo .env real rastreado por Git:\n$TRACKED_ENV"
else
    echo "  [OK] Ningún archivo .env real está siendo rastreado por Git."
fi

TRACKED_BACKUPS=$(git ls-files | grep -E '\.(sql|sql\.gz|tar\.gz|zip)$' || true)
if [ -n "$TRACKED_BACKUPS" ]; then
    report_error "Se encontraron volcados/backups rastreados por Git:\n$TRACKED_BACKUPS"
else
    echo "  [OK] No se encontraron archivos de backup/SQL rastreados por Git."
fi

# 5. Comprobar la presencia de certificados públicos requeridos (PKI)
echo -e "\n[+] 5. Verificando disponibilidad de certificados públicos (PKI)..."
PUBLIC_CERTS=(
    "docs/mf0489/validations/fase3/server/ca.crt"
    "suricata/suricata.yaml"
    "docker-compose.yml"
    "README.md"
)

for CERT in "${PUBLIC_CERTS[@]}"; do
    if [ -f "$CERT" ]; then
        echo "  [OK] Archivo requerido encontrado: $CERT"
    else
        echo "  [WARN] Archivo no encontrado en la ruta esperada: $CERT"
    fi
done

# 6. Comprobar cambios sin confirmar (git status)
echo -e "\n[+] 6. Estado del árbol de trabajo (git status)..."
UNCOMMITTED=$(git status --porcelain || true)
if [ -n "$UNCOMMITTED" ]; then
    echo "  [INFO] Existen archivos modificados o sin seguimiento:"
    echo "$UNCOMMITTED"
else
    echo "  [OK] Árbol de trabajo limpio (sin cambios pendientes)."
fi

# Resumen de resultados
echo "================================================================="
if [ $ERRORS_FOUND -eq 0 ]; then
    echo "[*] AUDITORÍA COMPLETADA CON ÉXITO: El repositorio es seguro para su entrega."
else
    echo "[!] ATENCIÓN: Se encontraron $ERRORS_FOUND advertencia(s)/error(es) que deben corregirse."
fi
echo "================================================================="
