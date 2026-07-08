#!/bin/bash
# ============================================================
#  "Execute AI Recording Watcher" — one-click Mac app installer
#  Creates /Applications/Execute AI Recording Watcher.app
#  Double-click the app to manually run the ROSE-REC watcher.
# ============================================================
set -e

APP_NAME="Execute AI Recording Watcher"
APP_DIR="/Applications/${APP_NAME}.app"
WATCHER="$HOME/Scripts/rose_rec_watcher.sh"

echo "=============================================="
echo " ${APP_NAME} — Installer"
echo "=============================================="

if [ ! -f "$WATCHER" ]; then
  echo "ERROR: Watcher script not found at $WATCHER"
  echo "Install the watcher (v5) first, then re-run this installer."
  exit 1
fi

echo "[1/3] Building app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

# --- Info.plist ---
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Execute AI Recording Watcher</string>
  <key>CFBundleDisplayName</key><string>Execute AI Recording Watcher</string>
  <key>CFBundleIdentifier</key><string>com.rose.recwatcher.button</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>launcher</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict>
</plist>
PLIST

# --- Launcher executable: opens Terminal and runs the watcher ---
cat > "$APP_DIR/Contents/MacOS/launcher" <<'LAUNCH'
#!/bin/bash
# Opens a Terminal window and runs the watcher so progress is visible.
RUNNER="$HOME/Scripts/run_watcher_manual.sh"
open -a Terminal "$RUNNER"
LAUNCH
chmod +x "$APP_DIR/Contents/MacOS/launcher"

echo "[2/3] Installing manual-run wrapper..."
mkdir -p "$HOME/Scripts"
cat > "$HOME/Scripts/run_watcher_manual.sh" <<'RUNNER'
#!/bin/bash
clear
echo "=================================================="
echo "   AI RECORDING WATCHER — MANUAL RUN"
echo "   $(date '+%A %m-%d-%Y %H:%M:%S')"
echo "=================================================="
echo ""
DEVICES=$(ls /Volumes/ 2>/dev/null | grep -i '^ROSE-REC' || true)
if [ -z "$DEVICES" ]; then
  echo "No ROSE-REC device detected in /Volumes."
  echo "Plug in ROSE-REC1 or ROSE-REC2 and press the button again."
  echo ""
  osascript -e 'display notification "No ROSE-REC device plugged in." with title "AI Recording Watcher"' 2>/dev/null || true
else
  echo "Detected: $DEVICES"
  echo "Running watcher — uploads will appear below..."
  echo "--------------------------------------------------"
  bash "$HOME/Scripts/rose_rec_watcher.sh"
  echo "--------------------------------------------------"
  echo ""
  echo "Done. Recent log:"
  tail -6 "$HOME/Library/Logs/rose_rec_watcher.log" 2>/dev/null || true
fi
echo ""
echo "You can close this window."
RUNNER
chmod +x "$HOME/Scripts/run_watcher_manual.sh"

echo "[3/3] Finishing up..."
# Remove quarantine so Gatekeeper doesn't block the unsigned app
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true
# Refresh LaunchServices registration
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true

echo ""
echo "=============================================="
echo " Installed: $APP_DIR"
echo "=============================================="
echo ""
echo " HOW TO USE:"
echo "  1. Open your Applications folder"
echo "  2. Double-click 'Execute AI Recording Watcher'"
echo "     (drag it to your Dock for one-click access)"
echo "  3. A Terminal window opens and runs the watcher,"
echo "     showing upload progress live."
echo ""
echo " Note: the automatic watcher still runs on plug-in;"
echo " this button is just for manual runs whenever you want."
echo ""
open /Applications >/dev/null 2>&1 || true
