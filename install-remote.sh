#!/bin/bash
# Remote installer for voice2type
# Usage: curl -fsSL https://raw.githubusercontent.com/Theyellowhat06/voice2type/main/install-remote.sh | bash

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

# Build .app bundle
echo "Building Voice2Type.app..."
bash "$INSTALL_DIR/build-app.sh"

APP_DIR="$INSTALL_DIR/Voice2Type.app"
LAUNCHER="$APP_DIR/Contents/MacOS/voice2type-launcher"

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
        <string>$LAUNCHER</string>
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
echo "Installed! voice2type starts on login."
echo "First run downloads the whisper model (~150MB)."
echo "Logs: tail -f $LOG_FILE"
echo ""

# Open Accessibility settings and guide the user
echo "Opening Accessibility settings..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

osascript -e "display dialog \"voice2type needs Accessibility permission to detect hotkeys.

Steps:
1. Click the + button (unlock if needed)
2. Press Cmd+Shift+G and paste:
   $INSTALL_DIR
3. Select Voice2Type.app
4. Make sure it is toggled ON\" with title \"Voice2Type Setup\" buttons {\"Done\"} default button \"Done\""

echo "Setup complete! Hold Ctrl+Shift to record."
echo "Config: $INSTALL_DIR/config.json"
echo "Uninstall: $INSTALL_DIR/uninstall.sh"
echo ""
