# Troubleshooting

## rclone Auth Issues

**Symptom:** `rclone lsf gdrive:` fails or prompts for re-auth.

**Fix:**
```bash
rclone config reconnect gdrive:
```
Follow the browser-based OAuth flow. If on a headless machine, use `rclone authorize` on a machine with a browser and paste the token.

## systemd User Services Not Running

**Symptom:** `systemctl --user status cursor-memory-backup.timer` shows inactive or not found.

**Fixes:**

1. Reinstall:
   ```bash
   bin/install_systemd_backup_timer.sh
   ```

2. Check if user services work:
   ```bash
   systemctl --user list-timers
   ```

3. If timers don't survive logout and you need them to, enable lingering:
   ```bash
   loginctl enable-linger $USER
   ```
   Note: for laptop use where you're always logged in, lingering is typically not needed.

4. Check logs:
   ```bash
   journalctl --user -u cursor-memory-backup.service --since today
   ```

## Cron Issues

**Symptom:** Reminder never fires.

**Fixes:**

1. Verify cronie is installed:
   ```bash
   rpm -q cronie
   # If missing:
   sudo dnf install cronie
   sudo systemctl enable --now crond
   ```

2. Check crontab:
   ```bash
   crontab -l
   ```
   You should see a line ending with `# cursor-memory-reminder`.

3. Check cron logs:
   ```bash
   journalctl -u crond --since today
   ```

## notify-send Missing

**Symptom:** Reminder runs but no desktop notification appears.

**Fix:**
```bash
sudo dnf install libnotify
```

The reminder script works without `notify-send` — it always writes to the log file. Desktop notifications are a nice-to-have.

## Active Project/Topic Not Set

**Symptom:** `healthcheck.sh` shows ACTIVE_PROJECT.md missing or set to INBOX.

**Fix:**
```bash
bin/set_active_project.sh my-project
bin/set_active_topic.sh my-topic
```

If the project doesn't exist yet:
```bash
bin/create_project.sh my-project
bin/create_topic.sh my-project my-topic
```
