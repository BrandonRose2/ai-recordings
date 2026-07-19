#!/usr/bin/env python3
"""
pipeline_run.py — Recordings Pipeline (Simplified: Detect → File → Archive)
-----------------------------------------------------------------------------
On every run:
  1. Scans the Drive Inbox for new audio files (not in processed_state.json)
  2. Copies each new file into the "To Review" folder (your review queue)
  3. Moves the original from Inbox to "Archived" (clears the device sync folder)
  4. Marks the file as processed in processed_state.json

No transcription, no analysis, no reports.
Manual review and sorting happens separately from the "To Review" folder.

Usage:
  python3 pipeline_run.py            # scan + file + archive new files
  python3 pipeline_run.py --dry-run  # show what would be moved, no changes
  python3 pipeline_run.py --mark-done <drive_file_id> [...]
                                     # mark IDs as processed without moving
"""

import html as htmllib
import json
import os
import re
import subprocess
import sys
import time

# ── Paths ──────────────────────────────────────────────────────────────────
BASE_DIR   = os.path.expanduser("~/recordings_pipeline")
STATE_FILE = os.path.join(BASE_DIR, "processed_state.json")
KEY_FILE   = os.path.join(BASE_DIR, "service_account.json")

# ── Drive folder IDs ───────────────────────────────────────────────────────
INBOX_FOLDER_ID     = "1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9"
TO_REVIEW_FOLDER_ID = "1ULntCgzv9tY7l7_k5jF-_vmqQgfc087g"
ARCHIVED_FOLDER_ID  = "1JCRAH2gaJOo968MZElpMFjmR3Ky07MQR"

AUDIO_EXTENSIONS = (
    ".m4a", ".mp3", ".wav", ".mp4", ".webm",
    ".aac", ".flac", ".ogg", ".opus", ".wma", ".amr"
)

# ── State helpers ──────────────────────────────────────────────────────────
def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"processed_ids": []}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

# ── Drive folder listing (public link, no auth needed for scanning) ─────────
def list_folder_public(folder_id):
    """Return list of {id, name, is_folder} from a link-shared Drive folder."""
    try:
        result = subprocess.run(
            ["curl", "-sL", "--max-time", "30",
             f"https://drive.google.com/embeddedfolderview?id={folder_id}"],
            capture_output=True, text=True, check=True
        )
        page = result.stdout
    except subprocess.CalledProcessError:
        return []

    entries = []
    for m in re.finditer(
        r'flip-entry" id="entry-([^"]+)"(.*?)flip-entry-title">([^<]*)', page, re.S
    ):
        eid, body, title = m.group(1), m.group(2), m.group(3)
        name = htmllib.unescape(title).strip()
        is_folder = f"/drive/folders/{eid}" in page
        entries.append({"id": eid, "name": name, "is_folder": is_folder})
    return entries

# ── Drive service (service account) ───────────────────────────────────────
def get_drive_service():
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        creds = service_account.Credentials.from_service_account_file(
            KEY_FILE, scopes=["https://www.googleapis.com/auth/drive"]
        )
        return build("drive", "v3", credentials=creds, cache_discovery=False)
    except Exception as e:
        print(f"[WARN] Service account unavailable: {e}", file=sys.stderr)
        return None

def copy_file(svc, file_id, dest_parent):
    """Copy a file into dest_parent (original stays in place)."""
    from googleapiclient.errors import HttpError
    for attempt in range(4):
        try:
            svc.files().copy(
                fileId=file_id,
                body={"parents": [dest_parent]},
                fields="id"
            ).execute()
            return
        except HttpError as e:
            if attempt == 3:
                raise
            time.sleep(15 * (attempt + 1))

def move_file(svc, file_id, add_parent, remove_parent):
    """Move file to add_parent, removing from remove_parent."""
    from googleapiclient.errors import HttpError
    for attempt in range(4):
        try:
            svc.files().update(
                fileId=file_id,
                addParents=add_parent,
                removeParents=remove_parent,
                fields="id,parents"
            ).execute()
            return
        except HttpError as e:
            if attempt == 3:
                raise
            time.sleep(15 * (attempt + 1))

# ── Main ───────────────────────────────────────────────────────────────────
def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args

    # --mark-done mode
    if args and args[0] == "--mark-done":
        state = load_state()
        ids = set(state.get("processed_ids", []))
        ids.update(args[1:])
        state["processed_ids"] = sorted(ids)
        save_state(state)
        print(f"Marked {len(args) - 1} file(s) as processed.")
        return

    state = load_state()
    processed = set(state.get("processed_ids", []))

    # 1. Scan Inbox
    print("Scanning Drive Inbox...", flush=True)
    entries = list_folder_public(INBOX_FOLDER_ID)
    audio = [
        e for e in entries
        if not e["is_folder"] and e["name"].lower().endswith(AUDIO_EXTENSIONS)
    ]
    new_files = [e for e in audio if e["id"] not in processed]

    print(f"  Inbox audio files : {len(audio)}")
    print(f"  Already processed : {len(processed)}")
    print(f"  New files found   : {len(new_files)}")

    if not new_files:
        print("Inbox is clear — nothing to do.")
        return

    # 2. Get Drive service for file operations
    svc = None if dry_run else get_drive_service()

    # 3. Process each new file
    filed = 0
    failed = 0
    for f in sorted(new_files, key=lambda x: x["name"]):
        name, fid = f["name"], f["id"]
        print(f"\n  → {name}")

        if dry_run:
            print(f"    [DRY RUN] Would copy to 'To Review' + move to 'Archived'")
            continue

        if svc is None:
            print(f"    [SKIP] No Drive service available (service_account.json missing)")
            failed += 1
            continue

        try:
            # Copy to "To Review" so you can review it there
            copy_file(svc, fid, TO_REVIEW_FOLDER_ID)
            print(f"    ✓ Copied  → To Review")

            # Move original from Inbox to "Archived" (clears the device sync)
            move_file(svc, fid, ARCHIVED_FOLDER_ID, INBOX_FOLDER_ID)
            print(f"    ✓ Archived → Archived")

            # Mark done
            state["processed_ids"].append(fid)
            save_state(state)
            filed += 1

        except Exception as e:
            print(f"    [ERROR] {e}")
            failed += 1

    print(f"\nDone: {filed} filed to 'To Review', {failed} failed.")

if __name__ == "__main__":
    main()
