#!/bin/bash
cd ~/recordings_pipeline
> transcripts/batch2_tx.log
for f in mp3/ROSE-REC2_Monday_V2026-01-01-*.mp3 "mp3/ROSE-REC2_Tuesday_V2026-06-30-07-22-01.mp3" "mp3/ROSE-REC2_Tuesday_V2026-06-30-08-22-01.mp3" "mp3/ROSE-REC2_Tuesday_V2026-06-30-08-40-29.mp3" "mp3/ROSE-REC2_Tuesday_V2026-06-30-09-02-59.mp3" mp3/ROSE-REC2_Tuesday_V2026-06-30-1*.mp3 mp3/ROSE-REC2_Wednesday*.mp3; do
  base=$(basename "$f" .mp3)
  out="transcripts/${base}.txt"
  [ -f "$out" ] && { echo "SKIP $base" >> transcripts/batch2_tx.log; continue; }
  echo "START $base $(date +%H:%M:%S)" >> transcripts/batch2_tx.log
  manus-speech-to-text "$f" > "$out" 2>&1
  echo "DONE $base $(date +%H:%M:%S)" >> transcripts/batch2_tx.log
done
echo "ALL_DONE" >> transcripts/batch2_tx.log
