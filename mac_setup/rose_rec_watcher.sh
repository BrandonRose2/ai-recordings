#!/bin/bash
#
# ROSE-REC Recording Auto-Copy Watcher
# ------------------------------------
# Watches for the ROSE-REC1 and ROSE-REC2 recorder devices to be mounted,
# then copies any NEW files from each device's "Recordings" folder into the
# Google Drive "Recordings/Inbox" folder so the cloud automation can pick
# them up, transcribe, summarize, and sort them into profiles.
#
# Works identically for both devices. Files already copied are remembered in
# ~/.rose_rec_copied.log so nothing is duplicated.
#
# SETUP (one time):
#   1. Make sure Google Drive for desktop is installed and syncing.
#   2. Adjust GDRIVE_INBOX below if your Drive path differs.
#   3. chmod +x rose_rec_watcher.sh
#   4. Install the Launch Agent (see com.rose.recwatcher.plist) so this runs
#      automatically whenever a device is plugged in.

# ====== CONFIG ======
DEVICES=("ROSE-REC1" "ROSE-REC2")

# Path to the synced Google Drive Recordings/Inbox folder.
# Common locations (uncomment / edit the one that matches your Mac):
GDRIVE_INBOX="$HOME/Library/CloudStorage/GoogleDrive-*/My Drive/Recordings/Inbox"
# GDRIVE_INBOX="$HOME/Google Drive/My Drive/Recordings/Inbox"

COPIED_LOG="$HOME/.rose_rec_copied.log"
LOG_FILE="$HOME/Library/Logs/rose_rec_watcher.log"
AUDIO_EXTS=("m4a" "mp3" "wav" "mp4" "aac" "flac" "ogg" "opus" "wma" "amr")
# ====================

touch "$COPIED_LOG"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Resolve the Drive inbox path (handles the wildcard in CloudStorage paths)
resolve_inbox() {
    local resolved
    resolved=$(ls -d $GDRIVE_INBOX 2>/dev/null | head -1)
    if [ -z "$resolved" ]; then
        # Try to create it inside My Drive if the Recordings folder exists
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
    log "ERROR: Could not find Google Drive Recordings/Inbox folder. Is Google Drive for desktop running?"
    exit 1
fi

for DEVICE in "${DEVICES[@]}"; do
    VOLUME="/Volumes/$DEVICE"
    [ -d "$VOLUME" ] || continue

    # Find the Recordings folder on the device (case-insensitive, top 2 levels)
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

            if grep -qF "$FINGERPRINT" "$COPIED_LOG"; then
                continue  # already copied previously
            fi

            # Prefix with device name + date to keep filenames unique & informative
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
