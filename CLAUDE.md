# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

voice2type is a local, offline speech-to-text tool for macOS. Hold a hotkey to record from the microphone, release to transcribe via faster-whisper and paste the text at the cursor position. Single-file Python app (~200 lines).

## Setup & Run

```bash
# First-time setup (creates .venv, installs deps)
./setup.sh

# Run
.venv/bin/python voice2type.py
```

First run downloads the whisper model (~150MB). Requires Accessibility permission for the terminal app (System Settings > Privacy & Security > Accessibility).

## Architecture

Single module `voice2type.py` with one class `Voice2Type`:
- **Hotkey detection**: `pynput` keyboard listener tracks pressed keys, triggers record on hotkey combo (configurable in `config.json`)
- **Audio capture**: `sounddevice` InputStream at 16kHz mono, frames collected in a list
- **Transcription**: `faster-whisper` WhisperModel with VAD filter, runs on release in a daemon thread
- **Text output**: Copies to clipboard via `pyperclip`, then simulates Cmd+V via `osascript` (macOS only), restores original clipboard after

## Config

`config.json` fields:
- `hotkey` — key combo string like `"cmd_r+;"` (modifier names from pynput)
- `model_size` — whisper model: `tiny`, `base`, `small`, `medium`, `large-v2`
- `language` — ISO language code (e.g. `"en"`)
- `device` — `"cpu"` or `"cuda"`
- `compute_type` — `"int8"`, `"float16"`, etc.

## Key Dependencies

`faster-whisper`, `sounddevice`, `numpy`, `pynput`, `pyperclip` — pinned in `requirements.txt`.

## Platform

macOS only — uses `osascript` for keystroke simulation and relies on macOS Accessibility API via pynput.
