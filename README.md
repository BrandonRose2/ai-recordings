# AI Recordings Pipeline

Automation that recognizes ROSE-REC recording devices, uploads recordings to Google Drive, transcribes and summarizes the dialogue, matches speakers against known voice profiles, and sorts recordings into Drive folders.

## How It Works

The system has two halves: a **Mac-side watcher** that moves audio off the recording devices into Google Drive, and a **processing pipeline** (run by Manus on a schedule) that transcribes, analyzes, and sorts everything that lands in the Drive Inbox.

| Stage | Component | What It Does |
|-------|-----------|--------------|
| 1. Capture | ROSE-REC1 / ROSE-REC2 devices | Voice recorders; store WAV files in a `RECORD`/`RECORDED`/`RECORDINGS` folder. |
| 2. Upload | `mac_setup/` watcher (v5.2) | On device plug-in: scans only the recordings folder, uploads new files into day-named folders in the Drive `Recordings/Inbox`, verifies each upload, then deletes from device. |
| 3. Detect | `drive_scan.py` | Scans the link-shared Drive Inbox for new audio files; downloads them; tracks processed state in `processed_state.json`. |
| 4. Repair | `fix_downloads.py` | Re-downloads any files that came through as Google virus-scan stub pages. |
| 5. Transcribe | `manus-speech-to-text` | Produces timestamped transcripts. |
| 6. Analyze & Sort | `PROCESSING_PLAYBOOK.md` + `profiles.json` | Speaker matching against voice profiles (Marc, Ethan, Gerald, Momma Rose, etc.), summary + notable moments report, destination folder decision. |
| 7. Report | `reports/` | Batch reports with filing instructions delivered to Brandon. |

## Key Files

- **`PROCESSING_PLAYBOOK.md`** — the full processing procedure: screening, transcription, speaker matching, custom summary formats (e.g., Gerald's business/AI session format), sorting rules, and state management.
- **`profiles.json`** — voice profiles and folder routing. Includes voice characteristics, speech patterns, behavioral evidence, known interactions, and Drive folder IDs for each person.
- **`drive_scan.py`** — Drive Inbox scanner/downloader with retry logic (no OAuth needed; uses the link-shared folder view).
- **`fix_downloads.py`** — repairs virus-scan stub downloads.
- **`mac_setup/`** — Mac installers: the v5.x watcher (auto-upload on plug-in) and the "Execute AI Recording Watcher" one-click app.
- **`reports/`** — all delivered batch reports and transcripts.
- **`transcripts/` and `downloads/*.txt`** — timestamped transcripts (audio files themselves are excluded from the repo; originals live in Google Drive).

## Drive Folder Structure

```
Recordings/
├── Inbox/               ← watcher uploads land here in day folders
├── Calls/
├── Meetings/
├── Personal Notes/
├── Gerald/              ← Brandon + Gerald business/AI sessions
├── Momma Rose/          ← calls with Brandon's mom
├── Marc's Inappropriate Screaming/
└── Other/
```

## Mac Watcher (v5.2)

Installed via `mac_setup/install_rose_rec_v5_2.command`. Features: recordings-folder-only scanning (never touches root files), accepts `RECORD`/`RECORDED`/`RECORDINGS` folder names, direct-path folder detection (immune to mount-settling quirks), day-folder grouping, verified upload-then-delete, single launch agent, Mac notifications. The one-click manual trigger app is installed via `mac_setup/install_watcher_app.command`.

## Note

Audio files (WAV/mp3) are excluded from this repository via `.gitignore` — they total 20+ GB and the originals are preserved in Google Drive.
