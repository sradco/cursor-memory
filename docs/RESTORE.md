# Restore

## New Laptop / Fresh Setup

Follow these steps to restore cursor-memory on a new machine.

### 1. Install rclone

```bash
sudo dnf install rclone    # Fedora
# or
curl https://rclone.org/install.sh | sudo bash
```

### 2. Configure Google Drive Remote

```bash
rclone config
```

Create a remote named `gdrive` of type `drive`. Follow the interactive prompts to authenticate.

Verify:
```bash
rclone lsf gdrive:CursorBackups/cursor-memory
```

### 3. Create the cursor-memory Folder

```bash
mkdir -p ~/cursor-memory
cd ~/cursor-memory
```

Or clone the repo if cursor-memory is tracked in git.

### 4. Create Minimal Config

Create `config.yaml` (or copy from `config.example.yaml`):
```yaml
backup:
  rclone_remote: "gdrive:CursorBackups/cursor-memory"
  log_file: "./backup.log"
  reminders_log_file: "./memory-reminders.log"
  backup_interval_minutes: 30
reminder:
  cron_time: "17:30"
```

### 5. Run Restore

```bash
bin/restore_from_drive.sh
```

This syncs all files from Google Drive to the local folder.

### 6. Reinstall Automation

```bash
bin/install_systemd_backup_timer.sh
bin/install_cron_reminder.sh
```

### 7. Verify

```bash
bin/healthcheck.sh
```

## Verification Checklist

- [ ] `config.yaml` exists and has correct remote
- [ ] `rclone lsf gdrive:CursorBackups/cursor-memory` shows files
- [ ] `ACTIVE_PROJECT.md` exists
- [ ] Project folders restored under `PROJECTS/`
- [ ] `systemctl --user status cursor-memory-backup.timer` shows active
- [ ] `crontab -l` shows the reminder entry
- [ ] `bin/healthcheck.sh` passes all checks
