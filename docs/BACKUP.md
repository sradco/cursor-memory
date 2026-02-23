# Backup

## How It Works

The backup system uses [rclone](https://rclone.org/) to sync the entire `cursor-memory/` folder to Google Drive. It runs automatically via a systemd user timer.

**Flow:**
```
cursor-memory/ → rclone sync → gdrive:CursorBackups/cursor-memory
```

- Uses `rclone sync` (source → remote), never deletes local files.
- Retries up to 3 times on failure.
- Logs all activity to the configured `backup.log`.

## Remote Location

Default remote path (configurable in `config.yaml`):
```
gdrive:CursorBackups/cursor-memory
```

## Verify Backup

```bash
# List files on the remote
rclone lsf gdrive:CursorBackups/cursor-memory

# Check detailed listing
rclone ls gdrive:CursorBackups/cursor-memory
```

## View Logs

```bash
# Show recent backup log entries
tail -20 cursor-memory/backup.log
```

## Change Backup Interval

Edit `config.yaml`:
```yaml
backup:
  backup_interval_minutes: 15  # default is 30
```

Then reinstall the systemd timer to pick up the change:
```bash
bin/install_systemd_backup_timer.sh
```

## Manual Backup

```bash
bin/backup_to_drive.sh
```

## Setup

See the [README](../README.md) for initial setup instructions.
