"""Build character attack, special, impact, and damage cues from local CC0 Foley.

The source OGG files remain untouched. GStreamer decodes them to temporary PCM;
the added tonal, noise, and sub-bass layers are generated here. Run from any cwd.
"""

from array import array
import math
from pathlib import Path
import random
import subprocess
import tempfile
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/generated"
RATE = 44100
TAU = 2.0 * math.pi

# Character, cue: (duration, source folder/file, sample offset, speed, sample gain,
# tonal start/end Hz and gain, noise type/gain, bass Hz/gain, seed).
RECIPES = {
    ("P", "attack"): (.39, "opengameart_rpg/blade_01.ogg", .03, 1.34, .60, 950, 240, .16, "rush", .21, 120, .08, 200),
    ("N", "attack"): (.43, "opengameart_rpg/metal_02.ogg", .02, 1.15, .57, 680, 170, .23, "rush", .19, 95, .14, 201),
    ("B", "attack"): (.48, "opengameart_rpg/spell_02.ogg", .02, 1.42, .42, 360, 850, .25, "shimmer", .16, 130, .06, 202),
    ("R", "attack"): (.56, "kenney/impactPunch_heavy_001.ogg", .0, .70, .62, 230, 65, .17, "war", .20, 58, .43, 203),
    ("Q", "attack"): (.49, "kenney/impactBell_heavy_003.ogg", .0, 1.55, .37, 610, 920, .25, "shimmer", .11, 125, .10, 204),
    ("K", "attack"): (.51, "opengameart_rpg/metal_03.ogg", .01, .92, .59, 350, 110, .18, "rattle", .13, 72, .25, 205),
    ("W", "attack"): (.59, "kenney/impactPlate_heavy_001.ogg", .0, .75, .64, 180, 50, .20, "war", .18, 50, .42, 206),
    ("N", "special"): (.69, "kenney/impactMetal_medium_004.ogg", .34, 1.0, .38, 720, 130, .32, "rush", .33, 84, .24, 210),
    ("N", "hit"): (.52, "kenney/impactMetal_heavy_002.ogg", .0, .82, .66, 470, 150, .17, "rattle", .12, 105, .15, 211),
    ("B", "special"): (.84, "opengameart_rpg/spell_fire_06.ogg", .06, .92, .32, 180, 1050, .31, "crackle", .34, 115, .09, 220),
    ("B", "hit"): (.62, "kenney/impactGlass_medium_001.ogg", .0, 1.12, .42, 950, 270, .25, "shimmer", .17, 140, .06, 221),
    ("R", "special"): (.92, "kenney/impactPunch_heavy_001.ogg", .24, .66, .58, 190, 45, .15, "fuse", .27, 62, .48, 230),
    ("R", "hit"): (.66, "kenney/impactWood_heavy_003.ogg", .0, .88, .55, 280, 85, .13, "rattle", .16, 74, .28, 231),
    ("Q", "special"): (1.02, "kenney/impactBell_heavy_000.ogg", .12, 1.18, .43, 460, 890, .36, "shimmer", .15, 118, .18, 240),
    ("Q", "hit"): (.71, "kenney/impactBell_heavy_003.ogg", .0, 1.38, .35, 1050, 240, .28, "shimmer", .09, 160, .09, 241),
    ("K", "special"): (.94, "opengameart_rpg/stones_03.ogg", .15, .87, .58, 155, 54, .20, "quake", .28, 55, .38, 250),
    ("K", "hit"): (.69, "kenney/impactMining_003.ogg", .0, .97, .42, 225, 70, .17, "quake", .15, 66, .29, 251),
    ("W", "special"): (.97, "kenney/impactMetal_heavy_002.ogg", .27, .7, .63, 165, 76, .29, "war", .26, 49, .47, 260),
    ("W", "hit"): (.72, "kenney/impactPlate_heavy_001.ogg", .0, .84, .56, 260, 70, .14, "war", .14, 58, .31, 261),
    ("N", "special_impact"): (.66, "kenney/impactMetal_heavy_002.ogg", .0, .80, .65, 520, 85, .23, "rush", .24, 67, .32, 270),
    ("B", "special_impact"): (.80, "opengameart_rpg/spell_fire_07.ogg", .0, .85, .46, 670, 105, .21, "crackle", .44, 86, .30, 271),
    ("R", "special_impact"): (.94, "kenney/impactPunch_heavy_001.ogg", .0, .59, .72, 190, 43, .23, "blast", .52, 49, .62, 272),
    ("Q", "special_impact"): (.96, "kenney/impactBell_heavy_000.ogg", .0, .93, .53, 1150, 270, .32, "shimmer", .22, 114, .27, 273),
    ("K", "special_impact"): (.90, "opengameart_rpg/stones_04.ogg", .0, .72, .64, 200, 47, .20, "quake", .37, 47, .51, 274),
    ("W", "special_impact"): (.99, "kenney/impactPlate_heavy_001.ogg", .0, .66, .70, 150, 38, .27, "war", .36, 42, .62, 275),
}


def decode_source(path: Path, scratch: Path) -> array:
    target = scratch / (path.stem + ".wav")
    subprocess.run([
        "gst-launch-1.0", "-q", "filesrc", f"location={path}", "!",
        "oggdemux", "!", "vorbisdec", "!", "audioconvert", "!", "audioresample", "!",
        "audio/x-raw,format=S16LE,channels=1,rate=44100", "!", "wavenc", "!",
        "filesink", f"location={target}",
    ], check=True)
    with wave.open(str(target), "rb") as wav:
        assert wav.getnchannels() == 1 and wav.getsampwidth() == 2 and wav.getframerate() == RATE
        pcm = array("h")
        pcm.frombytes(wav.readframes(wav.getnframes()))
    return array("f", (value / 32768.0 for value in pcm))


def build(spec: tuple, source: array) -> array:
    duration, _, offset, speed, sample_gain, hz0, hz1, tone_gain, noise_kind, noise_gain, bass_hz, bass_gain, seed = spec
    total = round(duration * RATE)
    result = array("f", [0.0]) * total
    rng = random.Random(seed)
    phase = 0.0
    bass_phase = 0.0
    low = 0.0
    prev_noise = 0.0
    for i in range(total):
        t = i / RATE
        x = i / total
        # Local Foley is the transient anchor; source clips are intentionally short.
        source_at = (t - offset) * RATE * speed
        if 0 <= source_at < len(source) - 1:
            index = int(source_at)
            fraction = source_at - index
            result[i] += (source[index] * (1 - fraction) + source[index + 1] * fraction) * sample_gain
        tone_hz = hz0 * (hz1 / hz0) ** x
        phase += TAU * tone_hz / RATE
        if noise_kind == "shimmer":
            tone = math.sin(phase) + .38 * math.sin(2.39 * phase)
            envelope = math.sin(math.pi * x) ** .7
        elif noise_kind == "fuse":
            tone = math.sin(phase) * (1 + .2 * math.sin(TAU * 23 * t))
            envelope = math.exp(-5 * max(0.0, t - .25))
        else:
            tone = math.sin(phase) + .19 * math.sin(2 * phase)
            envelope = math.sin(math.pi * x) ** 1.2
        result[i] += tone_gain * tone * envelope
        raw = rng.uniform(-1.0, 1.0)
        low += (.12 if noise_kind in ("quake", "war") else .25) * (raw - low)
        high = raw - prev_noise * .7
        prev_noise = raw
        if noise_kind == "rush":
            noise = high * math.sin(math.pi * x) ** 1.5
        elif noise_kind == "crackle":
            noise = high * (1.0 if rng.random() < .16 else .08) * (1 - x)
        elif noise_kind == "fuse":
            noise = high * (1.0 if rng.random() < .035 else .06) * (1 - x)
        elif noise_kind == "blast":
            noise = (.55 * low + .45 * high) * math.exp(-5 * x)
        elif noise_kind == "shimmer":
            noise = high * .5 * math.exp(-3 * x)
        elif noise_kind == "rattle":
            noise = high * math.exp(-5 * x) * (0.4 + .6 * abs(math.sin(TAU * 34 * t)))
        else:
            noise = low * math.exp(-3 * x)
        result[i] += noise_gain * noise
        # Falling sub-bass distinguishes bombs and stone/armour impacts.
        bass_phase += TAU * bass_hz * (1.5 - .5 * x) / RATE
        bass_start = .24 if noise_kind == "fuse" else (.17 if noise_kind in ("quake", "war") else .0)
        if t >= bass_start:
            result[i] += bass_gain * math.sin(bass_phase) * math.exp(-8 * (t - bass_start))
    # Eliminate edge clicks while retaining the body of short impacts.
    fade = round(.008 * RATE)
    for i in range(fade):
        result[i] *= i / fade
        result[-1 - i] *= i / fade
    return result


def save(path: Path, samples: array) -> tuple[float, float]:
    largest = max(abs(value) for value in samples)
    raw_rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    scale = min(.72 / max(largest, 1e-9), .21 / max(raw_rms, 1e-9))
    pcm = array("h", (round(max(-1, min(1, value * scale)) * 32767) for value in samples))
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())
    rms = math.sqrt(sum((value / 32768) ** 2 for value in pcm) / len(pcm))
    return len(samples) / RATE, rms


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT / ".audit_runtime").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=ROOT / ".audit_runtime") as temp:
        scratch = Path(temp)
        decoded = {}
        for (kind, cue), spec in RECIPES.items():
            source_name = spec[1]
            if source_name not in decoded:
                decoded[source_name] = decode_source(ROOT / "assets/audio" / source_name, scratch)
            name = f"{cue}_{kind.lower()}.wav"
            length, rms = save(OUT / name, build(spec, decoded[source_name]))
            print(f"{name}: {length:.2f}s, RMS {rms:.3f}")


if __name__ == "__main__":
    main()
