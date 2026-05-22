#!/usr/bin/env bash
set -euo pipefail

echo "[payram-build] Running DigitalOcean-required cleanup..."

# --- Stop & remove the Payram container that ran during the build (if any).
#     The image stays cached so user droplets boot fast; only runtime state goes.
if command -v docker >/dev/null 2>&1; then
  systemctl stop payram.service 2>/dev/null || true
  docker stop payram-mainnet 2>/dev/null || true
  docker rm payram-mainnet 2>/dev/null || true
fi

# --- Wipe build-time Payram state so user droplets generate fresh secrets.
rm -rf /root/payram/payram.env
rm -rf /root/payram/db/postgres/*
rm -rf /root/payram/log/supervisord/*
# Recreate empty data dirs (first-boot script also does this, belt-and-suspenders).
mkdir -p /root/payram /root/payram/db/postgres /root/payram/log/supervisord
chmod 700 /root/payram

# --- Remove DO droplet-agent (validator FAIL fix).
apt-get purge -y droplet-agent || true
rm -rf /etc/digitalocean

# --- Standard DO cleanup.
apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean

rm -rf /tmp/* /var/tmp/*

# --- Truncate every log under /var/log AFTER the steps that write to it.
find /var/log -type f -exec truncate -s 0 {} \; || true
rm -f /var/log/payram-first-boot.log

# --- SSH host keys + root keys must be absent at snapshot time.
rm -f /root/.ssh/authorized_keys
rm -rf /root/.ssh
rm -f /etc/ssh/ssh_host_*

passwd -d root || true
passwd -l root || true

unset HISTFILE
rm -f /root/.bash_history
history -c || true

# --- Reset cloud-init INSTANCE STATE only — surgical, matches DO's reference
#     cleanup. Do NOT use `cloud-init clean`: it wipes /var/lib/cloud/scripts/
#     contents (including our per-instance first-boot script), causing the
#     snapshot to ship without our first-boot script.
rm -rf /var/lib/cloud/instances/*
rm -rf /var/lib/cloud/sem/*
rm -f /var/log/cloud-init.log /var/log/cloud-init-output.log

echo "[payram-build] Cleanup complete."
