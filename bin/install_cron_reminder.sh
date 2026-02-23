#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${CURSOR_MEMORY_CONFIG:-"$ROOT_DIR/config.yaml"}"

CRON_TIME="17:30"
if [[ -f "$CONFIG_FILE" ]]; then
  PARSED="$(grep -E "^\s*cron_time:" "$CONFIG_FILE" | head -1 | sed 's/^[^:]*:\s*//;s/^"//;s/"$//' | xargs)"
  [[ -n "$PARSED" ]] && CRON_TIME="$PARSED"
fi

CRON_MINUTE="${CRON_TIME##*:}"
CRON_HOUR="${CRON_TIME%%:*}"

MARKER="# cursor-memory-reminder"
CRON_CMD="$CRON_MINUTE $CRON_HOUR * * * $ROOT_DIR/bin/remind_to_summarize.sh $MARKER"

CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"

if echo "$CURRENT_CRONTAB" | grep -qF "$MARKER"; then
  echo "Cron reminder already installed. Updating schedule to $CRON_TIME."
  CURRENT_CRONTAB="$(echo "$CURRENT_CRONTAB" | grep -vF "$MARKER")"
fi

echo "$CURRENT_CRONTAB
$CRON_CMD" | crontab -

echo "Cron reminder installed: daily at $CRON_TIME"
echo "Verify with: crontab -l"
