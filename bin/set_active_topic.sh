#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <topic-slug>" >&2
  exit 1
fi

TOPIC_SLUG="$1"

ACTIVE_PROJECT="$(grep -oP 'project_slug=\K.*' "$ROOT_DIR/ACTIVE_PROJECT.md" 2>/dev/null || true)"

if [[ -z "$ACTIVE_PROJECT" || "$ACTIVE_PROJECT" == "INBOX" ]]; then
  echo "ERROR: no active project set (or active project is INBOX)." >&2
  echo "Set an active project first: bin/set_active_project.sh <project-slug>" >&2
  exit 1
fi

PROJECT_DIR="$ROOT_DIR/PROJECTS/$ACTIVE_PROJECT"
TOPIC_DIR="$PROJECT_DIR/topics/$TOPIC_SLUG"

if [[ ! -d "$TOPIC_DIR" ]]; then
  echo "ERROR: topic '$TOPIC_SLUG' does not exist under PROJECTS/$ACTIVE_PROJECT/topics/" >&2
  echo "Available topics:" >&2
  ls -1 "$PROJECT_DIR/topics/" 2>/dev/null || echo "  (none)" >&2
  exit 1
fi

echo "topic_slug=$TOPIC_SLUG" > "$PROJECT_DIR/ACTIVE_TOPIC.md"
echo "Active topic set to '$TOPIC_SLUG' (project: $ACTIVE_PROJECT)"
