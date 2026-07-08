#!/bin/bash
#
# ROSE-REC Automation — One-Click Installer
# -----------------------------------------
# Double-click this file (or run: bash install_rose_rec.command)
# It installs everything: the watcher script AND the auto-run trigger.
# No editing needed — it detects your username and Google Drive path.

set -e
echo "=============================================="
echo " ROSE-REC Recordings Automation Installer"
echo "=============================================="

USERNAME=$(whoami)
echo "Detected user: $USERNAME"

mkdir -p "$HOME/Scripts"

# ---------- 1. Write the watcher script ----------
cat > "$HOME/Scripts/rose_rec_watcher.sh" << 'WATCHER_EOF'
#!/bin/bash
# ROSE-REC Recording Auto-Copy Watcher
# Copies NEW files from ROSE-REC1 / ROSE-REC2 "Recordings" folders
# into Google Drive "Recordings/Inbox". Duplicates are skipped.

DEVICES=("ROSE-REC1" "ROSE-REC2")
COPIED_LOG="$HOME/.rose_rec_copied.log"
LOG_FILE="$HOME/Library/Logs/rose_rec_watcher.log"
AUDIO_EXTS=("m4a" "mp3" "wav" "mp4" "aac" "flac" "ogg" "opus" "wma" "amr")

touch "$COPIED_LOG"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"; }

resolve_inbox() {
    local resolved
    resolved=$(ls -d "$HOME/Library/CloudStorage/"GoogleDrive-*"/My Drive/Recordings/Inbox" 2>/dev/null | head -1)
    if [ -z "$resolved" ]; then
        resolved=$(ls -d "$HOME/Google Drive/My Drive/Recordings/Inbox" 2>/dev/null | head -1)
    fi
    if [ -z "$resolved" ]; then
        local mydrive
        mydrive=$(ls -d "$HOME/Library/CloudStorage/"GoogleDrive-*"/My Drive" 2>/dev/null | head -1)
        if [ -n "$mydrive" ]; then
            mkdir -p "$mydrive/Recordings/Inbox"
            resolved="$mydrive/Recordings/Inbox"
        fi
    fi
    echo "$resolved"
}

INBOX=$(resolve_inbox)
if [ -z "$INBOX" ]; then
    log "ERROR: Google Drive Recordings/Inbox not found. Is Google Drive for desktop running?"
    exit 1
fi

for DEVICE in "${DEVICES[@]}"; do
    VOLUME="/Volumes/$DEVICE"
    [ -d "$VOLUME" ] || continue

    REC_DIR=$(find "$VOLUME" -maxdepth 2 -type d -iname "Recordings" 2>/dev/null | head -1)
    if [ -z "$REC_DIR" ]; then
        log "WARN: $DEVICE mounted but no Recordings folder found"
        continue
    fi

    log "Scanning $DEVICE ($REC_DIR)..."
    COPIED_COUNT=0

    for EXT in "${AUDIO_EXTS[@]}"; do
        while IFS= read -r -d '' FILE; do
            BASENAME=$(basename "$FILE")
            SIZE=$(stat -f%z "$FILE")
            FINGERPRINT="$DEVICE|$BASENAME|$SIZE"
            grep -qF "$FINGERPRINT" "$COPIED_LOG" && continue
            DEST_NAME="${DEVICE}_${BASENAME}"
            if cp -n "$FILE" "$INBOX/$DEST_NAME"; then
                echo "$FINGERPRINT" >> "$COPIED_LOG"
                COPIED_COUNT=$((COPIED_COUNT + 1))
                log "Copied: $BASENAME -> Inbox/$DEST_NAME"
            else
                log "ERROR copying $BASENAME"
            fi
        done < <(find "$REC_DIR" -type f -iname "*.${EXT}" -print0 2>/dev/null)
    done

    if [ "$COPIED_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$COPIED_COUNT new recording(s) sent to Google Drive Inbox\" with title \"$DEVICE\"" 2>/dev/null
    fi
    log "$DEVICE: $COPIED_COUNT new file(s) copied."
done
WATCHER_EOF

chmod +x "$HOME/Scripts/rose_rec_watcher.sh"
echo "[1/3] Watcher script installed at ~/Scripts/rose_rec_watcher.sh"

# ---------- 2. Write the Launch Agent ----------
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.rose.recwatcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/$USERNAME/Scripts/rose_rec_watcher.sh</string>
    </array>
    <key>StartOnMount</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/rose_rec_watcher.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/rose_rec_watcher.err</string>
</dict>
</plist>
PLIST_EOF
echo "[2/3] Auto-run trigger installed"

# ---------- 3. Load the Launch Agent ----------
launchctl unload "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist"
echo "[3/3] Auto-run trigger activated"

echo ""
echo "=============================================="
echo " DONE! Test it: plug in ROSE-REC1 or ROSE-REC2."
echo " You should see a notification when new"
echo " recordings are copied to Google Drive."
echo ""
echo " Log file: ~/Library/Logs/rose_rec_watcher.log"
echo "=============================================="
