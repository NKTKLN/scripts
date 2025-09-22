#!/bin/bash

# ========================================================
# SSH Login Notification Script with Gotify Integration
# ========================================================
#
# Description:
# This script sends notifications to a Gotify server whenever
# a user logs in or logs out via SSH. It uses PAM (Pluggable
# Authentication Modules) to detect login/logout events.
#
# Requirements:
# 1. Gotify server accessible via HTTP/HTTPS.
# 2. PAM configured to execute this script on SSH events.
#
# Configuration:
# 1. Set the Gotify server URL and token below.
# 2. Set NOTIFY_LOGOUT to "true" if you want logout notifications.
# 3. Ensure this script is executable:
#    chmod +x /path/to/script.sh
# 4. Add the following line to /etc/pam.d/sshd:
#    session optional pam_exec.so /path/to/script.sh
#
# Gotify Setup:
# 1. Deploy Gotify server (e.g., using Docker, bare metal, or cloud).
# 2. Create an application in Gotify to get a token.
#
# Variables to Configure:
# - GOTIFY_URL: The URL of your Gotify server (e.g., http://gotify.example.com).
# - GOTIFY_TOKEN: The token for your Gotify application.
# - NOTIFY_LOGOUT: Set to "true" to enable logout notifications.
#
# ========================================================

exec &> /dev/null

# Configuration
GOTIFY_URL="http://gotify.example.com"  # Replace with your Gotify server URL
GOTIFY_TOKEN="your-token-here"          # Replace with your Gotify app token
NOTIFY_LOGOUT="true"                    # Set to "true" to enable logout notifications

# Function to send SSH login/logout notification
send_notification() {
    local user=$PAM_USER
    local hostname=$(hostname)
    local ip=${PAM_RHOST:-"unknown"}

    # Determine the event (login or logout)
    local event
    local emoji
    if [[ "$PAM_TYPE" == "open_session" ]]; then
        event="logged in"
        emoji="🟢"
    elif [[ "$PAM_TYPE" == "close_session" ]]; then
        if [[ "$NOTIFY_LOGOUT" != "true" ]]; then
            exit 0  # Skip logout notification if NOTIFY_LOGOUT is not enabled
        fi
        event="logged out"
        emoji="🔴"
    else
        exit 0  # Ignore other events
    fi

    if [[ "$PAM_TYPE" == "open_session" ]]; then
        event="logged in"
        emoji="🟢"
    elif [[ "$PAM_TYPE" == "close_session" ]]; then
        if [[ "$NOTIFY_LOGOUT" != "true" ]]; then
            exit 0
        fi
        event="logged out"
        emoji="🔴"
    elif [[ "$PAM_TYPE" == "auth" ]]; then
        event="attempted login"
        emoji="⚪"
    elif [[ "$PAM_TYPE" == "auth_fail" ]]; then
        event="failed login attempt"
        emoji="❌"
    else
        exit 0
    fi


    # Create the notification message with emoji at the beginning
    local message="$emoji $user $event to $hostname from $ip"

    # Create the title with hostname
    local title="⚠️ SSH Login Alert on $hostname"

    # Send the notification to Gotify
    curl -X POST -s \
         -F "title=${title}" \
         -F "message=${message}" \
         -F "priority=5" \
         "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}"
}

# Run the function in the background
send_notification &
