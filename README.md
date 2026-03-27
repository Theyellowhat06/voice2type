# voice2type

Local, offline speech-to-text for macOS. Hold a hotkey to record, release to transcribe and paste at your cursor. No API keys, no cloud — runs entirely on your machine using [faster-whisper](https://github.com/SYSTRAN/faster-whisper).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Theyellowhat06/voice2type/main/install-remote.sh | bash
```

After install, grant permissions in **System Settings > Privacy & Security**:
1. **Accessibility** — add the Python path shown by the installer
2. **Microphone** — allow when prompted on first use

## Usage

voice2type runs in the background and starts automatically on login.

**Hold `Ctrl+Shift`** to record, **release** to transcribe and paste.

## Config

Edit `~/.voice2type/config.json`:

```json
{
  "hotkey": "ctrl+shift",
  "model_size": "base",
  "language": "en",
  "device": "cpu",
  "compute_type": "int8"
}
```

| Field | Options |
|-------|---------|
| `hotkey` | Key combo, e.g. `ctrl+shift`, `cmd_r+alt_r` |
| `model_size` | `tiny`, `base`, `small`, `medium`, `large-v2` |
| `language` | ISO code: `en`, `mn`, `ja`, etc. |
| `device` | `cpu` or `cuda` |
| `compute_type` | `int8`, `float16`, etc. |

## Commands

```bash
# View logs
tail -f ~/Library/Logs/voice2type.log

# Stop
launchctl unload ~/Library/LaunchAgents/com.voice2type.plist

# Start
launchctl load ~/Library/LaunchAgents/com.voice2type.plist

# Uninstall
~/.voice2type/uninstall.sh
```

## Requirements

- macOS
- Python 3.10+
- ~150MB for whisper model (downloaded on first run)

## License

MIT
