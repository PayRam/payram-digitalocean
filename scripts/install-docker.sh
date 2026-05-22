#!/usr/bin/env bash
set -euo pipefail

# Wait for cloud-init / unattended-upgrades to release the dpkg lock before
# touching apt — Ubuntu 24.04 base images run background package updates on
# first boot, and racing them causes "Could not get lock" errors.
wait_for_apt() {
  echo "[payram-build] Waiting for apt locks to be released..."
  for _ in $(seq 1 120); do
    if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock >/dev/null 2>&1; then
      echo "[payram-build] Apt locks free."
      return 0
    fi
    sleep 5
  done
  echo "[payram-build] Timed out waiting for apt locks." >&2
  return 1
}

wait_for_apt
# Stop unattended-upgrades from kicking in mid-script.
systemctl stop unattended-upgrades.service 2>/dev/null || true
systemctl disable unattended-upgrades.service 2>/dev/null || true
wait_for_apt

echo "[payram-build] Updating apt and installing base packages..."
apt-get update -y
apt-get upgrade -y
# shellcheck disable=SC2086
apt-get install -y ${APT_PACKAGES}

echo "[payram-build] Installing Docker Engine from official repo..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "[payram-build] Docker installed: $(docker --version)"
