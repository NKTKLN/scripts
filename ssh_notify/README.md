# 📡 SSH Connection Notifier

## 🗒 Description

This script monitors SSH connections to your server and sends real-time notifications using Gotify. It's useful for keeping track of who is accessing your system and from where.

## ⚙️ Installation Options

### 1. Standard Installation (Non-Docker Gotify)

1. Copy `ssh_notify.sh` to your server:
    ```bash
    sudo cp ssh_notify.sh /usr/local/bin/ssh_notify.sh
    sudo chmod +x /usr/local/bin/ssh_notify.sh
    ```

2. Edit `/etc/pam.d/sshd` and add:
    ```
    session optional pam_exec.so /usr/local/bin/ssh_notify.sh
    ```

3. Configure in the script:
    - `GOTIFY_URL` — your Gotify server URL.
    - `GOTIFY_TOKEN` — your Gotify app token.
    - `NOTIFY_LOGOUT` — set to `true` to enable logout notifications.

4. Restart SSH:
    ```bash
    sudo systemctl restart sshd
    ```

### 2. Docker-Based Gotify Installation

1. Copy `ssh_notify_docker.sh` to your server:
    ```bash
    sudo cp ssh_notify_docker.sh /usr/local/bin/ssh_notify_docker.sh
    sudo chmod +x /usr/local/bin/ssh_notify_docker.sh
    ```

2. Configure in the script:
    - `GOTIFY_CONTAINER_ID` — your Gotify container name or ID.
    - `GOTIFY_TOKEN` — your Gotify app token.
    - `NOTIFY_LOGOUT` — set to `true` to enable logout notifications.

3. Edit `/etc/pam.d/sshd` and add:
    ```
    session optional pam_exec.so /usr/local/bin/ssh_notify_docker.sh
    ```

4. Restart SSH:
    ```bash
    sudo systemctl restart sshd
    ```

### 3. Automatic Installation via Installer Script

1. Run the installer:
    ```bash
    bash installer.sh
    ```

2. Follow the prompts:
    - Choose Docker or standard Gotify.
    - Enter Gotify URL or select Docker container.
    - Enter your Gotify app token.
    - Choose whether to enable logout notifications.

3. After installation:
    - The installer will show the script path and PAM configuration line.
    - Add the line to `/etc/pam.d/sshd` as instructed.
    - Restart SSH:
        ```bash
        sudo systemctl restart sshd
        ```

## 🛠️ Testing

Connect to your server via SSH. You should receive notifications in your Gotify app.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/NKTKLN/scripts/LICENSE.md) file for details.
