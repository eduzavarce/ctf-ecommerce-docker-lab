#!/bin/bash
set -e

CONFIG_FILE="/etc/suricata/suricata.yaml"
CONFIG_TEMPLATE="suricata/suricata.yaml"
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

sudo tee "$CONFIG_FILE" < "$CONFIG_TEMPLATE" > /dev/null

sudo sed -i -E \
    -e "s|HOME_NET_PLACEHOLDER|$HOME_NET_VAL|g" \
    -e "s|INTERFACE_PLACEHOLDER|$INTERFACE|g" \
    "$CONFIG_FILE"

echo "[*] Restarting Suricata service..."
sudo systemctl restart suricata
echo "[*] Suricata status:"
sudo systemctl status suricata --no-pager

sudo suricata -T -c /etc/suricata/suricata.yaml