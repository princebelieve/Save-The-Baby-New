"""Create compact, original arcade sounds used by the tile battle effects."""
import math
import random
import struct
import wave
from pathlib import Path


RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx" / "generated"
RNG = random.Random(730241)


def write(name, duration, sample):
    frames = bytearray()
    count = int(RATE * duration)
    for index in range(count):
        t = index / RATE
        value = max(-1.0, min(1.0, sample(t, duration)))
        frames.extend(struct.pack("<h", round(value * 32760)))
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(frames)


def envelope(t, length, attack=0.01, decay=4.0):
    return min(1.0, t / max(attack, 0.001)) * math.exp(-decay * t / length)


def launch(t, length):
    e = envelope(t, length, 0.05, 2.4)
    noise = RNG.uniform(-1.0, 1.0)
    sweep = math.sin(2 * math.pi * (150 - 100 * t / length) * t)
    sub = math.sin(2 * math.pi * 52 * t)
    return e * (0.28 * noise + 0.28 * sweep + 0.42 * sub)


def shot(t, length):
    e = envelope(t, length, 0.001, 5.0)
    noise = RNG.uniform(-1.0, 1.0)
    crack = noise * math.exp(-48 * t / length)
    body = math.sin(2 * math.pi * (125 - 32 * t / length) * t)
    metallic = math.sin(2 * math.pi * 1450 * t) * math.exp(-30 * t / length)
    ricochet = math.sin(2 * math.pi * (560 + 520 * t / length) * t) * math.exp(-12 * t / length)
    return e * (0.72 * crack + 0.34 * body + 0.22 * metallic + 0.12 * ricochet)


def burst(t, length):
    e = envelope(t, length, 0.002, 6.0)
    noise = RNG.uniform(-1.0, 1.0)
    thump = math.sin(2 * math.pi * (105 - 42 * t / length) * t)
    crackle = math.sin(2 * math.pi * 1850 * t) * math.exp(-18 * t / length)
    return e * (0.44 * noise + 0.40 * thump + 0.16 * crackle)


def drop(t, length):
    e = envelope(t, length, 0.004, 4.2)
    pitch = 390 - 170 * t / length + 52 * math.sin(2 * math.pi * 7 * t)
    note = math.sin(2 * math.pi * pitch * t)
    tap = RNG.uniform(-1.0, 1.0) * math.exp(-22 * t / length)
    return e * (0.56 * note + 0.24 * tap)


def rumble(t, length):
    e = envelope(t, length, 0.02, 2.2)
    noise = RNG.uniform(-1.0, 1.0)
    low = math.sin(2 * math.pi * 48 * t) + 0.45 * math.sin(2 * math.pi * 73 * t)
    return e * (0.48 * low + 0.20 * noise)


def swipe(t, length):
    e = envelope(t, length, 0.004, 5.0)
    pitch = 650 - 400 * t / length
    return e * (0.42 * RNG.uniform(-1.0, 1.0) + 0.32 * math.sin(2 * math.pi * pitch * t))


def fighter_shout(t, length):
    # Formant-style synthesized "ha-yah" call, made without a voice sample.
    first = t < 0.22
    local_t = t if first else t - 0.25
    if local_t < 0 or local_t > (0.22 if first else 0.32):
        return 0.0
    phase = 2 * math.pi * (245 * local_t - 70 * local_t * local_t)
    formants = ([(780, 180), (1180, 240), (2550, 420)] if first
                else [(690, 190), (1420, 260), (2350, 420)])
    voiced = 0.0
    for harmonic in range(1, 28):
        freq = harmonic * (245 - 140 * local_t)
        weight = sum(math.exp(-0.5 * ((freq - center) / width) ** 2) for center, width in formants)
        voiced += math.sin(harmonic * phase) * weight / harmonic
    env = min(1.0, local_t / 0.025) * math.exp(-4.5 * local_t)
    aspiration = RNG.uniform(-1.0, 1.0) * math.exp(-22 * local_t)
    return env * (0.48 * voiced + 0.055 * aspiration)


for filename, duration, generator in [
    ("rocket_launch.wav", 0.64, launch),
    ("rocket_shot.wav", 0.12, shot),
    ("tile_burst.wav", 0.20, burst),
    ("tile_drop.wav", 0.28, drop),
    ("board_rumble.wav", 0.38, rumble),
    ("tile_swap.wav", 0.14, swipe),
    ("kung_fu_shout.wav", 0.58, fighter_shout),
]:
    write(filename, duration, generator)
    print(f"generated {filename}")
