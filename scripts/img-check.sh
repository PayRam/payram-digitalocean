#!/usr/bin/env bash
set -euo pipefail

echo "[payram-build] Fetching DigitalOcean 99-img-check.sh validator..."
curl -fsSL https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/99-img-check.sh -o /tmp/99-img-check.sh
chmod +x /tmp/99-img-check.sh

echo "[payram-build] Running 99-img-check.sh (warnings OK, FAIL blocks the build)..."
/tmp/99-img-check.sh

rm -f /tmp/99-img-check.sh
echo "[payram-build] Done."
