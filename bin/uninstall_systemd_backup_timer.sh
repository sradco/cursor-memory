#!/usr/bin/env bash
set -euo pipefail

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "Stopping and disabling cursor-memory-backup.timer..."
systemctl --user disable --now cursor-memory-backup.timer 2>/dev/null || true

echo "Removing unit files..."
rm -f "$USER_SYSTEMD_DIR/cursor-memory-backup.service"
rm -f "$USER_SYSTEMD_DIR/cursor-memory-backup.timer"

systemctl --user daemon-reload

echo "systemd backup timer uninstalled."
