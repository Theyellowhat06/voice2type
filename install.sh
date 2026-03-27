#!/bin/bash
# Install voice2type as a login service (LaunchAgent)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.voice2type.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LOG_FILE="$HOME/Library/Logs/voice2type.log"
PYTHON="$PROJECT_DIR/.venv/bin/python"

echo "=== voice2type installer ==="
echo ""

# Check venv exists
if [ ! -f "$PYTHON" ]; then
    echo "Virtual environment not found. Running setup first..."
    "$PROJECT_DIR/setup.sh"
fi

# Unload if already installed
if launchctl list 2>/dev/null | grep -q com.voice2type; then
    echo "Stopping existing service..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Create LaunchAgent plist
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
        <string>$PYTHON</string>
        <string>-u</string>
        <string>$PROJECT_DIR/voice2type.py</string>
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

# Load the service
launchctl load "$PLIST_DEST"

echo "Installed and started!"
echo ""
echo "Logs: $LOG_FILE"
echo "  tail -f $LOG_FILE"
echo ""
echo "IMPORTANT: Grant Accessibility permission to:"
echo "  $PYTHON"
echo "  System Settings > Privacy & Security > Accessibility"
echo "  (Click +, press Cmd+Shift+G, paste the path above)"
echo ""
echo "To stop:  launchctl unload $PLIST_DEST"
echo "To start: launchctl load $PLIST_DEST"
echo ""
