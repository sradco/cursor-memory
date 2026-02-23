# Naming Conventions

## Slug Rules

All project and topic slugs must be:
- **Lowercase** only
- **Hyphen-separated** (no underscores, no spaces, no camelCase)
- **Start with a letter** (not a number or hyphen)
- **Descriptive but concise** (2-4 words ideal)

### Valid Examples

| Type | Slug | Description |
|------|------|-------------|
| Project | `my-web-app` | Web application project |
| Project | `backend-api` | Backend API service |
| Topic | `alert-routing` | Alert routing logic |
| Topic | `ui-grouping` | UI alert grouping feature |
| Topic | `api-migration-v2` | API migration to v2 |

### Invalid Examples

| Slug | Problem |
|------|---------|
| `AlertRouting` | camelCase |
| `alert_routing` | underscores |
| `Alert Routing` | spaces |
| `3d-charts` | starts with number |
| `-my-topic` | starts with hyphen |

## File Naming

### Conversation Files

Format: `YYYY-MM-DD-<short-description>.md`

Examples:
- `2026-02-23-initial-design.md`
- `2026-02-23-api-review.md`

### Project Files

Standard files created by `create_project.sh`:
- `00-project-summary.md`
- `01-project-architecture.md`
- `ACTIVE_TOPIC.md`

### Topic Files

Standard files created by `create_topic.sh`:
- `overview.md`
- `decisions.md`
- `open-questions.md`
- `design-evolution.md`
- `conversations/` (directory)

## When to Create a New Topic

Create a new topic when:
- The conversation shifts to a **distinct concern** within the same project.
- You start working on a **separate feature, bug, or investigation**.
- The current topic's `overview.md` would become unfocused by including the new work.

**Rule of thumb:** if you'd put it in a separate PR or ticket, it's a separate topic.

Do NOT create a new topic for:
- Minor follow-ups on the same feature.
- Bug fixes directly related to the current topic.
- Refinements to an existing design.
