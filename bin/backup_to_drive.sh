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
LOG_FILE="$(parse_yaml_value log_file)"

# Resolve relative paths against ROOT_DIR
[[ "$LOG_FILE" == ./* ]] && LOG_FILE="$ROOT_DIR/${LOG_FILE#./}"

if ! command -v rclone &>/dev/null; then
  echo "ERROR: rclone is not installed" >&2
  exit 1
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting backup to $RCLONE_REMOTE"

REMOTE_BASE="${RCLONE_REMOTE%%:*}:"
if ! rclone about "$REMOTE_BASE" &>/dev/null; then
  log "ERROR: remote $REMOTE_BASE is not reachable — run: rclone config reconnect ${REMOTE_BASE}"
  exit 1
fi

MAX_RETRIES=3
RETRY=0
while (( RETRY < MAX_RETRIES )); do
  if rclone sync "$ROOT_DIR" "$RCLONE_REMOTE" \
    --timeout 120s \
    --retries 1 \
    --log-level NOTICE \
    --stats 0 \
    2>>"$LOG_FILE"; then
    log "Backup completed successfully"
    exit 0
  fi
  RETRY=$((RETRY + 1))
  log "WARNING: rclone sync attempt $RETRY/$MAX_RETRIES failed, retrying in 5s..."
  sleep 5
done

log "ERROR: backup failed after $MAX_RETRIES attempts"
exit 1
