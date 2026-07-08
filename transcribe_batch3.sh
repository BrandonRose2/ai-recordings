#!/bin/bash
# Transcribe all batch-3 mp3s sequentially with manus-speech-to-text.
cd ~/recordings_pipeline/mp3
> ../transcripts/batch3_tx.log
for f in \
  "ROSE-REC2_V2025-12-26-17-20-18.mp3" \
  "ROSE-REC2_V2025-12-26-19-06-42.mp3" \
  "ROSE-REC2_V2025-12-27-12-31-19.mp3" \
  "ROSE-REC2_V2025-12-27-13-44-38.mp3" \
  "ROSE-REC2_V2025-12-27-15-16-08.mp3" \
  "ROSE-REC2_V2025-12-27-15-51-38.mp3" \
  "ROSE-REC2_V2025-12-27-15-58-16.mp3" \
  "ROSE-REC2_V2025-12-27-16-01-28.mp3" \
  "ROSE-REC2_V2025-12-27-17-53-14.mp3" \
  "ROSE-REC2_V2025-12-27-19-21-04.mp3" \
  "ROSE-REC2_V2025-12-27-20-34-35.mp3" \
  "ROSE-REC2_V2025-12-28-12-14-06.mp3" \
  "ROSE-REC2_V2025-12-28-13-09-24.mp3" \
  "ROSE-REC2_V2025-12-28-15-13-53.mp3" \
  "ROSE-REC2_V2025-12-28-18-15-09.mp3" \
  "ROSE-REC2_V2025-12-28-20-00-42.mp3" \
  "ROSE-REC2_V2025-12-28-21-38-40.mp3" \
  "ROSE-REC2_V2025-12-29-12-30-06.mp3" \
  "ROSE-REC2_V2025-12-29-14-25-19.mp3" \
  "ROSE-REC2_V2025-12-29-15-37-39.mp3" \
  "ROSE-REC2_V2025-12-29-17-52-38.mp3" \
  "ROSE-REC2_V2025-12-29-19-32-47.mp3" \
  "ROSE-REC2_V2025-12-29-21-00-42.mp3" \
  "ROSE-REC2_V2025-12-31-17-21-26.mp3" \
  "ROSE-REC2_V2025-12-31-18-22-14.mp3" \
  "ROSE-REC2_V2025-12-31-21-56-57.mp3" \
  "ROSE-REC2_V2025-12-31-22-56-57.mp3" \
  "ROSE-REC2_V2026-07-02-08-55-08.mp3" \
  "ROSE-REC2_V2026-07-02-09-55-09.mp3" \
  "ROSE-REC2_V2026-07-02-10-55-09.mp3" \
  "ROSE-REC2_V2026-07-02-11-55-09.mp3" \
  "ROSE-REC2_V2026-07-02-12-55-09.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-11-08-04.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-12-08-05.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-13-08-05.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-14-08-05.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-15-08-05.mp3" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-16-08-06.mp3" \
; do
  base="${f%.mp3}"
  out="../transcripts/${base}.txt"
  if [ -f "$out" ] && [ -s "$out" ]; then
    echo "SKIP (exists): $base" >> ../transcripts/batch3_tx.log
    continue
  fi
  echo "START: $base $(date '+%H:%M:%S')" >> ../transcripts/batch3_tx.log
  manus-speech-to-text "$f" > "$out" 2>>../transcripts/batch3_tx.log
  echo "DONE: $base $(date '+%H:%M:%S') words=$(wc -w < "$out")" >> ../transcripts/batch3_tx.log
done
echo "ALL_TRANSCRIPTION_DONE" >> ../transcripts/batch3_tx.log
