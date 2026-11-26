"""Generate original Floating Island music and seven weapon swings.

Standard-library synthesis only; no external samples. This script writes only the
assets listed below and never touches the existing menu/board/battle tracks.
Run from the project root: python3 tools/generate_phase3_sound.py
"""

from array import array
import math
from pathlib import Path
import random
import wave

OUT = Path(__file__).resolve().parents[1] / "assets/audio/generated"
RATE = 44100
TAU = 2.0 * math.pi
BEAT = 0.5  # 120 BPM: sixteen four-beat bars make a 32-second loop.
BARS = 16
FRAMES = round(BARS * 4 * BEAT * RATE)


def hz(midi: int) -> float:
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def write_wav(name: str, left: array, right: array | None = None, peak: float = 0.68) -> None:
    largest = max(1e-8, max(abs(x) for x in left), max(abs(x) for x in right) if right is not None else 0.0)
    scale = peak * 32767.0 / largest
    pcm = array("h")
    if right is None:
        pcm.extend(round(max(-32767, min(32767, x * scale))) for x in left)
        channels = 1
    else:
        for l, r in zip(left, right):
            pcm.append(round(max(-32767, min(32767, l * scale))))
            pcm.append(round(max(-32767, min(32767, r * scale))))
        channels = 2
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())


def add_note(left: array, right: array, start: float, duration: float, midi: int,
             gain: float, pan: float, timbre: str) -> None:
    first = round(start * RATE)
    total = round(duration * RATE)
    frequency = hz(midi)
    l_gain = gain * math.sqrt((1.0 - pan) * 0.5)
    r_gain = gain * math.sqrt((1.0 + pan) * 0.5)
    for i in range(total):
        t = i / RATE
        phase = TAU * frequency * t
        release = max(0.0, math.sin(math.pi * i / total)) ** 0.7
        if timbre == "air":
            tone = math.sin(phase + 0.12 * math.sin(TAU * 3.4 * t)) + 0.18 * math.sin(2.0 * phase)
            envelope = release * min(1.0, t / 0.22)
        elif timbre == "bell":
            tone = math.sin(phase) + 0.34 * math.sin(2.43 * phase) * math.exp(-t * 2.4)
            envelope = release * math.exp(-t * 2.0) * min(1.0, t / 0.008)
        else:  # soft bass
            tone = math.sin(phase) + 0.18 * math.sin(2.0 * phase)
            envelope = release * min(1.0, t / 0.015)
        at = (first + i) % FRAMES  # retain note tails through the loop boundary
        value = tone * envelope
        left[at] += value * l_gain
        right[at] += value * r_gain


def add_drum(left: array, right: array, start: float, kind: str, gain: float, seed: int) -> None:
    rng = random.Random(seed)
    duration = 0.24 if kind == "kick" else 0.14
    first = round(start * RATE)
    low = 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        envelope = math.exp(-t * (24.0 if kind == "kick" else 42.0)) * min(1.0, t / 0.003)
        if kind == "kick":
            value = math.sin(TAU * (52.0 * t + 32.0 * (1.0 - math.exp(-22.0 * t)) / 22.0))
        else:
            noise = rng.uniform(-1.0, 1.0)
            low = 0.78 * low + 0.22 * noise
            value = noise - low
        at = (first + i) % FRAMES
        left[at] += value * envelope * gain * 0.7
        right[at] += value * envelope * gain * 0.7


def island_music(intense: bool) -> None:
    left = array("f", [0.0]) * FRAMES
    right = array("f", [0.0]) * FRAMES
    chords = [(50, 53, 57, 62), (46, 50, 53, 58), (53, 57, 60, 65), (48, 52, 55, 60)]
    melody = [74, 77, 81, 79, 77, 74, 72, 69, 72, 74, 77, 81, 79, 77, 74, 72]
    for bar in range(BARS):
        start = bar * 4 * BEAT
        chord = chords[bar % len(chords)]
        if not intense:
            for voice, note in enumerate(chord):
                add_note(left, right, start, 2.45, note, 0.058, (-0.55, -0.2, 0.25, 0.6)[voice], "air")
            for beat in (0, 2):
                add_note(left, right, start + beat * BEAT, 0.9, chord[0] - 12, 0.12, 0.0, "bass")
            for beat in range(4):
                note = melody[(bar * 4 + beat) % len(melody)]
                add_note(left, right, start + beat * BEAT, 0.78, note, 0.105, (-0.35, 0.3)[beat % 2], "bell")
        else:
            for step in range(8):
                note = chord[(step + bar) % 4] + 24
                add_note(left, right, start + step * BEAT * 0.5, 0.34, note, 0.065,
                         (-0.48, 0.48)[step % 2], "bell")
                add_drum(left, right, start + step * BEAT * 0.5, "hat", 0.06, bar * 8 + step)
            for beat in (0, 2):
                add_drum(left, right, start + beat * BEAT, "kick", 0.3, bar * 4 + beat)
            for beat in (1, 3):
                add_drum(left, right, start + beat * BEAT, "hat", 0.12, 100 + bar * 4 + beat)
    write_wav("island_battle_intense.wav" if intense else "island_battle.wav",
              left, right, 0.48 if intense else 0.67)


WEAPONS = {
    # kind: duration, starting pitch, ending pitch, noise strength, metallic tone, seed
    "P": (0.26, 760.0, 190.0, 0.44, 0.19, 101),  # spear
    "N": (0.31, 580.0, 145.0, 0.56, 0.26, 102),  # fast blade
    "B": (0.35, 950.0, 320.0, 0.28, 0.35, 103),  # staff
    "R": (0.43, 310.0, 65.0, 0.67, 0.16, 104),   # heavy mace
    "Q": (0.34, 1080.0, 230.0, 0.35, 0.39, 105), # serpent blade
    "K": (0.40, 440.0, 85.0, 0.57, 0.31, 106),   # royal sword
    "W": (0.46, 240.0, 52.0, 0.73, 0.20, 107),   # warlord hammer
}


def weapon_swing(kind: str, specs: tuple[float, float, float, float, float, int]) -> None:
    duration, start_hz, end_hz, noise_gain, metal_gain, seed = specs
    rng = random.Random(seed)
    total = round(duration * RATE)
    samples = array("f")
    low = 0.0
    phase = 0.0
    for i in range(total):
        t = i / RATE
        progress = i / total
        envelope = math.sin(math.pi * progress) ** 1.5
        noise = rng.uniform(-1.0, 1.0)
        low = 0.86 * low + 0.14 * noise
        phase += TAU * (start_hz * (1.0 - progress) + end_hz * progress) / RATE
        whoosh = (noise - low) * noise_gain + math.sin(phase) * metal_gain
        samples.append(whoosh * envelope)
    write_wav("weapon_swing_%s.wav" % kind.lower(), samples, peak=0.62)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    island_music(False)
    island_music(True)
    for kind, parameters in WEAPONS.items():
        weapon_swing(kind, parameters)
    print("Generated 2 original Floating Island BGM WAV sources and 7 mono weapon swing WAV files.")
