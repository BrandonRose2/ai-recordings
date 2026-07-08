# Recordings Pipeline — State Notes (2026-07-05)

## User & setup
- User: Brandon Rose (Mac username: brandonrose, Google: brandonrose2@gmail.com)
- Two AI recorder devices, mount as volumes: ROSE-REC1 and ROSE-REC2
- Device layout: /Volumes/ROSE-REC2/RECORD/<subfolder>/<file>.WAV (folder is "RECORD", not "Recordings"; junk `._*` files present)
- Mac watcher v3 installed at ~/Scripts/rose_rec_watcher.sh + LaunchAgent com.rose.recwatcher.plist (StartOnMount). Uploads via rclone remote `gdrive` using --drive-root-folder-id (Google Drive desktop app is broken on user's Mac — macOS File Provider error; rclone bypasses it)
- Installer v3 CDN: https://files.manuscdn.com/user_upload_by_module/session_file/310519663449376037/WKgrPuPQffmiBCnD.command

## Google Drive (link-shared, accessed WITHOUT connector via embeddedfolderview/uc endpoints)
- Recordings root folder ID: 1Gxg3gg06CVLO-F05kke5CXvdXgVXSPsP (shared link; NOT in user's My Drive, not in shared-with-me list; accessible by ID)
- Subfolder IDs:
  - Inbox: 1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9
  - Calls: 1Cx4xR5JV0kr8iyLCd3CdKAqPhPYGxWU3
  - Marc's Inappropriate Screaming: 1PKwWvR4NbUwucn_Wp6RYcP_oJV7HSmiP
  - Meetings: 1Kg98rGEhxKKdCUEAjiEadYeKdhkajPO_
  - Other: 1vIdE78TJrPDIb9tI7N1uotgfNH1T75sH
  - Personal Notes: 1Bw1F45StcpM8UPm6vMc14Q5pFZ_18oI7
- Existing processed file in Marc's folder: "Marc Screaming at Ethan - 2026-06-24.m4a" (ID 11F2aQMYSk1KUuHcO_s0U7ipgtNb198Kq) + summary MD (ID 16dWSHvkobrPzYidmHQf6LoskOm8O7bN2). Summary says 34m51.5s, yelling at 9:05 highlighted.
- User's My Drive also has a "Recordings Vault" folder created 2026-07-05 (user hasn't clarified its purpose).

## Scheduled automation
- Manus schedule created: cron "0 0 8,12,16,20 * * *" (4x daily PT), re-triggers this task, follows ~/recordings_pipeline/PROCESSING_PLAYBOOK.md
- Scanner: ~/recordings_pipeline/drive_scan.py (list/download new inbox audio; --mark-done <id> to mark processed in processed_state.json)
- Profiles registry: ~/recordings_pipeline/profiles.json (Marc = boss, folder = Marc's Inappropriate Screaming; Ethan = co-worker; sorting rules for Calls/Meetings/Personal Notes/Other)

## Current batch (uploads from ROSE-REC2 in Inbox as of 10:25 PT)
- 13H-vq2Zx41gR9oFKuGz1CSM8yiSt0C7U | ROSE-REC2_06-23-2026_06-23-2026.WAV
- 1N92Xo-nnqDa5gdP-EreAkYU22srrEFEZ | ROSE-REC2_06-23-2026_Save.WAV
- 13by0yDNJfbejTF9EsuNuFGn1JTVVt-pA | ROSE-REC2_06-23-2026_V2025-12-26-12-33-52.WAV
- Still expected (seen on device): "Ethan Company Mail Error.WAV" (06-23-2026 subfolder), Tuesday/V2026-06-30-23-18-06.WAV, Tuesday/V2026-06-29-23-55-53.WAV, Tuesday/V2026-06-30-00-58-56.WAV, possibly root-level V2025-12-27-*.WAV files
- User wants: transcribe, summarize, speaker dialogue, sort by profiles; build Marc's profile (yelling at Ethan at 9:05 — likely the existing m4a or "Ethan Company Mail Error.WAV")

## Constraints
- Drive access is READ-ONLY from sandbox (share link). Cannot move files between Drive folders; reports must instruct user where to file, and deliver files as attachments.
- Marc recording context: boss Marc yells at co-worker Ethan at minute 9:05 (user's words).
