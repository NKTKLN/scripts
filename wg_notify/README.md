# 🔒 WireGuard Connection Notifier

## 🗒 Description

This script monitors WireGuard peer connections and sends real-time notifications to a Gotify server.  
It helps you track when VPN peers connect or disconnect from your server.

## ⚙️ Installation

### 1. Copy the Script

Copy `wg_notify.sh` to your server and make it executable:

```bash
sudo cp wg_notify.sh /usr/local/bin/wg_notify.sh
sudo chmod +x /usr/local/bin/wg_notify.sh
```

### 2. Configure the Script

Open `wg_notify.sh` and set the following variables:

* `GOTIFY_URL` — your Gotify server URL.
* `GOTIFY_TOKEN` — your Gotify application token.
* `WG_INTERFACES` — one or more WireGuard interfaces to monitor (e.g., `wg0 wg1`).

### 3. Setup Execution Method

You can use either **systemd timer** or **cronjob** to run the script periodically.

#### Option A: Systemd Timer (Recommended)

1. Create a service unit `/etc/systemd/system/wg-notify.service`:

   ```ini
   [Unit]
   Description=WireGuard Connection Notifier

   [Service]
   Type=oneshot
   ExecStart=/usr/local/bin/wg_notify.sh
   ```

2. Create a timer `/etc/systemd/system/wg-notify.timer`:

   ```ini
   [Unit]
   Description=Run WireGuard Notifier periodically

   [Timer]
   OnBootSec=1min
   OnUnitActiveSec=1min

   [Install]
   WantedBy=timers.target
   ```

3. Enable and start the timer:

   ```bash
   sudo systemctl enable --now wg-notify.timer
   ```

#### Option B: Cronjob

1. Edit cron with:

   ```bash
   crontab -e
   ```

2. Add an entry (runs every minute):

   ```
   * * * * * /usr/local/bin/wg_notify.sh
   ```

## 🛠️ Testing

Bring a WireGuard peer up or down.
You should receive notifications in your Gotify app when connections change.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/NKTKLN/scripts/LICENSE.md) file for details.
