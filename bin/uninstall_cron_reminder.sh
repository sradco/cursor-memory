#!/usr/bin/env bash
set -euo pipefail

MARKER="# cursor-memory-reminder"

CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"

if ! echo "$CURRENT_CRONTAB" | grep -qF "$MARKER"; then
  echo "No cursor-memory cron reminder found. Nothing to remove."
  exit 0
fi

echo "$CURRENT_CRONTAB" | grep -vF "$MARKER" | crontab -

echo "Cron reminder removed."
echo "Verify with: crontab -l"
