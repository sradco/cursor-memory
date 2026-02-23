#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${CURSOR_MEMORY_CONFIG:-"$ROOT_DIR/config.yaml"}"

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "  [OK]   $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label — $result"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== cursor-memory healthcheck ==="
echo ""

# Root structure
for dir in GLOBAL PROJECTS INBOX bin docs; do
  if [[ -d "$ROOT_DIR/$dir" ]]; then
    check "$dir/ exists" "ok"
  else
    check "$dir/ exists" "directory missing"
  fi
done

# config.yaml
if [[ -f "$CONFIG_FILE" ]]; then
  check "config.yaml exists" "ok"
else
  check "config.yaml exists" "file missing — run: cp config.example.yaml config.yaml"
fi

# rclone
if command -v rclone &>/dev/null; then
  check "rclone installed" "ok"
else
  check "rclone installed" "not found in PATH — install with: sudo dnf install rclone"
fi

# Remote reachable
if [[ -f "$CONFIG_FILE" ]]; then
  parse_yaml_value() {
    local key="$1"
    grep -E "^\s*${key}:" "$CONFIG_FILE" | head -1 | sed 's/^[^:]*:\s*//;s/^"//;s/"$//' | xargs
  }
  RCLONE_REMOTE="$(parse_yaml_value rclone_remote)"
  if command -v rclone &>/dev/null; then
    REMOTE_BASE="${RCLONE_REMOTE%%:*}:"
    if rclone about "$REMOTE_BASE" &>/dev/null; then
      check "remote reachable ($REMOTE_BASE)" "ok"
    else
      check "remote reachable ($REMOTE_BASE)" "rclone cannot reach remote — run: rclone config"
    fi
  else
    check "remote reachable" "skipped (rclone not installed)"
  fi
fi

# ACTIVE_PROJECT.md
if [[ -f "$ROOT_DIR/ACTIVE_PROJECT.md" ]]; then
  check "ACTIVE_PROJECT.md exists" "ok"
  ACTIVE_PROJECT="$(grep -oP 'project_slug=\K.*' "$ROOT_DIR/ACTIVE_PROJECT.md" 2>/dev/null || true)"
  if [[ -n "$ACTIVE_PROJECT" && "$ACTIVE_PROJECT" != "INBOX" ]]; then
    PROJECT_DIR="$ROOT_DIR/PROJECTS/$ACTIVE_PROJECT"
    if [[ -d "$PROJECT_DIR" ]]; then
      check "active project dir ($ACTIVE_PROJECT)" "ok"
      if [[ -f "$PROJECT_DIR/ACTIVE_TOPIC.md" ]]; then
        check "ACTIVE_TOPIC.md for $ACTIVE_PROJECT" "ok"
        ACTIVE_TOPIC="$(grep -oP 'topic_slug=\K.*' "$PROJECT_DIR/ACTIVE_TOPIC.md" 2>/dev/null || true)"
        if [[ -n "$ACTIVE_TOPIC" && "$ACTIVE_TOPIC" != "INBOX" ]]; then
          if [[ -d "$PROJECT_DIR/topics/$ACTIVE_TOPIC" ]]; then
            check "active topic dir ($ACTIVE_TOPIC)" "ok"
          else
            check "active topic dir ($ACTIVE_TOPIC)" "directory missing"
          fi
        fi
      else
        check "ACTIVE_TOPIC.md for $ACTIVE_PROJECT" "file missing"
      fi
    else
      check "active project dir ($ACTIVE_PROJECT)" "directory missing"
    fi
  fi
else
  check "ACTIVE_PROJECT.md exists" "file missing"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
