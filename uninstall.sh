#!/bin/bash
# Remove voice2type completely

PLIST_DEST="$HOME/Library/LaunchAgents/com.voice2type.plist"
INSTALL_DIR="$HOME/.voice2type"

echo ""
echo "  voice2type uninstaller"
echo ""

# Stop service
if [ -f "$PLIST_DEST" ]; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    rm "$PLIST_DEST"
    echo "Service stopped and removed."
else
    echo "Service not installed."
fi

# Remove files
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "Files removed from $INSTALL_DIR"
fi

echo ""
echo "Done. You can also remove:"
echo "  - Accessibility permission for Python in System Settings"
echo "  - Log file: ~/Library/Logs/voice2type.log"
echo ""
