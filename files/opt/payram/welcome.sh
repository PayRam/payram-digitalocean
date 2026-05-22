#!/usr/bin/env bash
cat <<'EOF'

Welcome to Payram on DigitalOcean!

Quick commands:
  payram-status              - check service health
  payram-logs                - tail Payram container logs
  payram-use-external-db     - switch to an external Postgres (DO Managed DB, etc.)
  systemctl restart payram   - restart Payram

Config file (edit then `systemctl restart payram`):
  /root/payram/payram.env

Docs: https://docs.payram.com
Support: https://payram.com/support

EOF

# Self-remove from .bashrc so this only runs once.
sed -i '/\/opt\/payram\/welcome.sh/d' /root/.bashrc 2>/dev/null || true
