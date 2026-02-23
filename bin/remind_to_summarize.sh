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

REMINDERS_LOG="$(parse_yaml_value reminders_log_file)"
[[ "$REMINDERS_LOG" == ./* ]] && REMINDERS_LOG="$ROOT_DIR/${REMINDERS_LOG#./}"

TODAY="$(date '+%Y-%m-%d')"
REMINDED=0

for PROJECT_DIR in "$ROOT_DIR"/PROJECTS/*/; do
  [[ ! -d "$PROJECT_DIR" ]] && continue

  PROJECT_SLUG="$(basename "$PROJECT_DIR")"
  [[ "$PROJECT_SLUG" == "_index.md" ]] && continue

  ACTIVE_TOPIC_FILE="$PROJECT_DIR/ACTIVE_TOPIC.md"
  [[ ! -f "$ACTIVE_TOPIC_FILE" ]] && continue

  ACTIVE_TOPIC="$(grep -oP 'topic_slug=\K.*' "$ACTIVE_TOPIC_FILE" 2>/dev/null || true)"
  [[ -z "$ACTIVE_TOPIC" || "$ACTIVE_TOPIC" == "INBOX" ]] && continue

  TOPIC_DIR="$PROJECT_DIR/topics/$ACTIVE_TOPIC"
  [[ ! -d "$TOPIC_DIR" ]] && continue

  SUMMARIZED=false

  if ls "$TOPIC_DIR/conversations/${TODAY}-"*.md &>/dev/null; then
    SUMMARIZED=true
  fi

  if [[ -f "$TOPIC_DIR/overview.md" ]]; then
    OVERVIEW_MTIME="$(date -r "$TOPIC_DIR/overview.md" '+%Y-%m-%d')"
    if [[ "$OVERVIEW_MTIME" == "$TODAY" ]]; then
      SUMMARIZED=true
    fi
  fi

  if [[ "$SUMMARIZED" == "false" ]]; then
    MSG="Reminder: no topic summary saved today for project '$PROJECT_SLUG', topic '$ACTIVE_TOPIC'. In Cursor run: Summarize and update topic memory."

    if command -v notify-send &>/dev/null; then
      notify-send "cursor-memory" "$MSG" 2>/dev/null || true
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" >> "$REMINDERS_LOG"
    REMINDED=$((REMINDED + 1))
  fi
done

if [[ $REMINDED -eq 0 ]]; then
  echo "All projects are up to date."
fi
