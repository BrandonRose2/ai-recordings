#!/bin/bash
#
# ROSE-REC Automation Installer v2 (rclone edition)
# --------------------------------------------------
# Replaces the previous watcher. Uploads new recordings from ROSE-REC1 /
# ROSE-REC2 directly to Google Drive "Recordings/Inbox" via rclone —
# no Google Drive desktop app required.
#
# Prerequisite (already done): rclone installed + "gdrive" remote authorized.

set -e
echo "=============================================="
echo " ROSE-REC Automation Installer v2 (rclone)"
echo "=============================================="

USERNAME=$(whoami)
echo "Detected user: $USERNAME"

# Verify rclone + remote before installing
if ! command -v rclone >/dev/null 2>&1; then
    echo "ERROR: rclone not found. Install it first: curl https://rclone.org/install.sh | sudo bash"
    exit 1
fi
if ! rclone listremotes | grep -q "^gdrive:"; then
    echo "ERROR: rclone remote 'gdrive' not configured. Run: rclone config create gdrive drive scope=drive"
    exit 1
fi
echo "rclone + gdrive remote: OK"

mkdir -p "$HOME/Scripts"

# ---------- 1. Write the watcher script ----------
cat > "$HOME/Scripts/rose_rec_watcher.sh" << 'WATCHER_EOF'
#!/bin/bash
# ROSE-REC Recording Auto-Upload Watcher (rclone edition)
# Uploads NEW files from ROSE-REC1 / ROSE-REC2 "Recordings" folders directly
# to Google Drive Recordings/Inbox via rclone. Duplicates are skipped.

DEVICES=("ROSE-REC1" "ROSE-REC2")
COPIED_LOG="$HOME/.rose_rec_copied.log"
LOG_FILE="$HOME/Library/Logs/rose_rec_watcher.log"
AUDIO_EXTS=("m4a" "mp3" "wav" "mp4" "aac" "flac" "ogg" "opus" "wma" "amr")

# Google Drive folder IDs (Recordings root and its Inbox subfolder)
RECORDINGS_ROOT_ID="1Gxg3gg06CVLO-F05kke5CXvdXgVXSPsP"
INBOX_ID="1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9"

RCLONE="/usr/local/bin/rclone"
[ -x "$RCLONE" ] || RCLONE="$(command -v rclone)"

touch "$COPIED_LOG"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"; }

for DEVICE in "${DEVICES[@]}"; do
    VOLUME="/Volumes/$DEVICE"
    [ -d "$VOLUME" ] || continue

    REC_DIR=$(find "$VOLUME" -maxdepth 3 -type d -iname "Recordings" 2>/dev/null | head -1)
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
            if "$RCLONE" copyto "$FILE" "gdrive:$DEST_NAME" \
                --drive-root-folder-id "$INBOX_ID" \
                --retries 3 --low-level-retries 10 >> "$LOG_FILE" 2>&1; then
                echo "$FINGERPRINT" >> "$COPIED_LOG"
                COPIED_COUNT=$((COPIED_COUNT + 1))
                log "Uploaded: $BASENAME -> Drive Inbox/$DEST_NAME"
            else
                log "ERROR uploading $BASENAME (will retry next time device is plugged in)"
            fi
        done < <(find "$REC_DIR" -type f -iname "*.${EXT}" -print0 2>/dev/null)
    done

    if [ "$COPIED_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$COPIED_COUNT new recording(s) uploaded to Google Drive Inbox\" with title \"$DEVICE\"" 2>/dev/null
    fi
    log "$DEVICE: $COPIED_COUNT new file(s) uploaded."
done
WATCHER_EOF

chmod +x "$HOME/Scripts/rose_rec_watcher.sh"
echo "[1/3] Watcher script (rclone edition) installed"

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
echo "[2/3] Auto-run trigger refreshed"

# ---------- 3. Reload the Launch Agent ----------
launchctl unload "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist"
echo "[3/3] Auto-run trigger activated"

echo ""
echo "=============================================="
echo " DONE! Plug in ROSE-REC1 or ROSE-REC2 to test."
echo " Uploads go straight to Google Drive Inbox"
echo " via rclone (no Drive desktop app needed)."
echo ""
echo " Log: ~/Library/Logs/rose_rec_watcher.log"
echo "=============================================="
