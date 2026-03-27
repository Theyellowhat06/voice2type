#!/bin/bash
# Install voice2type locally

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_DEST="$HOME/Library/LaunchAgents/com.voice2type.plist"
LOG_FILE="$HOME/Library/Logs/voice2type.log"
APP_DIR="$PROJECT_DIR/Voice2Type.app"
LAUNCHER="$APP_DIR/Contents/MacOS/voice2type-launcher"

echo ""
echo "  voice2type installer"
echo ""

# Setup venv if needed
if [ ! -f "$PROJECT_DIR/.venv/bin/python" ]; then
    echo "Setting up virtual environment..."
    "$PROJECT_DIR/setup.sh"
fi

# Build .app if needed
if [ ! -d "$APP_DIR" ]; then
    "$PROJECT_DIR/build-app.sh"
fi

# Stop existing service
if launchctl list 2>/dev/null | grep -q com.voice2type; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Install LaunchAgent that runs the .app launcher
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_DEST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.voice2type</string>
    <key>ProgramArguments</key>
    <array>
        <string>$LAUNCHER</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>$LOG_FILE</string>
    <key>StandardErrorPath</key>
    <string>$LOG_FILE</string>
    <key>StandardInPath</key>
    <string>/dev/null</string>
</dict>
</plist>
EOF

# Start the service
launchctl load "$PLIST_DEST"

echo ""
echo "Installed and started!"
echo "Logs: tail -f $LOG_FILE"
echo ""

# Prompt for Accessibility permission
echo "Opening Accessibility settings..."
echo "Please add Voice2Type.app to the list."
echo ""

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

osascript -e "display dialog \"voice2type needs Accessibility permission to detect hotkeys.

Steps:
1. Click the + button (unlock if needed)
2. Press Cmd+Shift+G and paste:
   $PROJECT_DIR
3. Select Voice2Type.app
4. Make sure it is toggled ON\" with title \"Voice2Type Setup\" buttons {\"Done\"} default button \"Done\""

echo ""
echo "Setup complete! Hold Ctrl+Shift to record."
echo ""
