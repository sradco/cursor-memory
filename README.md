# cursor-memory

Durable, topic-isolated memory system for Cursor IDE projects. Structured Markdown files backed up automatically to Google Drive — no database, no MCP, no embeddings.

## What This Is

Cursor conversations are ephemeral. This system preserves context across sessions by organizing summaries into **projects** and **topics**, each with standardized files for decisions, open questions, and design evolution.

## Prerequisites

Install rclone (needed for Google Drive backup):

```bash
sudo dnf install rclone       # Fedora/RHEL
sudo apt install rclone        # Ubuntu/Debian
brew install rclone            # macOS
```

## Quick Start

### 1. One-time setup

```bash
cd cursor-memory
bin/setup.sh
```

The setup wizard will:
- Create `config.yaml` from the example
- Detect existing rclone remotes or guide you through creating one
- Let you pick the backup path on Google Drive
- Optionally install the automatic backup timer and daily reminder
- Install the Cursor rule into your workspace so the AI auto-manages projects/topics
- Run a healthcheck to verify everything works

**Important:** if `cursor-memory/` is a subfolder inside a larger workspace, the setup wizard asks for your workspace root and copies the Cursor rule there. Without this, the AI won't know about cursor-memory when you say "summarize".

### 2. Just use Cursor

Projects and topics are managed automatically by the AI via the included Cursor rule (`.cursor/rules/cursor-memory-auto.mdc`). You don't need to run scripts manually.

- **Start working.** Cursor detects the project and topic from context, creates them if needed, and sets them as active.
- **Topic shifts.** If the conversation moves to a different concern, Cursor creates or switches to the right topic.
- **End of session.** Just say:
  > "Summarize and update topic memory."

  Cursor updates `overview.md`, `decisions.md`, `open-questions.md`, and `design-evolution.md` automatically.

> **Note:** `bin/setup.sh` handles everything — rclone configuration, backup timer, and cron reminder. The sections below are reference for manual setup or customization.

## Backup Setup (Google Drive)

### Prerequisites

1. Install rclone:
   ```bash
   sudo dnf install rclone
   ```

2. Configure a Google Drive remote named `gdrive`:
   ```bash
   rclone config
   ```

3. Verify access:
   ```bash
   rclone lsf gdrive:
   ```

### Install Automatic Backup

```bash
bin/install_systemd_backup_timer.sh
```

This installs a systemd user timer that backs up every 30 minutes (configurable in `config.yaml`).

### Manual Backup

```bash
bin/backup_to_drive.sh
```

### Uninstall Backup Timer

```bash
bin/uninstall_systemd_backup_timer.sh
```

## Reminder Setup

A daily cron job reminds you to summarize if no summary was saved today for the active project+topic.

### Install

```bash
bin/install_cron_reminder.sh
```

Default time: 17:30 (configurable in `config.yaml` under `reminder.cron_time`).

Requires `cronie`:
```bash
sudo dnf install cronie
sudo systemctl enable --now crond
```

### Uninstall

```bash
bin/uninstall_cron_reminder.sh
```

## Log Locations

| Log | Path | Purpose |
|-----|------|---------|
| Backup log | `backup.log` | rclone sync results |
| Reminder log | `memory-reminders.log` | Missed summary reminders |

Both paths are configurable in `config.yaml`.

## Restore (New Machine)

```bash
# 1. Install rclone and configure gdrive remote
sudo dnf install rclone && rclone config

# 2. Create config.yaml (copy from config.example.yaml)
cp config.example.yaml config.yaml

# 3. Restore from Drive
bin/restore_from_drive.sh

# 4. Reinstall automation
bin/install_systemd_backup_timer.sh
bin/install_cron_reminder.sh

# 5. Verify
bin/healthcheck.sh
```

See [docs/RESTORE.md](docs/RESTORE.md) for detailed steps.

## Configuration

Edit `config.yaml` (see `config.example.yaml` for reference):

```yaml
backup:
  rclone_remote: "gdrive:CursorBackups/cursor-memory"
  log_file: "./backup.log"
  reminders_log_file: "./memory-reminders.log"
  backup_interval_minutes: 30
reminder:
  cron_time: "17:30"
```

Scripts read config from `$CURSOR_MEMORY_CONFIG` env var, defaulting to `./config.yaml`.

## Documentation

- [Overview](docs/OVERVIEW.md) — why this system, topic isolation concept
- [Workflow](docs/WORKFLOW.md) — creating projects/topics, end-of-session routine
- [Backup](docs/BACKUP.md) — how backup works, verification, changing interval
- [Restore](docs/RESTORE.md) — new laptop setup steps
- [Troubleshooting](docs/TROUBLESHOOTING.md) — common issues and fixes
- [Naming](docs/NAMING.md) — slug rules and file naming conventions

## Manual Scripts (Optional)

The `bin/` scripts are available if you prefer manual control or need to use them outside Cursor:

```bash
bin/create_project.sh my-project
bin/create_topic.sh my-project alert-routing
bin/set_active_project.sh my-project
bin/set_active_topic.sh alert-routing
bin/rename_topic.sh my-project old-name new-name
bin/healthcheck.sh
```

## Complementary Tools

cursor-memory handles **durable project context** (decisions, status, open questions). It works alongside — not instead of — Cursor's native features:

| Layer | Tool | What it does |
|-------|------|-------------|
| **Behavioral rules** | `.cursor/rules/*.mdc` | Tell the AI *how* to behave (coding standards, workflows) |
| **Reusable procedures** | `.cursor/skills/` | Teach the AI *how to do* specific tasks |
| **Project memory** | `cursor-memory/` | Remember *what happened* across sessions |
| **Chat history** | `@previous chats` | Reference recent conversations (local only, not durable) |

Use all of them together:
- **Rules** for conventions that rarely change.
- **Skills** for repeatable procedures (run tests, deploy, bootstrap context).
- **cursor-memory** for evolving project knowledge that must survive across machines.

## Fedora-Specific Notes

- **systemd user timers** run while you're logged in. For laptop use this is fine. If you need timers to run when logged out: `loginctl enable-linger $USER`.
- **cronie** is the cron daemon on Fedora. Install with `sudo dnf install cronie` if not present.
- **notify-send** requires `libnotify` (`sudo dnf install libnotify`). The reminder works without it — it always logs to the file.
