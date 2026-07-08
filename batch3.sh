#!/bin/bash
# Batch 3: verify durations, convert new WAVs to mp3, detect speech via volume levels.
cd ~/recordings_pipeline/downloads
mkdir -p ../mp3 ../transcripts
> ../transcripts/batch3_progress.log
# Batch-3 files: Dec 2025 backlog + Wednesday 07-01 continuation + July 2 workday
for f in \
  ROSE-REC2_V2025-12-26-17-20-18.WAV \
  ROSE-REC2_V2025-12-26-19-06-42.WAV \
  ROSE-REC2_V2025-12-27-12-31-19.WAV \
  ROSE-REC2_V2025-12-27-13-44-38.WAV \
  ROSE-REC2_V2025-12-27-15-16-08.WAV \
  ROSE-REC2_V2025-12-27-15-51-38.WAV \
  ROSE-REC2_V2025-12-27-15-58-16.WAV \
  ROSE-REC2_V2025-12-27-16-01-28.WAV \
  ROSE-REC2_V2025-12-27-17-53-14.WAV \
  ROSE-REC2_V2025-12-27-19-21-04.WAV \
  ROSE-REC2_V2025-12-27-20-34-35.WAV \
  ROSE-REC2_V2025-12-28-12-14-06.WAV \
  ROSE-REC2_V2025-12-28-13-09-24.WAV \
  ROSE-REC2_V2025-12-28-15-13-53.WAV \
  ROSE-REC2_V2025-12-28-18-15-09.WAV \
  ROSE-REC2_V2025-12-28-20-00-42.WAV \
  ROSE-REC2_V2025-12-28-21-38-40.WAV \
  ROSE-REC2_V2025-12-29-12-30-06.WAV \
  ROSE-REC2_V2025-12-29-14-25-19.WAV \
  ROSE-REC2_V2025-12-29-15-37-39.WAV \
  ROSE-REC2_V2025-12-29-17-52-38.WAV \
  ROSE-REC2_V2025-12-29-19-32-47.WAV \
  ROSE-REC2_V2025-12-29-21-00-42.WAV \
  ROSE-REC2_V2025-12-31-17-21-26.WAV \
  ROSE-REC2_V2025-12-31-18-22-14.WAV \
  ROSE-REC2_V2025-12-31-21-56-57.WAV \
  ROSE-REC2_V2025-12-31-22-56-57.WAV \
  ROSE-REC2_V2026-07-02-08-55-08.WAV \
  ROSE-REC2_V2026-07-02-09-55-09.WAV \
  ROSE-REC2_V2026-07-02-10-55-09.WAV \
  ROSE-REC2_V2026-07-02-11-55-09.WAV \
  ROSE-REC2_V2026-07-02-12-55-09.WAV \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-11-08-04.WAV" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-12-08-05.WAV" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-13-08-05.WAV" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-14-08-05.WAV" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-15-08-05.WAV" \
  "ROSE-REC2_Wednesday - Bob Bell Visit_V2026-07-01-16-08-06.WAV" \
; do
  if [ ! -f "$f" ]; then
    echo "$f | MISSING" >> ../transcripts/batch3_progress.log
    continue
  fi
  size=$(stat -c%s "$f")
  if [ "$size" -lt 100000 ]; then
    echo "$f | STUB size=$size" >> ../transcripts/batch3_progress.log
    continue
  fi
  base="${f%.WAV}"
  mp3="../mp3/${base}.mp3"
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null | cut -d. -f1)
  [ -f "$mp3" ] || ffmpeg -v error -i "$f" -ac 1 -ar 16000 -b:a 48k "$mp3" -y
  mean=$(ffmpeg -i "$mp3" -af volumedetect -f null - 2>&1 | grep mean_volume | grep -oP '[-\d.]+(?= dB)')
  maxv=$(ffmpeg -i "$mp3" -af volumedetect -f null - 2>&1 | grep max_volume | grep -oP '[-\d.]+(?= dB)')
  echo "$base | dur=${dur}s mean=${mean}dB max=${maxv}dB" >> ../transcripts/batch3_progress.log
done
echo "CONVERSION_DONE" >> ../transcripts/batch3_progress.log
