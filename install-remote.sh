#!/bin/bash
# Remote installer for voice2type
# Usage: curl -fsSL https://raw.githubusercontent.com/OWNER/voice2type/main/install-remote.sh | bash

set -euo pipefail

INSTALL_DIR="$HOME/.voice2type"
REPO_URL="https://github.com/Theyellowhat06/voice2type.git"
PLIST_DEST="$HOME/Library/LaunchAgents/com.voice2type.plist"
LOG_FILE="$HOME/Library/Logs/voice2type.log"

echo ""
echo "  voice2type installer"
echo "  Local, offline speech-to-text for macOS"
echo ""

# macOS only
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: voice2type only works on macOS."
    exit 1
fi

# Check Python 3.10+
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found. Install Python 3.10+."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(sys.version_info.minor)')
if [ "$PYTHON_VERSION" -lt 10 ]; then
    echo "Error: Python 3.10+ required (found 3.$PYTHON_VERSION)."
    exit 1
fi

# Check git
if ! command -v git &> /dev/null; then
    echo "Error: git not found."
    exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    git -C "$INSTALL_DIR" pull --quiet
else
    echo "Downloading voice2type..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

# Create venv and install deps
PYTHON="$INSTALL_DIR/.venv/bin/python"
if [ ! -f "$PYTHON" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$INSTALL_DIR/.venv"
fi

echo "Installing dependencies..."
"$INSTALL_DIR/.venv/bin/pip" install -q -r "$INSTALL_DIR/requirements.txt"

# Stop existing service
if launchctl list 2>/dev/null | grep -q com.voice2type; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Install LaunchAgent
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
        <string>$INSTALL_DIR/voice2type.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
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

launchctl load "$PLIST_DEST"

echo ""
echo "Installed! voice2type will start on login."
echo ""
echo "First run downloads the whisper model (~150MB)."
echo "Logs: tail -f $LOG_FILE"
echo ""
echo "IMPORTANT — grant these permissions in System Settings > Privacy & Security:"
echo ""
echo "  1. Accessibility:  Add $PYTHON"
echo "     (Click +, press Cmd+Shift+G, paste the path)"
echo ""
echo "  2. Microphone:     Allow when prompted"
echo ""
echo "Config: $INSTALL_DIR/config.json"
echo "Uninstall: $INSTALL_DIR/uninstall.sh"
echo ""
