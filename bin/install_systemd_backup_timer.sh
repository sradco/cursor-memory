#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_FILE="${CURSOR_MEMORY_CONFIG:-"$ROOT_DIR/config.yaml"}"

BACKUP_INTERVAL=30
if [[ -f "$CONFIG_FILE" ]]; then
  PARSED="$(grep -E "^\s*backup_interval_minutes:" "$CONFIG_FILE" | head -1 | sed 's/^[^:]*:\s*//;s/^"//;s/"$//' | xargs)"
  [[ -n "$PARSED" ]] && BACKUP_INTERVAL="$PARSED"
fi

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

cat > "$USER_SYSTEMD_DIR/cursor-memory-backup.service" <<EOF
[Unit]
Description=cursor-memory backup to Google Drive via rclone

[Service]
Type=oneshot
ExecStart=$ROOT_DIR/bin/backup_to_drive.sh
WorkingDirectory=$ROOT_DIR
EOF

cat > "$USER_SYSTEMD_DIR/cursor-memory-backup.timer" <<EOF
[Unit]
Description=cursor-memory periodic backup timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=${BACKUP_INTERVAL}min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now cursor-memory-backup.timer

echo ""
echo "systemd backup timer installed (every ${BACKUP_INTERVAL} minutes)."
echo ""
echo "Useful commands:"
echo "  systemctl --user status cursor-memory-backup.timer"
echo "  systemctl --user list-timers"
echo "  journalctl --user -u cursor-memory-backup.service"
