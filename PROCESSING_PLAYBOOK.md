# Recordings Processing Playbook

This playbook defines exactly what to do on every scheduled run of the recordings automation. Both ROSE-REC1 and ROSE-REC2 recordings are treated identically.

## Step 1 — Scan for new recordings

```bash
cd ~/recordings_pipeline && python3 drive_scan.py
```

- Scans the Google Drive `Recordings` root and `Inbox` folder (link-shared, no connector needed).
- Downloads any new audio files (not in `processed_state.json`) to `~/recordings_pipeline/downloads/`.
- If no new files: end the run quietly (send a brief no-op note only if the user asked for run confirmations; otherwise stay silent).

## Step 2 — Transcribe each new recording

```bash
manus-speech-to-text ~/recordings_pipeline/downloads/<file>
```

If the format is unsupported, convert first with ffmpeg (`ffmpeg -i in.ext -ar 16000 out.mp3`).

## Step 3 — Analyze (per recording)

Load `~/recordings_pipeline/profiles.json`, then produce a Markdown report containing:

1. **Header** — filename, source device (from the `ROSE-REC1_`/`ROSE-REC2_` prefix), duration, date.
2. **Summary** — 2–4 paragraph overview of what the recording contains.
3. **Speaker dialogue** — the transcript rewritten as a labeled dialogue with timestamps. Use profile voice characteristics, names spoken in the audio, and conversational context to attribute lines (e.g., `[09:05] Marc: ...`). Unknown voices get `Speaker A/B` labels.
4. **Notable moments** — arguments, yelling, decisions, action items, with timestamps. Flag any inappropriate behavior by Marc explicitly.
5. **Profile matches** — which known profiles (Marc, Ethan, ...) appear and the evidence for the match.

### Gerald recordings — REQUIRED custom summary format

If the recording is a one-on-one call/conversation between Brandon and **Gerald** (boyfriend/business collaborator; topics: business ideas, AI coaching), the report MUST additionally include these four sections:

1. **Business Ideas** — every idea discussed, with enough context to revisit later.
2. **Action Items / Tasks** — split into two lists: *Brandon's tasks* and *Gerald's tasks*.
3. **Research Reminders** — things Brandon said he'd look into; tools/services mentioned worth exploring.
4. **AI Lessons Covered** — what Brandon taught Gerald, to track progress and plan future sessions.

## Step 4 — Sort

Decide the destination folder using `profiles.json` sorting rules:

- Marc yelling/inappropriate → `Marc's Inappropriate Screaming`
- Brandon + Gerald one-on-one (business/AI) → `Gerald` (inside Recordings; see `target_folder_id` in profiles.json)
- Brandon + Momma Rose (mother) calls/conversations → `Momma Rose` (inside Recordings; see `target_folder_id` in profiles.json). Confirmed voice sample: `voice_samples/Momma_Rose_sample.WAV`.
- Phone call → `Calls`
- Work meeting → `Meetings`
- User alone (memo) → `Personal Notes`
- No match → `Other`

**Filing:** Because Drive write-access is not available via connector, deliver the report + sorted-copy of the audio to the user as attachments AND tell the user which Drive folder to drop them in (exact folder name). If Drive write access becomes available later (connector fixed or user provides another method), move files directly instead.

## Step 5 — Update profiles

- Append any newly observed voice characteristics, phrases, or interactions to the matching profile in `profiles.json`.
- If a new recurring voice appears, propose a new profile to the user.

## Step 6 — Mark processed & report

```bash
python3 ~/recordings_pipeline/drive_scan.py --mark-done <file_id> [...]
```

Then message the user with: files processed, summaries, dialogues, destination folders, and any profile updates.
