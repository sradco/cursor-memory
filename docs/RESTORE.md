# Restore

## New Laptop / Fresh Setup

Follow these steps to restore cursor-memory on a new machine.

### 1. Install rclone

```bash
sudo dnf install rclone    # Fedora
# or
curl https://rclone.org/install.sh | sudo bash
```

### 2. Clone the repo

```bash
git clone https://github.com/sradco/cursor-memory.git
cd cursor-memory
```

### 3. Run setup (configures rclone remote, creates config.yaml)

```bash
bin/setup.sh
```

The wizard will detect existing rclone remotes or guide you through creating one.

### 4. Run Restore

```bash
bin/restore_from_drive.sh
```

This syncs all files from Google Drive to the local folder.

### 5. Verify

```bash
bin/healthcheck.sh
```

Note: if you skipped the backup timer and cron reminder during `bin/setup.sh`, install them now:
```bash
bin/install_systemd_backup_timer.sh
bin/install_cron_reminder.sh
```

## Verification Checklist

- [ ] `config.yaml` exists and has correct remote
- [ ] `rclone lsf gdrive:CursorBackups/cursor-memory` shows files
- [ ] `ACTIVE_PROJECT.md` exists
- [ ] Project folders restored under `PROJECTS/`
- [ ] `systemctl --user status cursor-memory-backup.timer` shows active
- [ ] `crontab -l` shows the reminder entry
- [ ] `bin/healthcheck.sh` passes all checks
