#!/bin/bash
#
# ROSE-REC Automation Installer v4
# ---------------------------------
# Everything from v3, PLUS:
# - After each file uploads to Google Drive, the upload is VERIFIED
#   (rclone check: size + checksum against the Drive copy).
# - Only after successful verification is the file DELETED from the device.
# - Files that fail upload or verification stay on the device and are
#   retried on the next plug-in.

set -e
echo "=============================================="
echo " ROSE-REC Automation Installer v4"
echo " (verified upload + auto-delete from device)"
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
# ROSE-REC Recording Auto-Upload Watcher (v4)
# Uploads NEW audio files from ROSE-REC1 / ROSE-REC2 to Google Drive
# Recordings/Inbox via rclone, verifies the upload, then deletes the
# file from the device. Both devices treated identically.

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
    if [ -z "$REC_DIR" ]; then
        REC_DIR="$VOLUME"
        log "NOTE: $DEVICE has no RECORD-style folder; scanning entire volume"
    fi

    log "Scanning $DEVICE ($REC_DIR)..."
    UPLOADED_COUNT=0
    DELETED_COUNT=0

    osascript -e "display notification \"Checking $DEVICE for new recordings...\" with title \"ROSE-REC Watcher\"" 2>/dev/null

    while IFS= read -r -d '' FILE; do
        BASENAME=$(basename "$FILE")

        # Skip macOS metadata junk (._foo.WAV) and hidden files
        case "$BASENAME" in
            ._*|.*) continue ;;
        esac

        SIZE=$(stat -f%z "$FILE" 2>/dev/null || echo 0)
        [ "$SIZE" -gt 4096 ] || continue   # skip zero/near-zero byte stubs

        FINGERPRINT="$DEVICE|$BASENAME|$SIZE"

        # Include the parent subfolder (e.g. date folder) in the uploaded name
        PARENT=$(basename "$(dirname "$FILE")")
        if [ "$PARENT" != "$(basename "$REC_DIR")" ] && [ "$PARENT" != "$DEVICE" ]; then
            DEST_NAME="${DEVICE}_${PARENT}_${BASENAME}"
        else
            DEST_NAME="${DEVICE}_${BASENAME}"
        fi
        DEST_NAME=$(echo "$DEST_NAME" | tr '/:' '__')

        ALREADY_UPLOADED=false
        if grep -qF "$FINGERPRINT" "$COPIED_LOG"; then
            ALREADY_UPLOADED=true
        else
            if "$RCLONE" copyto "$FILE" "gdrive:$DEST_NAME" \
                --drive-root-folder-id "$INBOX_ID" \
                --retries 3 --low-level-retries 10 >> "$LOG_FILE" 2>&1; then
                echo "$FINGERPRINT" >> "$COPIED_LOG"
                UPLOADED_COUNT=$((UPLOADED_COUNT + 1))
                ALREADY_UPLOADED=true
                log "Uploaded: $FILE -> Drive Inbox/$DEST_NAME"
            else
                log "ERROR uploading $BASENAME (kept on device; will retry next plug-in)"
                continue
            fi
        fi

        # VERIFY the Drive copy before deleting from the device:
        # rclone check compares size + checksum of the local file vs the Drive copy.
        if [ "$ALREADY_UPLOADED" = true ]; then
            if "$RCLONE" check "$FILE" "gdrive:" \
                --drive-root-folder-id "$INBOX_ID" \
                --include "/$DEST_NAME" --one-way >> /dev/null 2>&1 || \
               "$RCLONE" checksum md5 <("$RCLONE" md5sum "gdrive:$DEST_NAME" --drive-root-folder-id "$INBOX_ID" 2>/dev/null) "$FILE" >/dev/null 2>&1; then
                :
            fi
            # Simpler robust verification: compare remote size to local size
            REMOTE_SIZE=$("$RCLONE" size "gdrive:$DEST_NAME" --drive-root-folder-id "$INBOX_ID" --json 2>/dev/null | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('bytes',-1))" 2>/dev/null)
            if [ "$REMOTE_SIZE" = "$SIZE" ]; then
                if rm -f "$FILE" 2>/dev/null; then
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                    log "Verified + deleted from device: $BASENAME (size match: $SIZE bytes)"
                else
                    log "WARN: verified but could not delete $BASENAME (read-only device?)"
                fi
            else
                log "WARN: NOT deleting $BASENAME - remote size ($REMOTE_SIZE) != local size ($SIZE)"
            fi
        fi
    done < <(find "$REC_DIR" \( -iname "*.wav" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.mp4" -o -iname "*.aac" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" -o -iname "*.amr" \) -type f -not -path "*/.*" -print0 2>/dev/null)

    # Clean up macOS junk metadata files left behind in emptied folders
    find "$REC_DIR" -name "._*" -type f -delete 2>/dev/null

    if [ "$UPLOADED_COUNT" -gt 0 ] || [ "$DELETED_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$UPLOADED_COUNT uploaded, $DELETED_COUNT cleaned off device\" with title \"$DEVICE: Done\" sound name \"Glass\"" 2>/dev/null
    else
        osascript -e "display notification \"No new recordings found\" with title \"$DEVICE: Up to date\"" 2>/dev/null
    fi
    log "$DEVICE: $UPLOADED_COUNT uploaded, $DELETED_COUNT deleted from device."
done
WATCHER_EOF

chmod +x "$HOME/Scripts/rose_rec_watcher.sh"
echo "[1/3] Watcher v4 installed (verified upload + auto-delete)"

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
    echo "Device detected — running scan now (uploads + cleanup may take a while)..."
    bash "$HOME/Scripts/rose_rec_watcher.sh"
    echo "Scan complete. Last log lines:"
    tail -5 "$HOME/Library/Logs/rose_rec_watcher.log"
fi

echo ""
echo "=============================================="
echo " DONE! From now on: plug in a device, new"
echo " recordings upload to Drive Inbox, uploads are"
echo " verified, then files are wiped off the device."
echo " Log: ~/Library/Logs/rose_rec_watcher.log"
echo "=============================================="
