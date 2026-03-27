#!/bin/bash
# Build Voice2Type.app bundle

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Voice2Type"
APP_DIR="$PROJECT_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME.app..."

# Clean previous build
rm -rf "$APP_DIR"

# Create .app structure
mkdir -p "$MACOS" "$RESOURCES"

# Info.plist
cat > "$CONTENTS/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Voice2Type</string>
    <key>CFBundleIdentifier</key>
    <string>com.voice2type</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>voice2type-launcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSBackgroundOnly</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Launcher script
cat > "$MACOS/voice2type-launcher" <<LAUNCHER
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
DIR="\$(dirname "\$(dirname "\$(dirname "\$SCRIPT_DIR")")")"
VENV="\$DIR/.venv"
PYTHON="\$VENV/bin/python"

if [ ! -f "\$PYTHON" ]; then
    osascript -e 'display alert "Voice2Type" message "Run install.sh first to set up the virtual environment."'
    exit 1
fi

exec "\$PYTHON" -u "\$DIR/voice2type.py"
LAUNCHER

chmod +x "$MACOS/voice2type-launcher"

echo "Built: $APP_DIR"
