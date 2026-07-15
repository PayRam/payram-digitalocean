#!/usr/bin/env bash
set -euo pipefail

echo "[payram-build] Preparing Payram directories..."
mkdir -p /root/payram
mkdir -p /root/payram/log/supervisord
mkdir -p /root/payram/db/postgres

echo "[payram-build] Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 5432/tcp
ufw --force enable

echo "[payram-build] Enabling systemd service for Payram (will start on first boot)..."
chmod 0644 /etc/systemd/system/payram.service
systemctl daemon-reload
systemctl enable payram.service

echo "[payram-build] Marking helper scripts executable..."
chmod +x /usr/local/bin/payram-use-external-db
chmod +x /usr/local/bin/payram-status
chmod +x /usr/local/bin/payram-logs
chmod +x /usr/local/bin/payram-wait-for-db
chmod +x /opt/payram/welcome.sh
chmod +x /var/lib/cloud/scripts/per-instance/001-payram-first-boot.sh
chmod +x /etc/update-motd.d/99-image-readme

echo "[payram-build] Wiring first-login welcome banner into root .bashrc..."
grep -qxF '/opt/payram/welcome.sh' /root/.bashrc 2>/dev/null || echo '/opt/payram/welcome.sh' >> /root/.bashrc

echo "[payram-build] Pre-pulling Payram Docker image (best-effort — first boot will refresh)..."
docker pull payramapp/payram:latest || echo "[payram-build] Pre-pull failed, first-boot will retry."

echo "[payram-build] Done."
