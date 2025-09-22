# 🖥️ MOTD System Status Script

## 🗒 Description

This script displays a colorful and informative Message of the Day (MOTD) when you log in to your server. It shows system load, CPU and memory usage, disk status, available updates, Docker containers, last SSH login, IP address, active users, and zombie processes.

## ⚙️ Installation

1. Copy `motd.sh` to your server:
    ```bash
    sudo cp motd.sh /etc/profile.d/motd.sh
    sudo chmod +x /etc/profile.d/motd.sh
    ```

2. The script will automatically run for all users on login (via SSH or terminal).

## 🛠️ Features

- **System Load**: Shows 1, 5, and 30 minute averages.
- **CPU Usage**: Color-coded based on usage.
- **Memory Usage**: Color-coded, shows used/total and percent.
- **Disk Usage**: Displays main and mounted disks.
- **Available Updates**: Shows number of upgradable packages (APT-based systems).
- **Docker Status**: Shows running/stopped containers if Docker is installed.
- **Last SSH Login**: Displays last SSH login info.
- **Server IP**: Shows main IP address.
- **Active Users**: Number of logged-in users.
- **Tasks & Zombies**: Shows total and zombie processes.

## 💡 Notes

- Designed for Linux systems (Debian/Ubuntu recommended).
- Requires basic system utilities: `awk`, `free`, `df`, `ps`, `last`, `hostname`, `bc`.
- For update info, works with APT package manager.
- Docker info is shown only if Docker is installed.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/NKTKLN/scripts/LICENSE.md) file for details.
