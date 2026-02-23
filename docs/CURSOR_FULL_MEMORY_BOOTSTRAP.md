# CURSOR_FULL_MEMORY_BOOTSTRAP_FEDORA.md

## Goal
Bootstrap a durable, topic-isolated memory system for many projects, all inside ONE folder: `cursor-memory/`.

Must include:
1) Topic-isolated memory per project, per topic.
2) Google Drive backup via rclone, fully automatic using systemd user timer (no sudo).
3) Restore from Drive.
4) A daily reminder (cron) if no summary was saved today for the active project+topic.
5) Clear docs for workflow, backup, restore, troubleshooting.
6) Everything is Markdown + scripts, no database, no MCP.

## Assumptions
- OS: Fedora Linux
- User has a desktop session most of the time. Notifications are nice-to-have, log file is required.
- Google Drive is trusted for backup durability.
- We do not export Cursor internal chats. Summaries are manual, triggered by the user in Cursor.

## Root Folder
Everything lives under:
cursor-memory/

Backups sync this folder to Google Drive.

## Target Structure (must be created)
cursor-memory/
  README.md
  config.example.yaml
  config.yaml

  GLOBAL/
    00-work-principles.md
    01-cross-project-decisions.md
    02-reusable-patterns.md

  PROJECTS/
    _index.md
    <project-slug>/
      00-project-summary.md
      01-project-architecture.md
      ACTIVE_TOPIC.md
      topics/
        <topic-slug>/
          overview.md
          decisions.md
          open-questions.md
          design-evolution.md
          conversations/

  INBOX/
    00-capture.md

  ACTIVE_PROJECT.md

  bin/
    backup_to_drive.sh
    restore_from_drive.sh
    healthcheck.sh
    create_project.sh
    create_topic.sh
    set_active_project.sh
    set_active_topic.sh
    remind_to_summarize.sh
    install_cron_reminder.sh
    uninstall_cron_reminder.sh
    install_systemd_backup_timer.sh
    uninstall_systemd_backup_timer.sh

  systemd/
    cursor-memory-backup.service
    cursor-memory-backup.timer

  docs/
    OVERVIEW.md
    WORKFLOW.md
    BACKUP.md
    RESTORE.md
    TROUBLESHOOTING.md
    NAMING.md

## Naming Rules (strict)
Project slug and topic slug:
- lowercase
- hyphen-separated
Examples:
- my-web-app
- backend-api
- alert-routing
- ui-grouping

## Active project and topic (strict)
cursor-memory/ACTIVE_PROJECT.md contains exactly:
project_slug=<slug>

cursor-memory/PROJECTS/<project>/ACTIVE_TOPIC.md contains exactly:
topic_slug=<slug>

## Isolation Rules (critical)
1) Decisions must be written only inside:
   PROJECTS/<project>/topics/<topic>/decisions.md
2) Conversations must not mix topics.
3) If the discussion moves to a different topic, switch active topic or create a new one.
4) overview.md is scoped to one topic only.

## Definition: "summarized today"
For the active project+topic, summarized today if either:
A) A conversation file exists:
   conversations/YYYY-MM-DD-*.md
OR
B) overview.md mtime is today.

## Config
Create config.example.yaml and config.yaml.

config.example.yaml must include:

backup:
  rclone_remote: "gdrive:CursorBackups/cursor-memory"
  log_file: "./backup.log"
  reminders_log_file: "./memory-reminders.log"
  backup_interval_minutes: 30
reminder:
  cron_time: "17:30"

Notes:
- config.yaml is user-editable.
- Scripts must read config.yaml from CURSOR_MEMORY_CONFIG env var, default ./config.yaml.
- Paths in config can be relative to cursor-memory/ root.

## Implementations required (Cursor must generate all files)

### 1) Core Markdown files (initial content)
Create minimal useful content in:
- README.md
- GLOBAL/*.md
- INBOX/00-capture.md
- ACTIVE_PROJECT.md default: project_slug=INBOX
- PROJECTS/_index.md with instructions

### 2) Project and topic templates
When creating a project/topic, create the files with starter sections.

Topic file starter content must include:
- overview.md: scope, status, where we left off
- decisions.md: decision template blocks
- open-questions.md: list format
- design-evolution.md: timeline starter

### 3) Backup script
File: bin/backup_to_drive.sh

Requirements:
- bash, set -euo pipefail
- Determine root dir as the parent of bin/, so it works regardless of current directory.
- Load config.yaml
- Validate rclone exists.
- Validate remote is reachable (rclone lsf remote: should succeed).
- Run:
  rclone sync "<root>/cursor-memory" "<remote>" with retries and timeouts.
  Use flags that are safe and quiet (do not spam).
- Write logs to backup.log_file (append).
- Never delete local files.
- Exit non-zero on hard failure.

### 4) Restore script
File: bin/restore_from_drive.sh

Requirements:
- bash, set -euo pipefail
- Load config.yaml
- Validate rclone exists and remote reachable.
- rclone sync remote -> local cursor-memory folder
- Print summary and next steps:
  - set active project
  - set active topic
  - load topic memory

### 5) Healthcheck script
File: bin/healthcheck.sh
Checks:
- root structure exists
- config.yaml exists
- rclone installed
- remote reachable
- ACTIVE_PROJECT.md and active topic file exist (if a real project is active)
Outputs actionable messages.

### 6) Project and topic helper scripts
create_project.sh <project-slug>:
- Create project folder structure
- Create 00-project-summary.md and 01-project-architecture.md with starter content
- Create ACTIVE_TOPIC.md default: topic_slug=INBOX
- Add entry to PROJECTS/_index.md if missing
- Idempotent

create_topic.sh <project-slug> <topic-slug>:
- Create topic folder with required files and conversations folder
- Set project ACTIVE_TOPIC.md to this topic
- Idempotent

set_active_project.sh <project-slug>:
- Validate exists (or allow INBOX)
- Write ACTIVE_PROJECT.md

set_active_topic.sh <topic-slug>:
- Resolve active project
- Validate topic exists under that project
- Write ACTIVE_TOPIC.md

### 7) Reminder script (manual summarization reminder)
File: bin/remind_to_summarize.sh

Requirements:
- bash, set -euo pipefail
- Load config.yaml
- Resolve active project and topic
- Determine if summarized today by rules above
- If not summarized:
  - notify-send if available
  - always append to reminders_log_file
Message:
"Reminder: no topic summary saved today for project '<project>', topic '<topic>'. In Cursor run: Summarize and update topic memory."

### 8) Cron installer for reminder (no sudo)
File: bin/install_cron_reminder.sh
- Idempotent
- Adds a line to user crontab with a marker comment: # cursor-memory-reminder
- Schedule default 17:30, configurable via config.yaml reminder.cron_time
- Cron line runs:
  <absolute-path-to>/cursor-memory/bin/remind_to_summarize.sh
- Must not duplicate entries

File: bin/uninstall_cron_reminder.sh
- Removes only the line with the marker

### 9) systemd user timer for backup (no sudo)
Create:
systemd/cursor-memory-backup.service
systemd/cursor-memory-backup.timer

Use systemd user units, installed under:
~/.config/systemd/user/

Service requirements:
- Type=oneshot
- WorkingDirectory points to the folder that contains cursor-memory/
- ExecStart calls bin/backup_to_drive.sh

Timer requirements:
- OnBootSec=2m
- OnUnitActiveSec=<backup_interval_minutes>m (default 30)
- Persistent=true

Create install/uninstall scripts:

bin/install_systemd_backup_timer.sh:
- Copy service and timer to ~/.config/systemd/user/
- Patch WorkingDirectory if needed, or use an approach that does not require patching:
  Option A: ExecStart uses absolute path to bin/backup_to_drive.sh
  Option B: Use %h expansions.
- systemctl --user daemon-reload
- systemctl --user enable --now cursor-memory-backup.timer
- Print status commands

bin/uninstall_systemd_backup_timer.sh:
- systemctl --user disable --now cursor-memory-backup.timer
- Remove unit files
- daemon-reload

### 10) Documentation files (must be created)
docs/OVERVIEW.md:
- Why files are durable memory
- Why no DB or MCP for now
- Topic isolation concept

docs/WORKFLOW.md:
- How to create project and topic
- How to set active project/topic
- How to load topic memory in Cursor
- End-of-session routine:
  "Summarize and update topic memory"
- Inbox triage suggestion

docs/BACKUP.md:
- How backup works
- Where remote lives
- How to verify:
  rclone lsf remote
- How to view logs
- How to change interval

docs/RESTORE.md:
- New laptop steps:
  1) install rclone
  2) configure gdrive remote
  3) clone repo or create cursor-memory folder
  4) run restore_from_drive.sh
  5) reinstall timers and cron reminder
- Verification checklist

docs/TROUBLESHOOTING.md:
- rclone auth issues
- systemd user services not running
- cron issues
- notify-send missing
- active project/topic not set

docs/NAMING.md:
- slug rules
- file naming examples
- how to decide when to create a new topic

### 11) README.md update
Include:
- What this is
- Quick start commands
- Backup setup
- Reminder setup
- Logs locations
- Restore summary

## Fedora-specific notes (must include in docs)
- systemd user timers need lingering only if you want them to run when you are logged out.
  For laptop use, assume logged in is fine.
- cron runs for the user via cronie, if not installed, document how to install.

## Acceptance Test Plan (Cursor must provide)
Provide a step-by-step test plan that can be executed locally:
1) Create project and topic
2) Set active project/topic
3) Run backup script (dry run supported if you choose to add it)
4) Confirm log updated
5) Run reminder script when no summary exists, confirm log line added
6) Create a conversation file for today, confirm reminder does not trigger
7) Install and remove cron reminder, show crontab output
8) Install systemd backup timer, show systemctl --user status output, then uninstall

## Important constraint
Do not add any database, embeddings, or MCP here.
This system is about durable context through structured Markdown and automatic Drive backup.

