# Recordings Processing Playbook

This playbook defines the automated pipeline for ROSE-REC1 and ROSE-REC2 recordings.

## Current Mode: Auto-File Only (no transcription)

The pipeline detects new recordings, copies them to **To Review**, archives the originals, and marks them done. No transcription or analysis is performed automatically. Manual review and sorting happens from the **To Review** folder.

---

## Step 1 — Run the pipeline

```bash
python3 ~/recordings_pipeline/pipeline_run.py
```

What it does:
1. Scans the Google Drive **Inbox** folder for new audio files not yet in `processed_state.json`
2. Copies each new file to the **To Review** folder (`1ULntCgzv9tY7l7_k5jF-_vmqQgfc087g`)
3. Moves the original from **Inbox** to **Archived** (`1JCRAH2gaJOo968MZElpMFjmR3Ky07MQR`) — clears the device sync folder
4. Marks the file as processed in `processed_state.json`

Dry-run (no changes):
```bash
python3 ~/recordings_pipeline/pipeline_run.py --dry-run
```

Mark files as processed without moving (e.g. already manually handled):
```bash
python3 ~/recordings_pipeline/pipeline_run.py --mark-done <drive_file_id> [...]
```

---

## Step 2 — Manual review

Open the **To Review** folder in Google Drive and sort files into the appropriate destination folders:

| Destination | Contents |
|-------------|---------|
| Gerald | One-on-one Brandon + Gerald calls (business ideas, AI coaching) |
| Ethan | One-on-one Brandon + Ethan conversations |
| Momma Rose | Brandon + Momma Rose calls |
| Robert | One-on-one Brandon + Robert conversations |
| Santiago | One-on-one Brandon + Santiago conversations |
| Marc's Inappropriate Screaming | Marc yelling/inappropriate behavior |
| Meetings | Multi-person work discussions |
| Calls | Phone calls (one side audible) |
| Personal Notes | Solo memos, personal conversations |
| Other | Silent, ambient, music-only (candidates for deletion) |

---

## Step 3 — On-demand transcription (when needed)

When a recording needs a full report, run manually:

```bash
# Convert to MP3 if needed
ffmpeg -i ~/recordings_pipeline/downloads/<file>.WAV -ar 16000 /tmp/file.mp3

# Transcribe
manus-speech-to-text /tmp/file.mp3
```

Then follow the analysis format in `profiles.json`:
- Standard report: summary + speaker-labeled dialogue + notable moments
- Gerald recordings: add Business Ideas / Action Items / Research Reminders / AI Lessons Covered sections

---

## Drive Folder IDs (reference)

| Folder | ID |
|--------|----|
| Inbox | `1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9` |
| To Review | `1ULntCgzv9tY7l7_k5jF-_vmqQgfc087g` |
| Archived | `1JCRAH2gaJOo968MZElpMFjmR3Ky07MQR` |
| Gerald | `1fIUVHUWlTUChkJLlj5K-XrPHPm5wn9qP` |
| Ethan | `18rfNjyj7XaC7E7fHR6u3JFj1Qq1_o4St` |
| Momma Rose | `1pBStehwj76jQLLf8XUBCq4UXC2dgiaUM` |
| Robert | `190AXqzaI667pi2Dn73SS6EYCMG5fSvj9` |
| Santiago | `1Vnb8sQBJv1iy_Zdk_Nwyn4ajr1WVkS3s` |
| Marc's Inappropriate Screaming | `1PKwWvR4NbUwucn_Wp6RYcP_oJV7HSmiP` |
| Meetings | `1Kg98rGEhxKKdCUEAjiEadYeKdhkajPO_` |
| Calls | `1Cx4xR5JV0kr8iyLCd3CdKAqPhPYGxWU3` |
| Personal Notes | `1Bw1F45StcpM8UPm6vMc14Q5pFZ_18oI7` |
| Other | `1vIdE78TJrPDIb9tI7N1uotgfNH1T75sH` |

---

## Notes

- `processed_state.json` tracks all Drive file IDs that have been handled. Files in this list are never re-processed.
- The service account (`service_account.json`) is required for file move/copy operations. The Inbox scan uses the public folder link and does not require auth.
- ROSE-REC2 device clock is stamped as 2076 — actual year is 2026. Subtract 50 years from the filename timestamp.
- Santiago voice reference: `ROSE-REC2_V2076-06-09-08-39-23.WAV` (2026-07-09 ~8:39 AM).
- Gerald voice reference: `ROSE-REC2_V2076-06-08-18-47-11.WAV` (2026-07-08 ~6:47 PM). Confirmed by Brandon 2026-07-11.
