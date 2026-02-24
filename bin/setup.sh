#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== cursor-memory setup ==="
echo ""

# Step 1: config.yaml
if [[ -f "$ROOT_DIR/config.yaml" ]]; then
  echo "[OK] config.yaml already exists"
else
  cp "$ROOT_DIR/config.example.yaml" "$ROOT_DIR/config.yaml"
  echo "[OK] Created config.yaml from config.example.yaml"
fi

# Step 2: rclone
echo ""
if ! command -v rclone &>/dev/null; then
  echo "rclone is not installed."
  echo ""
  echo "Install it with:"
  echo "  Fedora/RHEL:  sudo dnf install rclone"
  echo "  Ubuntu/Debian: sudo apt install rclone"
  echo "  Any Linux:     curl https://rclone.org/install.sh | sudo bash"
  echo "  macOS:         brew install rclone"
  echo ""
  echo "Run this script again after installing rclone."
  exit 1
fi
echo "[OK] rclone is installed"

# Step 3: detect or create remote
echo ""
EXISTING_REMOTES="$(rclone listremotes 2>/dev/null || true)"

if [[ -n "$EXISTING_REMOTES" ]]; then
  echo "Found existing rclone remotes:"
  echo ""
  i=1
  declare -a REMOTE_LIST=()
  while IFS= read -r remote; do
    [[ -z "$remote" ]] && continue
    REMOTE_LIST+=("$remote")
    echo "  $i) $remote"
    i=$((i + 1))
  done <<< "$EXISTING_REMOTES"
  echo "  N) Create a new remote"
  echo ""
  read -rp "Pick a remote to use [1]: " CHOICE
  CHOICE="${CHOICE:-1}"

  if [[ "$CHOICE" == "N" || "$CHOICE" == "n" ]]; then
    echo ""
    echo "Running: rclone config"
    echo "Create a remote of type 'drive' for Google Drive."
    echo "You can leave client_id and client_secret blank to use rclone defaults."
    echo ""
    rclone config
    EXISTING_REMOTES="$(rclone listremotes 2>/dev/null || true)"
    SELECTED_REMOTE="$(echo "$EXISTING_REMOTES" | tail -1)"
  else
    IDX=$((CHOICE - 1))
    SELECTED_REMOTE="${REMOTE_LIST[$IDX]}"
  fi
else
  echo "No rclone remotes configured. Let's create one."
  echo ""
  echo "Running: rclone config"
  echo "Create a remote of type 'drive' for Google Drive."
  echo "You can leave client_id and client_secret blank to use rclone defaults."
  echo ""
  rclone config
  EXISTING_REMOTES="$(rclone listremotes 2>/dev/null || true)"
  SELECTED_REMOTE="$(echo "$EXISTING_REMOTES" | head -1)"
fi

SELECTED_REMOTE="${SELECTED_REMOTE%:}"
echo ""
echo "Using remote: $SELECTED_REMOTE"

# Step 4: choose backup path
DEFAULT_PATH="CursorBackups/cursor-memory"
read -rp "Backup path on remote [$DEFAULT_PATH]: " BACKUP_PATH
BACKUP_PATH="${BACKUP_PATH:-$DEFAULT_PATH}"

FULL_REMOTE="${SELECTED_REMOTE}:${BACKUP_PATH}"

# Step 5: verify connectivity
echo ""
echo "Testing remote connectivity..."
if rclone about "${SELECTED_REMOTE}:" &>/dev/null; then
  echo "[OK] Remote '$SELECTED_REMOTE' is reachable"
else
  echo "[FAIL] Cannot reach remote '$SELECTED_REMOTE'"
  echo "Run: rclone config reconnect ${SELECTED_REMOTE}:"
  exit 1
fi

# Step 6: update config.yaml
sed -i "s|rclone_remote:.*|rclone_remote: \"${FULL_REMOTE}\"|" "$ROOT_DIR/config.yaml"
echo "[OK] Updated config.yaml with remote: $FULL_REMOTE"

# Step 7: optional — install backup timer
echo ""
read -rp "Install automatic backup timer (systemd)? [Y/n]: " INSTALL_TIMER
INSTALL_TIMER="${INSTALL_TIMER:-Y}"
if [[ "$INSTALL_TIMER" =~ ^[Yy]$ ]]; then
  "$ROOT_DIR/bin/install_systemd_backup_timer.sh"
fi

# Step 8: optional — install cron reminder
echo ""
read -rp "Install daily summarization reminder (cron)? [Y/n]: " INSTALL_CRON
INSTALL_CRON="${INSTALL_CRON:-Y}"
if [[ "$INSTALL_CRON" =~ ^[Yy]$ ]]; then
  "$ROOT_DIR/bin/install_cron_reminder.sh"
fi

# Step 9: install Cursor rule
RULE_SRC="$ROOT_DIR/.cursor/rules/cursor-memory-auto.mdc"
echo ""
if [[ -f "$RULE_SRC" ]]; then
  PARENT_DIR="$(cd "$ROOT_DIR/.." && pwd)"
  DEFAULT_WORKSPACE="$PARENT_DIR"
  echo "The Cursor rule needs to be installed in your workspace's .cursor/rules/ folder."
  echo "This is the folder you open in Cursor (not cursor-memory/ itself)."
  echo ""
  read -rp "Cursor workspace root [$DEFAULT_WORKSPACE]: " WORKSPACE_DIR
  WORKSPACE_DIR="${WORKSPACE_DIR:-$DEFAULT_WORKSPACE}"

  if [[ -d "$WORKSPACE_DIR" ]]; then
    RULE_DST="$WORKSPACE_DIR/.cursor/rules/cursor-memory-auto.mdc"
    mkdir -p "$WORKSPACE_DIR/.cursor/rules"
    cp "$RULE_SRC" "$RULE_DST"
    echo "[OK] Cursor rule installed at $RULE_DST"
  else
    echo "[WARN] Directory '$WORKSPACE_DIR' does not exist. Skipping rule install."
    echo "Manually copy: $RULE_SRC"
    echo "  to: <your-workspace>/.cursor/rules/cursor-memory-auto.mdc"
  fi
else
  echo "[WARN] Cursor rule source not found at $RULE_SRC"
fi

# Step 10: healthcheck
echo ""
echo "Running healthcheck..."
echo ""
"$ROOT_DIR/bin/healthcheck.sh" || true

echo ""
echo "=== Setup complete ==="
echo ""
echo "You're ready to go! Open Cursor and start working."
echo "Projects and topics are managed automatically."
echo ""
echo "At the end of each session, say:"
echo '  "Summarize and update topic memory."'
echo ""
