#!/usr/bin/env python3
"""
voice2type - Local speech-to-text that types at your cursor.
Press and hold hotkey to record, release to transcribe and type.
Fully offline using faster-whisper (no API costs).
"""

import json
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

import numpy as np
import pyperclip
import sounddevice as sd
from faster_whisper import WhisperModel
from pynput import keyboard

CONFIG_PATH = Path(__file__).parent / 'config.json'
SAMPLE_RATE = 16000
CHANNELS = 1


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def paste_text(text):
    """Copy text to clipboard and paste at cursor via Cmd+V."""
    old_clipboard = pyperclip.paste()
    pyperclip.copy(text)
    subprocess.run(
        ['osascript', '-e',
         'tell application "System Events" to keystroke "v" using command down'],
        check=False,
    )
    time.sleep(0.1)
    pyperclip.copy(old_clipboard)


class Voice2Type:
    def __init__(self):
        self.config = load_config()
        self.recording = False
        self.audio_frames = []
        self.stream = None
        self.model = None
        self._hotkey_parts = self._parse_hotkey(self.config['hotkey'])
        self._pressed_keys = set()
        self._hotkey_active = False

    def _parse_hotkey(self, hotkey_str):
        """Parse hotkey string like 'cmd_r+;' into pynput key objects."""
        key_map = {
            'cmd': keyboard.Key.cmd,
            'cmd_l': keyboard.Key.cmd_l,
            'cmd_r': keyboard.Key.cmd_r,
            'ctrl': keyboard.Key.ctrl,
            'ctrl_l': keyboard.Key.ctrl_l,
            'ctrl_r': keyboard.Key.ctrl_r,
            'alt': keyboard.Key.alt,
            'alt_l': keyboard.Key.alt_l,
            'alt_r': keyboard.Key.alt_r,
            'shift': keyboard.Key.shift,
            'shift_l': keyboard.Key.shift_l,
            'shift_r': keyboard.Key.shift_r,
        }
        parts = []
        for part in hotkey_str.split('+'):
            part = part.strip().lower()
            if part in key_map:
                parts.append(key_map[part])
            elif len(part) == 1:
                parts.append(keyboard.KeyCode.from_char(part))
            else:
                print(f'Warning: unknown key "{part}"')
        return parts

    def _key_matches(self, key, target):
        """Check if a pressed key matches a target key."""
        if isinstance(target, keyboard.Key):
            return key == target
        if isinstance(target, keyboard.KeyCode) and isinstance(key, keyboard.KeyCode):
            return key.char == target.char if key.char else False
        return False

    def _is_hotkey_pressed(self):
        """Check if all hotkey parts are currently pressed."""
        for target in self._hotkey_parts:
            found = any(self._key_matches(k, target) for k in self._pressed_keys)
            if not found:
                return False
        return True

    def load_model(self):
        """Load whisper model (downloads on first run)."""
        print(f'Loading whisper model ({self.config["model_size"]})...')
        self.model = WhisperModel(
            self.config['model_size'],
            device=self.config['device'],
            compute_type=self.config['compute_type'],
        )
        print('Model loaded.')

    def start_recording(self):
        """Start capturing audio from microphone."""
        if self.recording:
            return
        self.recording = True
        self.audio_frames = []
        self.stream = sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            dtype='float32',
            callback=self._audio_callback,
        )
        self.stream.start()
        print('\r Recording...', end='', flush=True)

    def _audio_callback(self, indata, frames, time_info, status):
        if self.recording:
            self.audio_frames.append(indata.copy())

    def stop_recording_and_transcribe(self):
        """Stop recording, transcribe, and type the result."""
        if not self.recording:
            return
        self.recording = False
        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None

        if not self.audio_frames:
            print('\r No audio captured.', end='', flush=True)
            return

        print('\r Transcribing...', end='', flush=True)
        audio = np.concatenate(self.audio_frames, axis=0).flatten()

        segments, _ = self.model.transcribe(
            audio,
            language=self.config['language'],
            beam_size=5,
            vad_filter=True,
        )

        text = ' '.join(seg.text.strip() for seg in segments).strip()

        if text:
            print(f'\r Typed: {text}')
            paste_text(text)
        else:
            print('\r (no speech detected)')

    def on_press(self, key):
        self._pressed_keys.add(key)
        if not self._hotkey_active and self._is_hotkey_pressed():
            self._hotkey_active = True
            self.start_recording()

    def on_release(self, key):
        self._pressed_keys.discard(key)
        if self._hotkey_active and not self._is_hotkey_pressed():
            self._hotkey_active = False
            threading.Thread(
                target=self.stop_recording_and_transcribe,
                daemon=True,
            ).start()

    def run(self):
        """Main loop."""
        self.load_model()
        hotkey_display = self.config['hotkey'].replace('+', ' + ')
        print(f'\nvoice2type ready! Hold [{hotkey_display}] to speak.')
        print('Press Ctrl+C to quit.\n')

        with keyboard.Listener(
            on_press=self.on_press,
            on_release=self.on_release,
        ) as listener:
            try:
                listener.join()
            except KeyboardInterrupt:
                print('\nBye!')
                sys.exit(0)


if __name__ == '__main__':
    Voice2Type().run()
