#!/usr/bin/env python3
"""Mark all batch-3 files (from scan_run2.json downloaded list) as processed."""
import json

STATE = "/home/ubuntu/recordings_pipeline/processed_state.json"
SCAN = "/home/ubuntu/recordings_pipeline/scan_run2.json"

state = json.load(open(STATE))
done = set(state.get("processed_ids", []))
scan = json.load(open(SCAN))

added = 0
for entry in scan.get("downloaded", []):
    fid = entry.get("id") or entry.get("file_id")
    if fid and fid not in done:
        done.add(fid)
        added += 1
        state.setdefault("known_files", {})[fid] = entry.get("name", "")

state["processed_ids"] = sorted(done)
json.dump(state, open(STATE, "w"), indent=1)
print(f"Added {added} new IDs; total processed: {len(done)}")
