"""Deterministic, original CC0-compatible synth loops for Phase 3.

Run from the project root: python3 tools/generate_audio.py
"""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets/audio/generated"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 11025


def write(name, samples):
    peak = max(1.0, max(abs(s) for s in samples))
    pcm = b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * 0.84)) * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)


def music(name, bpm, chords, lead, drums):
    beats = 16
    duration = beats * 60 / bpm
    result = []
    for n in range(int(duration * RATE)):
        t = n / RATE
        beat = t * bpm / 60
        index = int(beat // 4) % len(chords)
        phase = beat % 1
        chord = chords[index]
        sound = 0
        for j, midi in enumerate(chord):
            hz = 440 * 2 ** ((midi - 69) / 12)
            sound += (0.13 if j else 0.21) * math.sin(2 * math.pi * hz * t) * (0.7 + 0.3 * math.cos(2 * math.pi * phase))
        if lead:
            midi = lead[int(beat * 2) % len(lead)]
            hz = 440 * 2 ** ((midi - 69) / 12)
            envelope = math.exp(-phase * 3.5)
            sound += 0.17 * envelope * (math.sin(2 * math.pi * hz * t) + 0.18 * math.sin(4 * math.pi * hz * t))
        if drums:
            kick = math.exp(-phase * 35) * math.sin(2 * math.pi * (75 - 25 * phase) * t)
            sound += drums * kick
        result.append(sound)
    write(name, result)


def ambience(name, seed, mode):
    rng = random.Random(seed)
    samples = []
    low = 0
    for n in range(RATE * 5):
        t = n / RATE
        noise = rng.uniform(-1, 1)
        low = low * (0.995 if mode == "wind" else 0.85) + noise * (0.005 if mode == "wind" else 0.15)
        if mode == "wind":
            val = low * (0.6 + 0.3 * math.sin(t * 2.1))
        elif mode == "water":
            val = low * 0.7 + noise * 0.07 + 0.08 * math.sin(t * 37)
        else:
            envelope = (1 - math.exp(-t * 14)) * math.exp(-t * 0.85)
            val = envelope * (low * 0.6 + 0.18 * math.sin(t * 73) + 0.12 * math.sin(t * 49))
        samples.append(val)
    write(name, samples)


music("menu.wav", 84, [[45, 52, 57], [41, 48, 53], [43, 50, 55], [40, 47, 52]], [69, 72, 76, 72, 67, 69, 72, 67], 0)
music("board.wav", 100, [[48, 55, 60], [45, 52, 57], [50, 57, 62], [43, 50, 55]], [72, 67, 69, 64, 67, 72, 74, 67], 0)
music("battle.wav", 120, [[45, 52, 57], [43, 50, 55], [41, 48, 53], [40, 47, 52]], [57, 60, 64, 60, 55, 57, 60, 55], 0.12)
music("battle_intense.wav", 120, [[45, 52, 57], [43, 50, 55], [41, 48, 53], [40, 47, 52]], [81, 76, 79, 72, 77, 72, 76, 71], 0.28)
ambience("wind.wav", 21, "wind")
ambience("waterfall.wav", 32, "water")
ambience("thunder.wav", 43, "thunder")
