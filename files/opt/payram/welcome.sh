#!/usr/bin/env bash
cat <<'EOF'

Welcome to Payram on DigitalOcean!

Quick commands:
  payram-status              - check service health
  payram-logs                - tail Payram container logs
  payram-use-external-db     - switch to an external Postgres (DO Managed DB, etc.)
  systemctl restart payram   - restart Payram

Note: Postgres (port 5432) is published on all interfaces and is reachable
from the public internet. Restrict access via a DigitalOcean Cloud Firewall
if you don't need it exposed externally.

Config file (edit then `systemctl restart payram`):
  /root/payram/payram.env

Docs: https://docs.payram.com
Support: https://payram.com/support

EOF

# Self-remove from .bashrc so this only runs once.
sed -i '/\/opt\/payram\/welcome.sh/d' /root/.bashrc 2>/dev/null || true
