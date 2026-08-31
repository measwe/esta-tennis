#!/usr/bin/env bash
# Deploy index.html to the VPS by hand. Same steps as the GitHub workflow.
#
#   SSH_USER=you SSH_HOST=srv1738178.hstgr.cloud \
#   TARGET_PATH=/srv/amanda/static ./deploy.sh
set -euo pipefail

cd "$(dirname "$0")"

: "${SSH_USER:?set SSH_USER}"
: "${SSH_HOST:?set SSH_HOST}"
: "${TARGET_PATH:?set TARGET_PATH to the directory the app serves the page from}"
SSH_PORT="${SSH_PORT:-22}"
SITE_URL="${SITE_URL:-https://srv1738178.hstgr.cloud/amanda}"

python3 .github/scripts/check_page.py index.html

stamp="local-$(date -u +%Y%m%dT%H%M%SZ)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp index.html "$tmp/index.html"
printf '\n<!-- build %s -->\n' "$stamp" >> "$tmp/index.html"

echo "Copying to $SSH_USER@$SSH_HOST:${TARGET_PATH%/}/index.html"
rsync -avz --checksum -e "ssh -p $SSH_PORT" \
  "$tmp/index.html" "$SSH_USER@$SSH_HOST:${TARGET_PATH%/}/index.html"

echo "Confirming $SITE_URL is serving $stamp"
for attempt in 1 2 3 4 5; do
  if curl -fsS --max-time 20 "$SITE_URL" | grep -qF "build $stamp"; then
    echo "Live. $SITE_URL is serving $stamp"
    exit 0
  fi
  echo "  not visible yet (attempt $attempt of 5)"
  sleep 5
done

echo "rsync succeeded but $SITE_URL is not serving $stamp." >&2
echo "TARGET_PATH may not be the directory the app reads from, or the app needs a restart." >&2
exit 1
