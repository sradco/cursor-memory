#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-slug>" >&2
  exit 1
fi

PROJECT_SLUG="$1"

if [[ "$PROJECT_SLUG" == "INBOX" ]]; then
  echo "project_slug=INBOX" > "$ROOT_DIR/ACTIVE_PROJECT.md"
  echo "Active project set to INBOX"
  exit 0
fi

if [[ ! -d "$ROOT_DIR/PROJECTS/$PROJECT_SLUG" ]]; then
  echo "ERROR: project '$PROJECT_SLUG' does not exist under PROJECTS/" >&2
  echo "Available projects:" >&2
  ls -1 "$ROOT_DIR/PROJECTS/" 2>/dev/null | grep -v '_index.md' || echo "  (none)" >&2
  exit 1
fi

echo "project_slug=$PROJECT_SLUG" > "$ROOT_DIR/ACTIVE_PROJECT.md"
echo "Active project set to '$PROJECT_SLUG'"
