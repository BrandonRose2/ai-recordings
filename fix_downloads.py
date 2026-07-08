#!/usr/bin/env python3
"""Re-download any 'virus scan warning' HTML stubs with the confirm token."""
import os, re, sys, requests

DL_DIR = os.path.expanduser("~/recordings_pipeline/downloads")

def is_html_stub(path):
    with open(path, "rb") as f:
        head = f.read(200)
    return head.lstrip().startswith(b"<!DOCTYPE html") or head.lstrip().startswith(b"<html")

def fix(path):
    html = open(path, encoding="utf-8", errors="ignore").read()
    action = re.search(r'action="([^"]+)"', html)
    params = dict(re.findall(r'name="([^"]+)" value="([^"]*)"', html))
    if not action or "id" not in params:
        print(f"SKIP (no form): {path}")
        return False
    url = action.group(1)
    print(f"Re-downloading {os.path.basename(path)} ...")
    with requests.get(url, params=params, stream=True, timeout=300) as r:
        r.raise_for_status()
        tmp = path + ".tmp"
        with open(tmp, "wb") as out:
            for chunk in r.iter_content(1 << 20):
                out.write(chunk)
    os.replace(tmp, path)
    size = os.path.getsize(path)
    print(f"  -> {size} bytes")
    return True

def main():
    fixed = 0
    for name in sorted(os.listdir(DL_DIR)):
        path = os.path.join(DL_DIR, name)
        if os.path.isfile(path) and is_html_stub(path):
            if fix(path):
                fixed += 1
    print(f"Fixed {fixed} file(s).")

if __name__ == "__main__":
    main()
