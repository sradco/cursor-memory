#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <project-slug> <old-topic-slug> <new-topic-slug>" >&2
  echo "  Renames a topic directory and updates internal references." >&2
  exit 1
fi

PROJECT_SLUG="$1"
OLD_SLUG="$2"
NEW_SLUG="$3"

if [[ ! "$NEW_SLUG" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: new topic slug must be lowercase, hyphen-separated, start with a letter" >&2
  exit 1
fi

PROJECT_DIR="$ROOT_DIR/PROJECTS/$PROJECT_SLUG"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project '$PROJECT_SLUG' does not exist" >&2
  exit 1
fi

OLD_DIR="$PROJECT_DIR/topics/$OLD_SLUG"
NEW_DIR="$PROJECT_DIR/topics/$NEW_SLUG"

if [[ ! -d "$OLD_DIR" ]]; then
  echo "ERROR: topic '$OLD_SLUG' does not exist in project '$PROJECT_SLUG'" >&2
  exit 1
fi

if [[ -d "$NEW_DIR" ]]; then
  echo "ERROR: topic '$NEW_SLUG' already exists in project '$PROJECT_SLUG'" >&2
  exit 1
fi

mv "$OLD_DIR" "$NEW_DIR"
echo "Renamed: topics/$OLD_SLUG/ -> topics/$NEW_SLUG/"

# Update ACTIVE_TOPIC.md if it pointed to the old slug
ACTIVE_FILE="$PROJECT_DIR/ACTIVE_TOPIC.md"
if [[ -f "$ACTIVE_FILE" ]]; then
  CURRENT_ACTIVE="$(grep -oP '(?<=topic_slug=).*' "$ACTIVE_FILE" | tr -d '[:space:]')"
  if [[ "$CURRENT_ACTIVE" == "$OLD_SLUG" ]]; then
    echo "topic_slug=$NEW_SLUG" > "$ACTIVE_FILE"
    echo "Updated ACTIVE_TOPIC.md: $OLD_SLUG -> $NEW_SLUG"
  fi
fi

# Update references inside the topic markdown files (header lines, **Project:** lines)
for f in "$NEW_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  if grep -q "$OLD_SLUG" "$f" 2>/dev/null; then
    sed -i "s|# Topic: $OLD_SLUG|# Topic: $NEW_SLUG|g" "$f"
    sed -i "s|# Decisions: $OLD_SLUG|# Decisions: $NEW_SLUG|g" "$f"
    sed -i "s|# Open Questions: $OLD_SLUG|# Open Questions: $NEW_SLUG|g" "$f"
    sed -i "s|# Design Evolution: $OLD_SLUG|# Design Evolution: $NEW_SLUG|g" "$f"
    echo "Updated references in $(basename "$f")"
  fi
done

echo "Done. Topic '$OLD_SLUG' renamed to '$NEW_SLUG'."
