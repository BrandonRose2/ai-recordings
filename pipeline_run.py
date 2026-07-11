#!/usr/bin/env python3
"""
pipeline_run.py — Recordings Pipeline: Scan → Download → Auto-File

Replaces the manual drive_filer.py workflow. On every run:
  1. Scans the Drive Inbox for new audio files (not in processed_state.json)
  2. Downloads them to ~/recordings_pipeline/downloads/
  3. After Manus analysis assigns a destination, calls file_recording() to
     move the Drive file to the correct folder via the service account.
  4. Marks the file as processed in processed_state.json.

Usage:
  python3 pipeline_run.py                  # scan + download new files
  python3 pipeline_run.py --file-done <drive_file_id> <dest_folder_key>
                                           # move one file to its folder
  python3 pipeline_run.py --mark-done <drive_file_id> [...]
                                           # mark IDs as processed (no move)

Destination folder keys (case-insensitive):
  Ethan, Gerald, Momma Rose, Robert, Santiago, Marc, Meetings,
  Calls, Personal Notes, Other
"""

import json
import os
import re
import subprocess
import sys
import time

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# ── Paths ──────────────────────────────────────────────────────────────────
BASE_DIR     = os.path.expanduser("~/recordings_pipeline")
DOWNLOAD_DIR = os.path.join(BASE_DIR, "downloads")
STATE_FILE   = os.path.join(BASE_DIR, "processed_state.json")
KEY_FILE     = os.path.join(BASE_DIR, "service_account.json")

# ── Drive folder IDs ───────────────────────────────────────────────────────
INBOX_FOLDER_ID = "1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9"

FOLDER_IDS = {
    "ethan":          "18rfNjyj7XaC7E7fHR6u3JFj1Qq1_o4St",
    "gerald":         "1fIUVHUWlTUChkJLlj5K-XrPHPm5wn9qP",
    "momma rose":     "1pBStehwj76jQLLf8XUBCq4UXC2dgiaUM",
    "robert":         "190AXqzaI667pi2Dn73SS6EYCMG5fSvj9",
    "santiago":       "1Vnb8sQBJv1iy_Zdk_Nwyn4ajr1WVkS3s",
    "marc":           "1PKwWvR4NbUwucn_Wp6RYcP_oJV7HSmiP",
    "meetings":       "1Kg98rGEhxKKdCUEAjiEadYeKdhkajPO_",
    "calls":          "1Cx4xR5JV0kr8iyLCd3CdKAqPhPYGxWU3",
    "personal notes": "1Bw1F45StcpM8UPm6vMc14Q5pFZ_18oI7",
    "other":          "1vIdE78TJrPDIb9tI7N1uotgfNH1T75sH",
}

AUDIO_EXTENSIONS = (
    ".m4a", ".mp3", ".wav", ".mp4", ".webm",
    ".aac", ".flac", ".ogg", ".opus", ".wma", ".amr"
)


# ── Service account Drive client ───────────────────────────────────────────
def get_drive_service():
    creds = service_account.Credentials.from_service_account_file(
        KEY_FILE, scopes=["https://www.googleapis.com/auth/drive"]
    )
    return build("drive", "v3", credentials=creds, cache_discovery=False)


# ── State helpers ──────────────────────────────────────────────────────────
def load_state() -> dict:
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"processed_ids": [], "known_files": {}}


def save_state(state: dict) -> None:
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def mark_done(file_id: str, filename: str) -> None:
    state = load_state()
    ids = set(state.get("processed_ids", []))
    ids.add(file_id)
    state["processed_ids"] = sorted(ids)
    kf = state.setdefault("known_files", {})
    kf[file_id] = filename
    save_state(state)


# ── Drive helpers ──────────────────────────────────────────────────────────
def list_folder_api(svc, folder_id: str) -> list[dict]:
    """Return all files/folders in a Drive folder (handles pagination)."""
    items = []
    page_token = None
    while True:
        params = dict(
            q=f"'{folder_id}' in parents and trashed=false",
            fields="nextPageToken,files(id,name,mimeType,size)",
            pageSize=100,
        )
        if page_token:
            params["pageToken"] = page_token
        r = svc.files().list(**params).execute()
        items.extend(r.get("files", []))
        page_token = r.get("nextPageToken")
        if not page_token:
            break
    return items


def move_file(svc, file_id: str, dest_folder_id: str) -> None:
    """Move a Drive file to dest_folder_id (removes from all current parents)."""
    f = svc.files().get(fileId=file_id, fields="parents,name").execute()
    prev = ",".join(f.get("parents", []))
    for attempt in range(4):
        try:
            svc.files().update(
                fileId=file_id,
                addParents=dest_folder_id,
                removeParents=prev,
                fields="id,parents",
            ).execute()
            return
        except HttpError as e:
            if attempt == 3:
                raise
            wait = 15 * (attempt + 1)
            print(f"  HttpError on move (attempt {attempt+1}): {e}; retrying in {wait}s",
                  file=sys.stderr)
            time.sleep(wait)


def find_file_by_id(svc, file_id: str) -> dict | None:
    """Return file metadata dict or None if not found."""
    try:
        return svc.files().get(fileId=file_id, fields="id,name,parents").execute()
    except HttpError:
        return None


# ── Download helper (curl with retry) ─────────────────────────────────────
def download_file_api(svc, file_id: str, filename: str) -> str:
    """Download a Drive file using the API (service account auth)."""
    import io
    from googleapiclient.http import MediaIoBaseDownload

    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    safe_name = re.sub(r"[^\w\-. ']", "_", filename)
    out_path = os.path.join(DOWNLOAD_DIR, safe_name)

    for attempt in range(4):
        try:
            request = svc.files().get_media(fileId=file_id)
            with open(out_path, "wb") as fh:
                downloader = MediaIoBaseDownload(fh, request, chunksize=8 * 1024 * 1024)
                done = False
                while not done:
                    _, done = downloader.next_chunk()
            return out_path
        except Exception as e:
            if attempt == 3:
                raise
            wait = 30 * (attempt + 1)
            print(f"  Download failed (attempt {attempt+1}): {e}; retrying in {wait}s",
                  file=sys.stderr)
            time.sleep(wait)


# ── Main scan + download ───────────────────────────────────────────────────
def scan_and_download() -> dict:
    """Scan Inbox for new files, download them. Returns report dict."""
    svc = get_drive_service()
    state = load_state()
    processed = set(state.get("processed_ids", []))

    new_files = []
    inbox_items = list_folder_api(svc, INBOX_FOLDER_ID)
    for item in inbox_items:
        if item["mimeType"] == "application/vnd.google-apps.folder":
            # Day subfolder (e.g. "Monday 07-07-2026")
            for sub in list_folder_api(svc, item["id"]):
                if sub["mimeType"] == "application/vnd.google-apps.folder":
                    continue
                if not sub["name"].lower().endswith(AUDIO_EXTENSIONS):
                    continue
                if sub["id"] not in processed:
                    new_files.append({**sub, "day_folder": item["name"]})
        else:
            if not item["name"].lower().endswith(AUDIO_EXTENSIONS):
                continue
            if item["id"] not in processed:
                new_files.append({**item, "day_folder": "Inbox (root)"})

    report = {"new_files_found": len(new_files), "downloaded": [], "errors": []}

    for f in new_files:
        print(f"Downloading: {f['name']} ({int(f.get('size',0))//1024//1024} MB)")
        try:
            path = download_file_api(svc, f["id"], f["name"])
            report["downloaded"].append({
                "name": f["name"],
                "id": f["id"],
                "path": path,
                "day_folder": f["day_folder"],
                "size_bytes": f.get("size", 0),
            })
            print(f"  -> {path}")
        except Exception as exc:
            report["errors"].append({"name": f["name"], "id": f["id"], "error": str(exc)})
            print(f"  ERROR: {exc}", file=sys.stderr)

    return report


# ── File a single recording to its destination ────────────────────────────
def file_recording(drive_file_id: str, dest_key: str) -> bool:
    """
    Move drive_file_id to the folder named by dest_key (case-insensitive).
    Returns True on success, False on failure.
    Marks the file as processed in processed_state.json on success.
    """
    key = dest_key.strip().lower()
    dest_folder_id = FOLDER_IDS.get(key)
    if not dest_folder_id:
        print(f"ERROR: Unknown destination key '{dest_key}'. Valid keys: {list(FOLDER_IDS)}")
        return False

    svc = get_drive_service()
    meta = find_file_by_id(svc, drive_file_id)
    if not meta:
        print(f"ERROR: File ID '{drive_file_id}' not found in Drive.")
        return False

    filename = meta["name"]
    try:
        move_file(svc, drive_file_id, dest_folder_id)
        mark_done(drive_file_id, filename)
        print(f"FILED: {filename} -> {dest_key}  (ID: {drive_file_id})")
        return True
    except HttpError as e:
        print(f"ERROR moving {filename}: {e}")
        return False


# ── Batch file from JSON manifest ─────────────────────────────────────────
def file_from_manifest(manifest: list[dict]) -> None:
    """
    manifest: list of {"id": "<drive_id>", "dest": "<folder_key>"} dicts.
    Moves each file and marks it done.
    """
    ok, fail = 0, 0
    for item in manifest:
        success = file_recording(item["id"], item["dest"])
        if success:
            ok += 1
        else:
            fail += 1
    print(f"\nFiling complete: {ok} moved, {fail} failed")


# ── Entry point ───────────────────────────────────────────────────────────
if __name__ == "__main__":
    args = sys.argv[1:]

    if not args:
        # Default: scan + download
        report = scan_and_download()
        print(json.dumps(report, indent=2))

    elif args[0] == "--file-done" and len(args) == 3:
        # Move one file and mark done: --file-done <drive_id> <dest_key>
        success = file_recording(args[1], args[2])
        sys.exit(0 if success else 1)

    elif args[0] == "--file-manifest" and len(args) == 2:
        # Read a JSON file with list of {id, dest} and file all
        with open(args[1]) as f:
            manifest = json.load(f)
        file_from_manifest(manifest)

    elif args[0] == "--mark-done":
        # Just mark IDs as processed (no move)
        state = load_state()
        ids = set(state.get("processed_ids", []))
        ids.update(args[1:])
        state["processed_ids"] = sorted(ids)
        save_state(state)
        print(f"Marked {len(args) - 1} file(s) as processed")

    else:
        print(__doc__)
        sys.exit(1)
