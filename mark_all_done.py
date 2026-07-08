#!/usr/bin/env python3
"""Mark every file ID found in any scan JSON as processed."""
import json, glob

STATE = "/home/ubuntu/recordings_pipeline/processed_state.json"
state = json.load(open(STATE))
done = set(state.get("processed_ids", []))
known = state.setdefault("known_files", {})

added = 0
for scanfile in glob.glob("/home/ubuntu/recordings_pipeline/scan*.json"):
    try:
        scan = json.load(open(scanfile))
    except Exception:
        continue
    for key in ("downloaded", "new_files"):
        for entry in scan.get(key, []):
            fid = entry.get("id")
            if fid and fid not in done:
                done.add(fid)
                known[fid] = entry.get("name", "")
                added += 1

state["processed_ids"] = sorted(done)
json.dump(state, open(STATE, "w"), indent=1)
print(f"Added {added}; total processed: {len(done)}")
