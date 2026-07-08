#!/bin/bash
# Batch 2: convert new WAVs to mp3, detect speech via volume, transcribe non-silent files.
cd ~/recordings_pipeline/downloads
mkdir -p ../mp3 ../transcripts
FILES=(
"ROSE-REC2_Monday_V2026-01-01-12-33-19.WAV"
"ROSE-REC2_Monday_V2026-01-01-14-48-34.WAV"
"ROSE-REC2_Monday_V2026-01-01-17-37-30.WAV"
"ROSE-REC2_Monday_V2026-01-01-19-47-25.WAV"
"ROSE-REC2_Monday_V2026-01-01-21-07-46.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-07-22-01.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-08-22-01.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-08-40-29.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-09-02-59.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-10-11-12.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-11-11-13.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-12-11-13.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-13-11-13.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-14-11-13.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-15-11-13.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-16-11-14.WAV"
"ROSE-REC2_Tuesday_V2026-06-30-17-11-14.WAV"
"ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-00-26-10.WAV"
"ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-01-40-21.WAV"
"ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-09-04-26.WAV"
"ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-10-08-01.WAV"
)
> ../transcripts/batch2_progress.log
for f in "${FILES[@]}"; do
  base="${f%.WAV}"
  mp3="../mp3/${base}.mp3"
  [ -f "$mp3" ] || ffmpeg -v error -i "$f" -ac 1 -ar 16000 -b:a 48k "$mp3" -y
  vol=$(ffmpeg -i "$mp3" -af volumedetect -f null - 2>&1 | grep max_volume | grep -oP '[-\d.]+(?= dB)')
  echo "$base | max_volume=${vol}dB" >> ../transcripts/batch2_progress.log
done
echo "CONVERSION_DONE" >> ../transcripts/batch2_progress.log
