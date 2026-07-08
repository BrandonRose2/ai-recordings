# Watcher v5 State — 2026-07-06

## User requirement (July 6, ~12:30 PT)
- Watcher must scan ONLY the RECORD folder on the device (user manually groups/renames files at volume root as an archive — must never be touched/uploaded/deleted).
- Auto-delete (verified upload then delete) only inside RECORD.
- Keep: mount-settle delay + retry, duplicate agent removal (com.user.roserec.sync leftover), notifications (start/finish/errors), lock file.
- If RECORD not found after settle: log warning, do nothing (no whole-volume fallback).

## Diagnosis history (July 6)
- 12:16 run failed to find RECORD due to mount race -> logged "no RECORD-style folder; scanning entire volume" -> 0 new files.
- 8am run uploaded 45 files including root-level December files (whole-volume fallback grabbed user's archive).
- One failed upload queued for retry: V2026-07-03-01-19-52.WAV (bad file descriptor mid-upload).
- Two launch agents present: com.rose.recwatcher (ours) + com.user.roserec.sync (leftover; must remove).
- Device layout (Finder screenshot): volume root has MRECSET.TXT, RECORD/ (with 06-23-2026, Monday, Tuesday subfolders), plus user's root-level V2025-12-*.WAV archive files.
- User confirmed: root-level files are their curated archive; already processed in Drive (batch 3); leave as-is on device.

## Current file versions
- v5 (whole-volume scan) written at ~/recordings_pipeline/mac_setup/install_rose_rec_v5.command and uploaded to:
  https://files.manuscdn.com/user_upload_by_module/session_file/310519663449376037/epRABgaaXksyqIGI.command
  -> OBSOLETE per user requirement; must rewrite as RECORD-only and re-upload.
- v4 at mac_setup/install_rose_rec_v4.command (RECORD-first with whole-volume fallback + auto-delete).

## Key IDs
- Inbox folder ID: 1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9
- Recordings root folder ID: 1Gxg3gg06CVLO-F05kke5CXvdXgVXSPsP
- Folder map: Calls=1Cx4xR5JV0kr8iyLCd3CdKAqPhPYGxWU3, Marc's=1PKwWvR4NbUwucn_Wp6RYcP_oJV7HSmiP, Meetings=1Kg98rGEhxKKdCUEAjiEadYeKdhkajPO_, Other=1vIdE78TJrPDIb9tI7N1uotgfNH1T75sH, Personal Notes=1Bw1F45StcpM8UPm6vMc14Q5pFZ_18oI7
- Inbox currently has 77 files, all processed (batches 1-3, 45 in batch 3 report reports/Batch_Report_2026-07-06_Batch3.md).

## Next steps
1. Rewrite install_rose_rec_v5.command: RECORD-only scan (find RECORD folder with settle retry; abort device if absent).
2. bash -n check, upload via manus-upload-file, send one-liner to user.
3. User runs it; confirm via log output; device RECORD files get cleaned after verification.
4. Failed file V2026-07-03-01-19-52.WAV should retry on next run (it is in RECORD folder presumably).
