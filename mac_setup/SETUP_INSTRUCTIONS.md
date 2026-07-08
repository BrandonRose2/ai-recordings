# ROSE-REC Recordings Automation — Mac Setup Guide

This one-time setup makes your Mac automatically copy new recordings from **ROSE-REC1** and **ROSE-REC2** into your Google Drive `Recordings/Inbox` folder whenever you plug either device in. From there, the cloud automation takes over: it transcribes, summarizes, identifies speakers, and sorts each recording into the right profile folder.

## How the Whole Pipeline Works

| Step | Where it runs | What happens |
| --- | --- | --- |
| 1. Plug in device | Your Mac | ROSE-REC1 or ROSE-REC2 mounts in Finder |
| 2. Auto-copy | Your Mac (watcher script) | New files in the device's `Recordings` folder are copied to Google Drive `Recordings/Inbox` (prefixed with the device name; duplicates skipped) |
| 3. Sync | Google Drive for desktop | The Inbox syncs to the cloud |
| 4. Detect & process | Manus (scheduled automation) | New audio in the Inbox is downloaded, transcribed, summarized, and a speaker dialogue is produced |
| 5. Sort | Manus | The recording and its summary are filed into the matching profile folder (e.g., "Marc's Inappropriate Screaming"), and you get a report |

## Prerequisites

1. **Google Drive for desktop** installed and signed in to the Google account that owns the `Recordings` folder.
2. The `Recordings` folder (with its `Inbox` subfolder) visible in your synced My Drive.

## Installation Steps

### Step 1 — Place the watcher script

```bash
mkdir -p ~/Scripts
cp rose_rec_watcher.sh ~/Scripts/
chmod +x ~/Scripts/rose_rec_watcher.sh
```

### Step 2 — Check the Google Drive path

Open `~/Scripts/rose_rec_watcher.sh` in a text editor and confirm the `GDRIVE_INBOX` path matches your Mac. For most modern Google Drive installs the default (already set) works:

```
$HOME/Library/CloudStorage/GoogleDrive-<your email>/My Drive/Recordings/Inbox
```

You can verify your actual path by running:

```bash
ls ~/Library/CloudStorage/
```

### Step 3 — Install the Launch Agent (auto-run on device plug-in)

1. Open `com.rose.recwatcher.plist` in a text editor and replace `REPLACE_WITH_YOUR_USERNAME` with your macOS username (run `whoami` in Terminal if unsure).
2. Install it:

```bash
cp com.rose.recwatcher.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.rose.recwatcher.plist
```

The `StartOnMount` key makes macOS run the watcher every time any volume mounts — i.e., the moment ROSE-REC1 or ROSE-REC2 appears in Finder. The script checks for your two devices specifically and exits quietly otherwise.

### Step 4 — Test it

1. Plug in ROSE-REC1 (or ROSE-REC2).
2. Within a few seconds you should see a macOS notification: *"N new recording(s) sent to Google Drive Inbox."*
3. Check the `Recordings/Inbox` folder in Google Drive — the new files should appear there, prefixed with the device name (e.g., `ROSE-REC1_meeting.m4a`).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No notification when device plugged in | Run `bash ~/Scripts/rose_rec_watcher.sh` manually and check `~/Library/Logs/rose_rec_watcher.log` |
| "Could not find Google Drive Recordings/Inbox" in the log | Google Drive for desktop isn't running, or the path in the script needs editing (Step 2) |
| Files copied twice | Shouldn't happen — the script fingerprints each file (device + name + size) in `~/.rose_rec_copied.log` |
| Want to re-copy everything | Delete `~/.rose_rec_copied.log` |
| macOS blocks the script | System Settings → Privacy & Security → Full Disk Access → add `bash` or grant permission when prompted |

## Notes

- Both devices are treated **identically** — same folders, same rules.
- Files are **copied**, never deleted from your devices.
- The cloud side checks the Inbox on a schedule; new recordings are processed automatically and filed into your profile folders, and a report is sent to you in Manus.
