#!/usr/bin/env python3
"""
Recordings Pipeline - Google Drive folder scanner.

Scans the link-shared Google Drive "Recordings" root folder (and its Inbox
subfolder) for new audio files that have not yet been processed, and downloads
them into ~/recordings_pipeline/downloads/ for transcription and analysis.

Works WITHOUT the Google Drive connector by using the public link-shared
endpoints:
  - Folder listing: https://drive.google.com/embeddedfolderview?id=<FOLDER_ID>
  - File download:  https://drive.google.com/uc?export=download&id=<FILE_ID>

State (already-processed file IDs) is tracked in processed_state.json.
"""

import html as htmllib
import json
import os
import re
import subprocess
import sys

ROOT_FOLDER_ID = "1Gxg3gg06CVLO-F05kke5CXvdXgVXSPsP"  # "Recordings" root
BASE_DIR = os.path.expanduser("~/recordings_pipeline")
DOWNLOAD_DIR = os.path.join(BASE_DIR, "downloads")
STATE_FILE = os.path.join(BASE_DIR, "processed_state.json")

AUDIO_EXTENSIONS = (".m4a", ".mp3", ".wav", ".mp4", ".webm", ".aac", ".flac", ".ogg", ".opus", ".wma", ".amr")

# Folders whose direct audio contents count as "new/unprocessed" input.
# The root folder itself and the Inbox subfolder are scanned for new files.
INBOX_FOLDER_NAMES = {"inbox"}


def curl(url: str, out_path: str | None = None, max_time: int = 120, retries: int = 4) -> str:
    """curl with retry/backoff: Drive connections sometimes stall (transient
    throttling of the sandbox egress IP). Retry with increasing waits."""
    import time as _time
    cmd = ["curl", "-sL", "--max-time", str(max_time), url]
    last_err = None
    for attempt in range(retries):
        try:
            if out_path:
                subprocess.run(cmd + ["-o", out_path], check=True)
                return out_path
            result = subprocess.run(cmd, check=True, capture_output=True, text=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            last_err = e
            wait = 30 * (attempt + 1)
            print(f"curl failed (exit {e.returncode}) for {url[:80]}; retry {attempt+1}/{retries} in {wait}s", file=sys.stderr)
            _time.sleep(wait)
    raise last_err


def list_folder(folder_id: str) -> list[dict]:
    """Return [{'id':..., 'name':..., 'is_folder':bool}] for a shared folder."""
    page = curl(f"https://drive.google.com/embeddedfolderview?id={folder_id}", max_time=30)
    entries = []
    for m in re.finditer(
        r'flip-entry" id="entry-([^"]+)"(.*?)flip-entry-title">([^<]*)', page, re.S
    ):
        eid, body, title = m.group(1), m.group(2), m.group(3)
        name = htmllib.unescape(title).strip()
        is_folder = "folders" in body or "folder" in body.lower()
        # More reliable folder detection: folder entries link to /drive/folders/
        is_folder = f"/drive/folders/{eid}" in page
        entries.append({"id": eid, "name": name, "is_folder": is_folder})
    return entries


def load_state() -> dict:
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"processed_ids": [], "known_files": {}}


def save_state(state: dict) -> None:
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def download_file(file_id: str, name: str) -> str:
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    safe_name = re.sub(r"[^\w\-. ']", "_", name)
    out_path = os.path.join(DOWNLOAD_DIR, safe_name)
    curl(f"https://drive.google.com/uc?export=download&id={file_id}", out_path, max_time=600)
    return out_path


def main() -> None:
    state = load_state()
    processed = set(state.get("processed_ids", []))

    root_entries = list_folder(ROOT_FOLDER_ID)
    scan_targets = [("(root)", ROOT_FOLDER_ID)]
    folder_map = {}
    for e in root_entries:
        if e["is_folder"]:
            folder_map[e["name"]] = e["id"]
            if e["name"].strip().lower() in INBOX_FOLDER_NAMES:
                scan_targets.append((e["name"], e["id"]))

    new_files = []
    for label, fid in scan_targets:
        for e in list_folder(fid):
            if e["is_folder"]:
                # v5 watcher groups uploads into day subfolders inside the
                # Inbox (e.g. "Monday 07-06-2026"); recurse one level deep.
                if label != "(root)":
                    for sub in list_folder(e["id"]):
                        if sub["is_folder"]:
                            continue
                        if not sub["name"].lower().endswith(AUDIO_EXTENSIONS):
                            continue
                        if sub["id"] in processed:
                            continue
                        new_files.append({"source_folder": f"{label}/{e['name']}", **sub})
                continue
            if not e["name"].lower().endswith(AUDIO_EXTENSIONS):
                continue
            if e["id"] in processed:
                continue
            new_files.append({"source_folder": label, **e})

    report = {"folder_map": folder_map, "new_files": [], "downloaded": []}
    for f in new_files:
        try:
            path = download_file(f["id"], f["name"])
            report["downloaded"].append({"name": f["name"], "id": f["id"], "path": path, "source_folder": f["source_folder"]})
        except Exception as exc:  # noqa: BLE001
            report["new_files"].append({**f, "error": str(exc)})

    print(json.dumps(report, indent=2))

    # NOTE: caller (the scheduled Manus run) should add IDs to processed_state
    # only AFTER successful transcription + filing, by calling:
    #   python3 drive_scan.py --mark-done <file_id> [...]


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--mark-done":
        st = load_state()
        ids = set(st.get("processed_ids", []))
        ids.update(sys.argv[2:])
        st["processed_ids"] = sorted(ids)
        save_state(st)
        print(f"marked {len(sys.argv) - 2} file(s) as processed")
    else:
        main()
