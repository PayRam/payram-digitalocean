#!/usr/bin/env bash
set -euo pipefail

LOG=/var/log/payram-first-boot.log
exec > >(tee -a "$LOG") 2>&1

echo "=== Payram first-boot $(date -u +%FT%TZ) ==="

ENV_FILE=/root/payram/payram.env
WORKDIR=/root/payram
DBAAS_CREDS=/root/.digitalocean_dbaas_credentials

mkdir -p "$WORKDIR" "$WORKDIR/log/supervisord" "$WORKDIR/db/postgres"

# ---------------------------------------------------------------------------
# Detect whether DO provisioned a Managed Postgres alongside this Droplet.
# If yes, /root/.digitalocean_dbaas_credentials exists with db_* keys.
# Otherwise, fall back to embedded Postgres.
# ---------------------------------------------------------------------------
USE_MANAGED_DB=0
if [ -f "$DBAAS_CREDS" ]; then
  echo "Detected DO Managed Database credentials at $DBAAS_CREDS"
  # shellcheck disable=SC1090
  source "$DBAAS_CREDS"
  if [ -n "${db_host:-}" ] && [ -n "${db_password:-}" ]; then
    USE_MANAGED_DB=1
  else
    echo "WARNING: $DBAAS_CREDS exists but is incomplete — falling back to embedded Postgres."
  fi
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Generating AES_KEY..."
  AES_KEY="$(openssl rand -hex 32)"

  if [ "$USE_MANAGED_DB" -eq 1 ]; then
    echo "Configuring Payram to use DO Managed Postgres at ${db_host}:${db_port}"
    cat > "$ENV_FILE" <<EOF
# Payram environment — generated on first boot.
# Postgres values came from DigitalOcean Managed Database (auto-provisioned).
# Constants (network=mainnet, server=PRODUCTION, payments URL) are hardcoded
# in /etc/systemd/system/payram.service.
AES_KEY=${AES_KEY}
POSTGRES_HOST=${db_host}
POSTGRES_PORT=${db_port}
POSTGRES_DATABASE=${db_database}
POSTGRES_USERNAME=${db_username}
POSTGRES_PASSWORD=${db_password}
POSTGRES_SSLMODE=require
EOF
  else
    echo "No Managed DB found — generating embedded Postgres password..."
    POSTGRES_PASSWORD="$(openssl rand -hex 16)"
    cat > "$ENV_FILE" <<EOF
# Payram environment — generated on first boot.
# Using embedded Postgres (no Managed DB selected at Droplet creation).
# To switch to an external DB later, run: payram-use-external-db --help
AES_KEY=${AES_KEY}
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=payram
POSTGRES_USERNAME=payram
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_SSLMODE=prefer
EOF
  fi
  chmod 600 "$ENV_FILE"
  echo "Wrote $ENV_FILE"
else
  echo "Existing $ENV_FILE found — keeping current configuration."
fi

echo "Pulling latest Payram image..."
docker pull payramapp/payram:latest

echo "Starting payram.service..."
systemctl restart payram.service

echo "=== First-boot complete ==="
