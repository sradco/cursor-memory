# cursor-memory

Durable, topic-isolated memory system for Cursor IDE projects. Structured Markdown files backed up automatically to Google Drive — no database, no MCP, no embeddings.

## What This Is

Cursor conversations are ephemeral. This system preserves context across sessions by organizing summaries into **projects** and **topics**, each with standardized files for decisions, open questions, and design evolution.

## Quick Start

```bash
cd cursor-memory

# First-time setup: create your personal config
cp config.example.yaml config.yaml
# Edit config.yaml with your rclone remote name and preferences

# Create a project
bin/create_project.sh my-project

# Create a topic within the project
bin/create_topic.sh my-project alert-routing

# Set active project and topic
bin/set_active_project.sh my-project
bin/set_active_topic.sh alert-routing

# Check everything is healthy
bin/healthcheck.sh
```

In Cursor, load context with:
> "Read @overview.md and @decisions.md for the alert-routing topic. Continue where we left off."

At the end of each session:
> "Summarize and update topic memory."

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

## Fedora-Specific Notes

- **systemd user timers** run while you're logged in. For laptop use this is fine. If you need timers to run when logged out: `loginctl enable-linger $USER`.
- **cronie** is the cron daemon on Fedora. Install with `sudo dnf install cronie` if not present.
- **notify-send** requires `libnotify` (`sudo dnf install libnotify`). The reminder works without it — it always logs to the file.
