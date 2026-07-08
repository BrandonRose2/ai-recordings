#!/bin/bash
#
# ROSE-REC Automation Installer v3
# ---------------------------------
# Matches the actual device layout discovered on ROSE-REC2:
#   /Volumes/ROSE-REC2/RECORD/<subfolder>/<file>.WAV
# - Searches for RECORD / RECORDINGS / VOICE / REC folders (case-insensitive)
# - Falls back to scanning the whole volume for audio if no such folder exists
# - Skips macOS junk files (._*) and zero-byte files
# - Uploads via rclone directly to Google Drive Recordings/Inbox

set -e
echo "=============================================="
echo " ROSE-REC Automation Installer v3"
echo "=============================================="

USERNAME=$(whoami)
echo "Detected user: $USERNAME"

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

cat > "$HOME/Scripts/rose_rec_watcher.sh" << 'WATCHER_EOF'
#!/bin/bash
# ROSE-REC Recording Auto-Upload Watcher (v3)
# Uploads NEW audio files from ROSE-REC1 / ROSE-REC2 to Google Drive
# Recordings/Inbox via rclone. Both devices treated identically.

DEVICES=("ROSE-REC1" "ROSE-REC2")
COPIED_LOG="$HOME/.rose_rec_copied.log"
LOG_FILE="$HOME/Library/Logs/rose_rec_watcher.log"

INBOX_ID="1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9"   # Google Drive Recordings/Inbox

RCLONE="/usr/local/bin/rclone"
[ -x "$RCLONE" ] || RCLONE="$(command -v rclone)"

touch "$COPIED_LOG"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"; }

for DEVICE in "${DEVICES[@]}"; do
    VOLUME="/Volumes/$DEVICE"
    [ -d "$VOLUME" ] || continue

    # Find the recordings folder: RECORD, RECORDINGS, VOICE, REC, etc.
    REC_DIR=""
    for NAME in "RECORD" "RECORDINGS" "RECORDING" "VOICE" "REC" "AUDIO"; do
        REC_DIR=$(find "$VOLUME" -maxdepth 2 -type d -iname "$NAME" -not -path "*/.*" 2>/dev/null | head -1)
        [ -n "$REC_DIR" ] && break
    done
    # Fallback: scan the whole volume (excluding hidden/system dirs)
    if [ -z "$REC_DIR" ]; then
        REC_DIR="$VOLUME"
        log "NOTE: $DEVICE has no RECORD-style folder; scanning entire volume"
    fi

    log "Scanning $DEVICE ($REC_DIR)..."
    COPIED_COUNT=0

    while IFS= read -r -d '' FILE; do
        BASENAME=$(basename "$FILE")

        # Skip macOS metadata junk (._foo.WAV) and hidden files
        case "$BASENAME" in
            ._*|.*) continue ;;
        esac

        SIZE=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
        [ "$SIZE" -gt 4096 ] || continue   # skip zero/near-zero byte stubs

        FINGERPRINT="$DEVICE|$BASENAME|$SIZE"
        grep -qF "$FINGERPRINT" "$COPIED_LOG" && continue

        # Include the parent subfolder (e.g. date folder) in the uploaded name
        PARENT=$(basename "$(dirname "$FILE")")
        if [ "$PARENT" != "$(basename "$REC_DIR")" ] && [ "$PARENT" != "$DEVICE" ]; then
            DEST_NAME="${DEVICE}_${PARENT}_${BASENAME}"
        else
            DEST_NAME="${DEVICE}_${BASENAME}"
        fi
        # Sanitize slashes/colons
        DEST_NAME=$(echo "$DEST_NAME" | tr '/:' '__')

        if "$RCLONE" copyto "$FILE" "gdrive:$DEST_NAME" \
            --drive-root-folder-id "$INBOX_ID" \
            --retries 3 --low-level-retries 10 >> "$LOG_FILE" 2>&1; then
            echo "$FINGERPRINT" >> "$COPIED_LOG"
            COPIED_COUNT=$((COPIED_COUNT + 1))
            log "Uploaded: $FILE -> Drive Inbox/$DEST_NAME"
        else
            log "ERROR uploading $BASENAME (will retry on next plug-in)"
        fi
    done < <(find "$REC_DIR" \( -iname "*.wav" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.mp4" -o -iname "*.aac" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" -o -iname "*.amr" \) -type f -not -path "*/.*" -print0 2>/dev/null)

    if [ "$COPIED_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$COPIED_COUNT new recording(s) uploaded to Google Drive Inbox\" with title \"$DEVICE\"" 2>/dev/null
    fi
    log "$DEVICE: $COPIED_COUNT new file(s) uploaded."
done
WATCHER_EOF

chmod +x "$HOME/Scripts/rose_rec_watcher.sh"
echo "[1/3] Watcher v3 installed"

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

launchctl unload "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist"
echo "[3/3] Auto-run trigger activated"

# Run an immediate scan if a device is already plugged in
if [ -d "/Volumes/ROSE-REC1" ] || [ -d "/Volumes/ROSE-REC2" ]; then
    echo ""
    echo "Device detected — running first scan now (may take a while for large files)..."
    bash "$HOME/Scripts/rose_rec_watcher.sh"
    echo "First scan complete. Last log lines:"
    tail -5 "$HOME/Library/Logs/rose_rec_watcher.log"
fi

echo ""
echo "=============================================="
echo " DONE! New recordings on ROSE-REC1/ROSE-REC2"
echo " now upload straight to Google Drive Inbox."
echo " Log: ~/Library/Logs/rose_rec_watcher.log"
echo "=============================================="
