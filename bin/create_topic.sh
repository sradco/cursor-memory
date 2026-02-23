#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <project-slug> <topic-slug>" >&2
  echo "  Slugs must be lowercase, hyphen-separated (e.g. alert-routing)" >&2
  exit 1
fi

PROJECT_SLUG="$1"
TOPIC_SLUG="$2"

if [[ ! "$TOPIC_SLUG" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: topic slug must be lowercase, hyphen-separated, start with a letter" >&2
  exit 1
fi

PROJECT_DIR="$ROOT_DIR/PROJECTS/$PROJECT_SLUG"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: project '$PROJECT_SLUG' does not exist. Create it first:" >&2
  echo "  bin/create_project.sh $PROJECT_SLUG" >&2
  exit 1
fi

TOPIC_DIR="$PROJECT_DIR/topics/$TOPIC_SLUG"

mkdir -p "$TOPIC_DIR/conversations"

if [[ ! -f "$TOPIC_DIR/overview.md" ]]; then
  cat > "$TOPIC_DIR/overview.md" <<EOF
# Topic: $TOPIC_SLUG
**Project:** $PROJECT_SLUG

## Scope

_What this topic covers._

## Current Status

- **Phase:** exploration | implementation | review | done
- **Last updated:** $(date '+%Y-%m-%d')

## Where We Left Off

_Describe the last meaningful state of work._
EOF
fi

if [[ ! -f "$TOPIC_DIR/decisions.md" ]]; then
  cat > "$TOPIC_DIR/decisions.md" <<EOF
# Decisions: $TOPIC_SLUG

## Template

### Decision: <title>
- **Date:** YYYY-MM-DD
- **Status:** proposed | accepted | rejected | superseded
- **Context:** Why this decision was needed.
- **Decision:** What was decided.
- **Alternatives considered:** What else was evaluated.
- **Consequences:** Trade-offs and follow-up actions.

---

_No decisions recorded yet._
EOF
fi

if [[ ! -f "$TOPIC_DIR/open-questions.md" ]]; then
  cat > "$TOPIC_DIR/open-questions.md" <<EOF
# Open Questions: $TOPIC_SLUG

- [ ] _Add your first question here._
EOF
fi

if [[ ! -f "$TOPIC_DIR/design-evolution.md" ]]; then
  cat > "$TOPIC_DIR/design-evolution.md" <<EOF
# Design Evolution: $TOPIC_SLUG

## Timeline

### $(date '+%Y-%m-%d') — Topic created
- Initial scope defined.
- _Add design evolution entries as the topic progresses._
EOF
fi

echo "topic_slug=$TOPIC_SLUG" > "$PROJECT_DIR/ACTIVE_TOPIC.md"

echo "Topic '$TOPIC_SLUG' created at PROJECTS/$PROJECT_SLUG/topics/$TOPIC_SLUG/"
echo "Active topic set to '$TOPIC_SLUG'"
