#!/usr/bin/env bash
set -euo pipefail

echo "[payram-build] Fetching DigitalOcean 99-img-check.sh validator..."
curl -fsSL https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/99-img-check.sh -o /tmp/99-img-check.sh
chmod +x /tmp/99-img-check.sh

echo "[payram-build] Running 99-img-check.sh (warnings OK, failures must be fixed before submission)..."
/tmp/99-img-check.sh || echo "[payram-build] img_check reported issues — review output above."

rm -f /tmp/99-img-check.sh
echo "[payram-build] Done."
