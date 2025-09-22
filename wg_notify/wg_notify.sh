#!/bin/bash

# ========================================================
# WireGuard Connection Notification Script with Gotify
# ========================================================
#
# Description:
# This script sends notifications to a Gotify server whenever
# a WireGuard peer connects or disconnects. It periodically
# checks one or multiple interfaces using systemd timer or cron.
#
# Requirements:
# 1. WireGuard installed and properly configured.
# 2. Gotify server accessible via HTTP or HTTPS.
# 3. Systemd timer or cronjob to schedule script execution.
#
# Configuration:
# 1. Set the Gotify server URL and application token in the script.
# 2. Ensure the script is executable:
#    chmod +x /usr/local/bin/wg-notify.sh
# 3. Configure a systemd service/timer or cronjob to run the script.
#
# Variables to Configure:
# - GOTIFY_URL: The URL of your Gotify server.
# - GOTIFY_TOKEN: The token for your Gotify application.
# - WG_INTERFACES: One or more WireGuard interfaces to monitor.
#
# ========================================================

exec &> /dev/null

# Configuration
GOTIFY_URL="http://gotify.example.com"   # Your Gotify server
GOTIFY_TOKEN="your-token-here"           # Your Gotify app token
WG_INTERFACES=()                         # Leave empty () to check ALL interfaces
STATE_DIR="/var/run/wg-notify"           # Directory to store state files

mkdir -p "$STATE_DIR"

# Function to send notifications
send_notification() {
    local peer_name="$1"
    local event="$2"
    local emoji="$3"
    local iface="$4"
    local hostname
    hostname=$(hostname)

    local message="$emoji $peer_name $event on $hostname ($iface)"
    local title="⚠️ WireGuard Alert"

    curl -s -X POST \
        -F "title=${title}" \
        -F "message=${message}" \
        -F "priority=5" \
        "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}" >/dev/null
}

# Get list of interfaces
if [ ${#WG_INTERFACES[@]} -eq 0 ]; then
    INTERFACES=$(wg show interfaces)
else
    INTERFACES="${WG_INTERFACES[*]}"
fi

# Iterate over each interface
for IFACE in $INTERFACES; do
    STATE_FILE="$STATE_DIR/${IFACE}.state"
    CURRENT=$(mktemp)

    wg show "$IFACE" latest-handshakes | awk '{print $1,$2}' > "$CURRENT"

    if [ -f "$STATE_FILE" ]; then
        while read -r peer ts; do
            prev_ts=$(grep "^$peer " "$STATE_FILE" | awk '{print $2}')
            # Try to extract AllowedIPs (acts as "peer name")
            peer_name=$(wg show "$IFACE" allowed-ips | grep "^$peer" | awk '{print $2}')
            [ -z "$peer_name" ] && peer_name="$peer"

            if [ "$ts" -gt 0 ]; then
                if [ -z "$prev_ts" ] || [ "$ts" -gt "$prev_ts" ]; then
                    send_notification "$peer_name" "connected" "🟢" "$IFACE"
                fi
            fi
        done < "$CURRENT"
    fi

    mv "$CURRENT" "$STATE_FILE"
done
