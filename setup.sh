#!/bin/bash
# voice2type setup script

set -e

cd "$(dirname "$0")"

echo "=== voice2type setup ==="
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found. Install Python 3.10+."
    exit 1
fi

# Create venv
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

echo "Installing dependencies..."
.venv/bin/pip install -q -r requirements.txt

echo ""
echo "Setup complete! Run with:"
echo "  cd $(pwd) && .venv/bin/python voice2type.py"
echo ""
echo "First run will download the whisper model (~150MB)."
echo ""
echo "IMPORTANT: Grant Accessibility permission to your terminal app:"
echo "  System Settings > Privacy & Security > Accessibility"
echo ""
