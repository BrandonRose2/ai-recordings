#!/bin/bash
#
# ROSE-REC Automation Installer v5
# ---------------------------------
# Changes vs v4:
# - Scans ONLY the RECORD folder on the device. Files/folders you have
#   manually grouped/renamed at the volume root are NEVER touched,
#   uploaded, or deleted.
# - Groups uploads into day folders in the Drive Inbox, named like
#   "Monday 07-06-2026", based on the recording's date (from the
#   V2026-07-06-... filename pattern, falling back to file mod date).
# - Waits for the device to fully mount (settle delay + retry) before
#   scanning, fixing the "no RECORD folder found" race on plug-in.
# - Removes the leftover duplicate Launch Agent (com.user.roserec.sync).
# - Keeps v4 behavior: verified upload (size match) then delete from
#   device (RECORD folder only); notifications; junk cleanup; lock file.

set -e
echo "=============================================="
echo " ROSE-REC Automation Installer v5.1"
echo " (RECORD/RECORDED/RECORDINGS folder support)"
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

# --- Remove old/duplicate launch agents ---
for OLD in com.user.roserec.sync com.rose.recwatcher; do
    if [ -f "$HOME/Library/LaunchAgents/$OLD.plist" ]; then
        launchctl unload "$HOME/Library/LaunchAgents/$OLD.plist" 2>/dev/null || true
    fi
done
rm -f "$HOME/Library/LaunchAgents/com.user.roserec.sync.plist"
echo "[1/4] Old/duplicate launch agents removed"

mkdir -p "$HOME/Scripts"

cat > "$HOME/Scripts/rose_rec_watcher.sh" << 'WATCHER_EOF'
#!/bin/bash
# ROSE-REC Recording Auto-Upload Watcher (v5.1: RECORD, RECORDED, RECORDINGS folders)
# RECORD-folder-only scan. Uploads new audio to Google Drive
# Recordings/Inbox, grouped into day folders ("Monday 07-06-2026"),
# verifies each upload (size match), then deletes the file from the
# device's RECORD folder. Root-level files are never touched.

DEVICES=("ROSE-REC1" "ROSE-REC2")
COPIED_LOG="$HOME/.rose_rec_copied.log"
LOG_FILE="$HOME/Library/Logs/rose_rec_watcher.log"
LOCK_FILE="/tmp/rose_rec_watcher.lock"

INBOX_ID="1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9"   # Google Drive Recordings/Inbox

RCLONE="/usr/local/bin/rclone"
[ -x "$RCLONE" ] || RCLONE="$(command -v rclone)"

touch "$COPIED_LOG"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"; }

# Prevent overlapping runs (plug-in trigger + manual run at same time)
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log "Another watcher run (PID $LOCK_PID) is active; exiting."
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# day_folder <file_path> -> echoes e.g. "Monday 07-06-2026"
day_folder() {
    local F="$1"
    local BASE Y M D EPOCH
    BASE=$(basename "$F")
    # Try device filename pattern V2026-07-06-...
    if [[ "$BASE" =~ ^V([0-9]{4})-([0-9]{2})-([0-9]{2})- ]]; then
        Y="${BASH_REMATCH[1]}"; M="${BASH_REMATCH[2]}"; D="${BASH_REMATCH[3]}"
        EPOCH=$(date -j -f "%Y-%m-%d" "$Y-$M-$D" "+%s" 2>/dev/null)
        if [ -n "$EPOCH" ]; then
            echo "$(date -j -f "%s" "$EPOCH" "+%A %m-%d-%Y")"
            return
        fi
    fi
    # Fallback: file modification date
    EPOCH=$(stat -f%m "$F" 2>/dev/null)
    if [ -n "$EPOCH" ]; then
        echo "$(date -j -f "%s" "$EPOCH" "+%A %m-%d-%Y")"
    else
        echo "Undated"
    fi
}

for DEVICE in "${DEVICES[@]}"; do
    VOLUME="/Volumes/$DEVICE"
    [ -d "$VOLUME" ] || continue

    # --- Mount-settle: retry finding the RECORD folder while the
    #     device filesystem finishes mounting ---
    REC_DIR=""
    for ATTEMPT in 1 2 3 4 5 6; do
        for NAME in "RECORD" "RECORDED" "RECORDINGS" "RECORDING" "VOICE" "REC" "AUDIO"; do
            REC_DIR=$(find "$VOLUME" -maxdepth 2 -type d -iname "$NAME" -not -path "*/.*" 2>/dev/null | head -1)
            [ -n "$REC_DIR" ] && break
        done
        [ -n "$REC_DIR" ] && break
        log "$DEVICE: RECORD folder not visible yet (attempt $ATTEMPT); waiting..."
        sleep 5
    done
    if [ -z "$REC_DIR" ]; then
        log "WARN: $DEVICE mounted but no RECORD folder found after settling. Doing nothing (root files are never scanned)."
        osascript -e "display notification \"No RECORD folder found on $DEVICE\" with title \"ROSE-REC Watcher\"" 2>/dev/null
        continue
    fi

    # Extra settle: wait until the file count inside RECORD is stable
    COUNT1=$(find "$REC_DIR" -type f -not -path "*/.*" 2>/dev/null | wc -l | tr -d ' ')
    sleep 4
    COUNT2=$(find "$REC_DIR" -type f -not -path "*/.*" 2>/dev/null | wc -l | tr -d ' ')
    while [ "$COUNT1" != "$COUNT2" ]; do
        COUNT1="$COUNT2"
        sleep 4
        COUNT2=$(find "$REC_DIR" -type f -not -path "*/.*" 2>/dev/null | wc -l | tr -d ' ')
    done

    log "Scanning $DEVICE ($REC_DIR)..."
    UPLOADED_COUNT=0
    DELETED_COUNT=0
    ERROR_COUNT=0

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

        # Group into a day folder in the Drive Inbox
        DAY_DIR=$(day_folder "$FILE")

        # Keep device subfolder context in the filename if present
        PARENT=$(basename "$(dirname "$FILE")")
        case "$PARENT" in
            RECORD|RECORDED|RECORDINGS|RECORDING|VOICE|REC|AUDIO)
                DEST_NAME="${DEVICE}_${BASENAME}" ;;
            *)
                DEST_NAME="${DEVICE}_${PARENT}_${BASENAME}" ;;
        esac
        DEST_NAME=$(echo "$DEST_NAME" | tr '/:' '__')
        DEST_PATH="$DAY_DIR/$DEST_NAME"

        ALREADY_UPLOADED=false
        if grep -qF "$FINGERPRINT" "$COPIED_LOG"; then
            ALREADY_UPLOADED=true
        else
            if "$RCLONE" copyto "$FILE" "gdrive:$DEST_PATH" \
                --drive-root-folder-id "$INBOX_ID" \
                --retries 3 --low-level-retries 10 >> "$LOG_FILE" 2>&1; then
                echo "$FINGERPRINT" >> "$COPIED_LOG"
                UPLOADED_COUNT=$((UPLOADED_COUNT + 1))
                ALREADY_UPLOADED=true
                log "Uploaded: $FILE -> Inbox/$DEST_PATH"
            else
                ERROR_COUNT=$((ERROR_COUNT + 1))
                log "ERROR uploading $BASENAME (kept on device; will retry next plug-in)"
                continue
            fi
        fi

        # VERIFY: compare remote size to local size, then delete local.
        # Note: older uploads (pre-v5) went to the Inbox root, so check
        # both locations before deleting.
        if [ "$ALREADY_UPLOADED" = true ]; then
            REMOTE_SIZE=$("$RCLONE" size "gdrive:$DEST_PATH" --drive-root-folder-id "$INBOX_ID" --json 2>/dev/null | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('bytes',-1))" 2>/dev/null)
            if [ "$REMOTE_SIZE" != "$SIZE" ]; then
                REMOTE_SIZE=$("$RCLONE" size "gdrive:$DEST_NAME" --drive-root-folder-id "$INBOX_ID" --json 2>/dev/null | /usr/bin/python3 -c "import sys,json; print(json.load(sys.stdin).get('bytes',-1))" 2>/dev/null)
            fi
            if [ "$REMOTE_SIZE" = "$SIZE" ]; then
                if rm -f "$FILE" 2>/dev/null; then
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                    log "Verified + deleted from device: $BASENAME ($SIZE bytes)"
                else
                    log "WARN: verified but could not delete $BASENAME (read-only device?)"
                fi
            else
                log "WARN: NOT deleting $BASENAME - remote size ($REMOTE_SIZE) != local size ($SIZE)"
            fi
        fi
    done < <(find "$REC_DIR" \( -iname "*.wav" -o -iname "*.m4a" -o -iname "*.mp3" -o -iname "*.mp4" -o -iname "*.aac" -o -iname "*.flac" -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wma" -o -iname "*.amr" \) -type f -not -path "*/.*" -print0 2>/dev/null)

    # Clean up macOS junk metadata files inside RECORD only
    find "$REC_DIR" -name "._*" -type f -delete 2>/dev/null
    # Remove now-empty date subfolders inside RECORD (never RECORD itself)
    find "$REC_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null

    if [ "$ERROR_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$UPLOADED_COUNT uploaded, $DELETED_COUNT cleaned, $ERROR_COUNT FAILED (will retry)\" with title \"$DEVICE: Done with errors\" sound name \"Basso\"" 2>/dev/null
    elif [ "$UPLOADED_COUNT" -gt 0 ] || [ "$DELETED_COUNT" -gt 0 ]; then
        osascript -e "display notification \"$UPLOADED_COUNT uploaded, $DELETED_COUNT cleaned off device\" with title \"$DEVICE: Done\" sound name \"Glass\"" 2>/dev/null
    else
        osascript -e "display notification \"No new recordings found\" with title \"$DEVICE: Up to date\"" 2>/dev/null
    fi
    log "$DEVICE: $UPLOADED_COUNT uploaded, $DELETED_COUNT deleted, $ERROR_COUNT errors."
done
WATCHER_EOF

chmod +x "$HOME/Scripts/rose_rec_watcher.sh"
echo "[2/4] Watcher v5 installed (RECORD-only + day grouping + verified delete)"

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
echo "[3/4] Auto-run trigger refreshed"

launchctl load "$HOME/Library/LaunchAgents/com.rose.recwatcher.plist"
echo "[4/4] Auto-run trigger activated"

# Run an immediate scan if a device is already plugged in
if [ -d "/Volumes/ROSE-REC1" ] || [ -d "/Volumes/ROSE-REC2" ]; then
    echo ""
    echo "Device detected — running scan now. It will verify previously"
    echo "uploaded RECORD files and clean them off the device, plus"
    echo "upload anything new into day folders. May take a few minutes..."
    bash "$HOME/Scripts/rose_rec_watcher.sh"
    echo ""
    echo "Scan complete. Last log lines:"
    tail -8 "$HOME/Library/Logs/rose_rec_watcher.log"
fi

echo ""
echo "=============================================="
echo " DONE! v5 active: RECORD-only scan, day-folder"
echo " grouping in Drive Inbox, verified upload +"
echo " auto-delete, single launch agent."
echo " Your root-level files are never touched."
echo " Log: ~/Library/Logs/rose_rec_watcher.log"
echo "=============================================="
