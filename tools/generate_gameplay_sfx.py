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


for filename, duration, generator in [
    ("rocket_launch.wav", 0.64, launch),
    ("tile_burst.wav", 0.20, burst),
    ("tile_drop.wav", 0.28, drop),
    ("board_rumble.wav", 0.38, rumble),
    ("tile_swap.wav", 0.14, swipe),
]:
    write(filename, duration, generator)
    print(f"generated {filename}")
