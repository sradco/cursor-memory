#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${CURSOR_MEMORY_CONFIG:-"$ROOT_DIR/config.yaml"}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: config file not found: $CONFIG_FILE" >&2
  echo "Run: cp config.example.yaml config.yaml  (then edit with your settings)" >&2
  exit 1
fi

parse_yaml_value() {
  local key="$1"
  grep -E "^\s*${key}:" "$CONFIG_FILE" | head -1 | sed 's/^[^:]*:\s*//;s/^"//;s/"$//' | xargs
}

RCLONE_REMOTE="$(parse_yaml_value rclone_remote)"

if ! command -v rclone &>/dev/null; then
  echo "ERROR: rclone is not installed" >&2
  exit 1
fi

REMOTE_BASE="${RCLONE_REMOTE%%:*}:"
echo "Checking remote: $REMOTE_BASE"
if ! rclone about "$REMOTE_BASE" &>/dev/null; then
  echo "ERROR: remote $REMOTE_BASE is not reachable — run: rclone config reconnect ${REMOTE_BASE}" >&2
  exit 1
fi

echo "Restoring from $RCLONE_REMOTE -> $ROOT_DIR"
rclone sync "$RCLONE_REMOTE" "$ROOT_DIR" \
  --timeout 120s \
  --retries 3 \
  --log-level NOTICE

echo ""
echo "=== Restore complete ==="
echo ""
echo "Next steps:"
echo "  1. Set your active project:"
echo "     bin/set_active_project.sh <project-slug>"
echo ""
echo "  2. Set your active topic:"
echo "     bin/set_active_topic.sh <topic-slug>"
echo ""
echo "  3. Load topic memory in Cursor:"
echo "     Open the topic overview.md and related files."
echo ""
