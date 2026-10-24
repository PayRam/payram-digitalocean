#!/usr/bin/env bash
ENV_FILE=/root/payram/payram.env
POSTGRES_HOST=localhost
# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

cat <<'EOF'

Welcome to Payram on DigitalOcean!

Quick commands:
  payram-status              - check service health
  payram-logs                - tail Payram container logs
  payram-use-external-db     - switch to an external Postgres (DO Managed DB, etc.)
  systemctl restart payram   - restart Payram

EOF

# The embedded Postgres is only reachable inside the container; a Managed
# Database is backed up by DigitalOcean.
if [ "${POSTGRES_HOST}" = "localhost" ] || [ "${POSTGRES_HOST}" = "127.0.0.1" ]; then
  cat <<'EOF'
The embedded Postgres is reachable only from inside the Payram container.
Back it up with:
  docker exec payram-mainnet pg_dump -U payram payram > payram-backup.sql

EOF
else
  cat <<EOF
Payram uses your external Postgres at ${POSTGRES_HOST}. Back it up with your
database provider's backups (DigitalOcean: Databases → your cluster → Backups).

EOF
fi

cat <<'EOF'
Config file (edit then `systemctl restart payram`):
  /root/payram/payram.env

Docs: https://docs.payram.com
Support: https://payram.com/support

EOF

# Self-remove from .bashrc so this only runs once.
sed -i '/\/opt\/payram\/welcome.sh/d' /root/.bashrc 2>/dev/null || true
