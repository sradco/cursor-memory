#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-slug>" >&2
  echo "  Slug must be lowercase, hyphen-separated (e.g. my-web-app)" >&2
  exit 1
fi

PROJECT_SLUG="$1"

if [[ ! "$PROJECT_SLUG" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: slug must be lowercase, hyphen-separated, start with a letter" >&2
  exit 1
fi

PROJECT_DIR="$ROOT_DIR/PROJECTS/$PROJECT_SLUG"

mkdir -p "$PROJECT_DIR/topics"

if [[ ! -f "$PROJECT_DIR/00-project-summary.md" ]]; then
  cat > "$PROJECT_DIR/00-project-summary.md" <<EOF
# Project: $PROJECT_SLUG

## Purpose

_Describe the project purpose here._

## Key Links

- Repo: _link_
- Docs: _link_

## Status

- **Phase:** planning | active | maintenance
- **Last updated:** $(date '+%Y-%m-%d')
EOF
fi

if [[ ! -f "$PROJECT_DIR/01-project-architecture.md" ]]; then
  cat > "$PROJECT_DIR/01-project-architecture.md" <<EOF
# Architecture: $PROJECT_SLUG

## Overview

_High-level architecture description._

## Components

| Component | Responsibility |
|-----------|---------------|
| _name_ | _description_ |

## Key Decisions

See topic-level \`decisions.md\` for detailed ADRs.
EOF
fi

if [[ ! -f "$PROJECT_DIR/ACTIVE_TOPIC.md" ]]; then
  echo "topic_slug=INBOX" > "$PROJECT_DIR/ACTIVE_TOPIC.md"
fi

INDEX_FILE="$ROOT_DIR/PROJECTS/_index.md"
if ! grep -qF "| $PROJECT_SLUG |" "$INDEX_FILE" 2>/dev/null; then
  sed -i "/| _none yet_ |/d" "$INDEX_FILE"
  echo "| $PROJECT_SLUG | _to be filled_ | $(date '+%Y-%m-%d') |" >> "$INDEX_FILE"
fi

echo "Project '$PROJECT_SLUG' created at PROJECTS/$PROJECT_SLUG/"
