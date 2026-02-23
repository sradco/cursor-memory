# Overview

## Why File-Based Memory?

Cursor IDE conversations are ephemeral — they don't survive across sessions, projects, or machines. cursor-memory solves this by storing structured summaries as plain Markdown files that are:

- **Durable** — files on disk survive app crashes, updates, and reinstalls.
- **Portable** — backed up to Google Drive, restorable on any machine.
- **Versionable** — can be committed to git if desired.
- **Human-readable** — no proprietary format, no database, no binary blobs.

## Why Not a Database or MCP?

| Approach | Drawback |
|----------|----------|
| SQLite / Postgres | Requires tooling, migrations, harder to browse manually |
| Vector DB / Embeddings | Adds complexity, requires embedding model, overkill for structured notes |
| MCP Server | Adds a running process dependency, not all environments support it |
| Plain Markdown | Zero dependencies, works everywhere, easy to grep/edit/backup |

We optimize for simplicity, durability, and zero infrastructure.

## Topic Isolation

Every piece of context is scoped to exactly one **project** and one **topic**:

```
PROJECTS/
  my-project/
    topics/
      alert-routing/      ← one topic
        overview.md
        decisions.md
        open-questions.md
        design-evolution.md
        conversations/
      ui-grouping/         ← another topic
        ...
```

**Rules:**
1. Decisions live only in `topics/<topic>/decisions.md`.
2. Conversations must not mix topics.
3. If discussion shifts to a different concern, switch or create a new topic.
4. `overview.md` is scoped to one topic only.

This isolation prevents context bleed and makes it easy to load exactly the context you need into Cursor.
