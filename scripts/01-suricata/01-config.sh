#!/bin/bash
set -e

CONFIG_FILE="/etc/suricata/suricata.yaml"
RULE_FILE="/etc/suricata/rules/local.rules"
RULE='alert icmp any any -> $HOME_NET any (msg:"ping detectado hacia la red protegida"; sid:1000001; rev:1;)'

echo "[*] Scanning active network interfaces..."
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")

INTERFACE=$(echo "$INTERFACES" | fzf --height=5 --reverse --prompt="Select interface to trace with Suricata > ")

echo "[+] Selected interface: $INTERFACE"

echo "[*] Detecting IP and subnet of the host..."
HOST_IP=$(ip -4 addr show dev "$INTERFACE" | grep inet | awk '{print $2}' | cut -d'/' -f1)
SUBNET_BASE=$(echo "$HOST_IP" | cut -d'.' -f1-3)
HOST_NET="${SUBNET_BASE}.0/24"

HOME_NET_VAL="[$HOST_NET]"

if ! sudo grep -q "sid:1000001" "$RULE_FILE" 2>/dev/null; then
    echo "$RULE" | sudo tee -a "$RULE_FILE" > /dev/null
fi

sudo sed -i "s|^\s*HOME_NET: \".*\"|    HOME_NET: \"$HOME_NET_VAL\"|" "$CONFIG_FILE" || \
sudo sed -i "s|^\s*HOME_NET: .*|    HOME_NET: \"$HOME_NET_VAL\"|" "$CONFIG_FILE"

# sudo sed -i '/^[[:space:]]*af-packet:/,/^[[:space:]]*-[[:space:]]*interface:/ s/^[[:space:]]*interface:.*/    - interface: '"$INTERFACE"'/' "$CONFIG_FILE"

echo "[*] Verifying declaration of local.rules in $CONFIG_FILE..."
if ! sudo grep -q "local.rules" "$CONFIG_FILE"; then
    # Insert '  - local.rules' right below '  - suricata.rules'
    sudo sed -i '/- suricata.rules/a \  - local.rules' "$CONFIG_FILE"
fi
CONFIG_FILE="/etc/suricata/suricata.yaml"
INTERFACE=patatas
echo "Please edit the file $CONFIG_FILE replacing the following lines:"
echo ===================================
echo " af-packet:"
echo "  - interface: eth0 "
echo ===================================
echo "for:"
echo ===================================
echo " af-packet:"
echo "  - interface: $INTERFACE "
echo ===================================

echo then run the following commands to restart Suricata and check its status:

echo sudo systemctl restart suricata
echo sudo systemctl status suricata --no-pager