#!/bin/bash

# ========================================================
# Install SSH Login Notification Script with Gotify Integration
# ========================================================
#
# Description:
# This script installs the SSH login/logout notification script with Gotify integration.
#
# ========================================================

# Function to prompt user for input with validation
prompt_user_input() {
    local prompt="$1"
    local default_value="$2"
    local input
    read -p "$prompt [$default_value]: " input
    echo "${input:-$default_value}"
}

# Function to install the script for Docker-based Gotify server
install_docker_script() {
    echo -e "\033[1;34mYou chose Docker. Please choose your Gotify container from the following list:\033[0m"

    # List running Docker containers and allow the user to select one
    containers=$(docker ps --format "{{.Names}}")
    select container in $containers; do
        if [ -n "$container" ]; then
            echo -e "\033[1;32mYou selected container: $container\033[0m"
            GOTIFY_CONTAINER_ID=$container
            break
        else
            echo -e "\033[1;31mInvalid selection, please choose a valid container.\033[0m"
        fi
    done
}

# Function to install the script for non-Docker Gotify server
install_non_docker_script() {
    GOTIFY_URL=$(prompt_user_input "Enter the Gotify server URL" "http://gotify.example.com")
}

# Ask the user if they want to use Docker for Gotify
USE_DOCKER=$(prompt_user_input "Do you want to use Docker for Gotify?" "Y")

# Install Gotify configuration based on user's choice
if [[ "$USE_DOCKER" =~ ^[Yy]$ ]]; then
    install_docker_script
else
    install_non_docker_script
fi

# Ask the user for the Gotify token
GOTIFY_TOKEN=$(prompt_user_input "Enter your Gotify app token" "")

# Ask the user if they want logout notifications
NOTIFY_LOGOUT=$(prompt_user_input "Do you want logout notifications?" "N")

# Script template with user inputs
SCRIPT_CONTENT=$(cat <<EOF
#!/bin/bash

exec &> /dev/null

# Configuration
EOF
)

# Append Docker or non-Docker-specific configuration
if [[ "$USE_DOCKER" =~ ^[Yy]$ ]]; then
    SCRIPT_CONTENT+=$(cat <<EOF
# Docker-based Gotify setup
GOTIFY_CONTAINER_ID="$GOTIFY_CONTAINER_ID"  # Gotify container ID
EOF
)
else
    SCRIPT_CONTENT+=$(cat <<EOF
# Non-Docker-based Gotify setup
GOTIFY_URL="$GOTIFY_URL"  # Gotify server URL
EOF
)
fi

# Append Gotify token and logout notification setting
SCRIPT_CONTENT+=$(cat <<EOF
GOTIFY_TOKEN="$GOTIFY_TOKEN"           # Gotify app token
NOTIFY_LOGOUT="$NOTIFY_LOGOUT"         # Set to "true" to enable logout notifications

# Function to send SSH login/logout notification
send_notification() {
    local user=\$PAM_USER
    local hostname=\$(hostname)
    local ip=\${PAM_RHOST:-"unknown"}

    # Determine the event (login or logout)
    local event
    local emoji
    if [[ "\$PAM_TYPE" == "open_session" ]]; then
        event="logged in"
        emoji="🟢"
    elif [[ "\$PAM_TYPE" == "close_session" ]]; then
        if [[ "\$NOTIFY_LOGOUT" != "true" ]]; then
            exit 0  # Skip logout notification if NOTIFY_LOGOUT is not enabled
        fi
        event="logged out"
        emoji="🔴"
    else
        exit 0  # Ignore other events
    fi

    # Create the notification message with emoji at the beginning
    local message="\$emoji \$user \$event to \$hostname from \$ip"

    # Create the title with hostname
    local title="⚠️ SSH Login Alert on \$hostname"

    # Send the notification to Gotify
EOF
)

# If Docker is used, use Docker's IP address
if [[ "$USE_DOCKER" =~ ^[Yy]$ ]]; then
    SCRIPT_CONTENT+=$(cat <<EOF
    local gotify_ip=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "\$GOTIFY_CONTAINER_ID")
    gotify_ip=\${gotify_ip:-"127.0.0.1"}  # Fallback to localhost if IP is not found

    local gotify_url="http://\$gotify_ip"
EOF
)
else
    SCRIPT_CONTENT+=$(cat <<EOF
    local gotify_url="$GOTIFY_URL"
EOF
)
fi

# Final curl command to send the notification
SCRIPT_CONTENT+=$(cat <<EOF
    curl -X POST -s \\
         -F "title=\${title}" \\
         -F "message=\${message}" \\
         -F "priority=5" \\
         "\${gotify_url}/message?token=\${GOTIFY_TOKEN}"
}

# Run the function in the background
send_notification &
EOF
)

# Save the script to a file
SCRIPT_PATH="/path/to/script.sh"
echo "$SCRIPT_CONTENT" > "$SCRIPT_PATH"

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Provide instructions for PAM configuration
echo -e "\033[1;32m======================================="
echo -e "Installation complete. Please follow these steps:\033[0m"
echo -e "\033[1;34m1. Ensure the script is executable: chmod +x $SCRIPT_PATH\033[0m"
echo -e "\033[1;34m2. Add the following line to /etc/pam.d/sshd:\033[0m"
echo -e "\033[1;34m   session optional pam_exec.so /path/to/script.sh\033[0m"
echo -e "\033[1;34m3. Restart the SSH service: systemctl restart sshd\033[0m"
echo -e "\033[1;32m======================================="

# Send a confirmation notification to Gotify
NOTIFY_MESSAGE="Installation completed successfully on the server $(hostname)"
NOTIFY_TITLE="⚠️ SSH Login Notification Installed"

# Try to send the notification via Gotify
NOTIFY_RESPONSE=$(curl -X POST -s -w "%{http_code}" -o /dev/null \
    -F "title=${NOTIFY_TITLE}" \
    -F "message=${NOTIFY_MESSAGE}" \
    -F "priority=5" \
    "${GOTIFY_URL}/message?token=${GOTIFY_TOKEN}")

# Check if the notification was successfully sent
if [[ "$NOTIFY_RESPONSE" == "200" ]]; then
    echo -e "\033[1;32mNotification sent successfully to Gotify.\033[0m"
else
    echo -e "\033[1;31mFailed to send notification to Gotify. HTTP code: $NOTIFY_RESPONSE\033[0m"
fi
