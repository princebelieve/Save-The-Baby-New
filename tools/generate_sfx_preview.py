"""Generate original sound-effect auditions without changing game audio mappings."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / ".test-data" / "audio-preview"


def render(name, duration, sample):
    rng = random.Random(name)
    samples = []
    state = {"low": 0.0, "phase": 0.0}
    for i in range(int(RATE * duration)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        state["low"] += 0.055 * (noise - state["low"])
        value = sample(t, duration, noise, state)
        # Quiet endpoints prevent clicks; normalize with 6 dB headroom.
        value *= min(1, t / 0.008, (duration - t) / 0.045)
        samples.append(value)
    peak = max(abs(x) for x in samples) or 1
    pcm = b"".join(struct.pack("<h", round(x / peak * 16383)) for x in samples)
    with wave.open(str(OUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(pcm)


def rocket(t, duration, noise, state):
    progress = t / duration
    state["phase"] += 2 * math.pi * (180 + 1100 * progress * progress) / RATE
    envelope = math.sin(math.pi * progress) ** 1.2
    return envelope * (2.7 * state["low"] + 0.22 * noise + 0.16 * math.sin(state["phase"]))


def bomb(t, _duration, noise, state):
    state["phase"] += 2 * math.pi * (44 + 100 * math.exp(-18 * t)) / RATE
    thump = math.sin(state["phase"]) * math.exp(-7 * t)
    crack = noise * math.exp(-70 * t)
    debris = state["low"] * math.exp(-5 * t) * (1 + 0.4 * math.sin(2 * math.pi * 31 * t))
    return 0.6 * thump + 0.24 * crack + 2.2 * debris


def thunder(t, _duration, noise, state):
    crack = noise * math.exp(-90 * t)
    echoes = sum(math.exp(-35 * (t - start)) for start in [0.045, 0.12, 0.23] if t >= start)
    rumble = 2.2 * state["low"] * math.exp(-3.8 * t)
    bass = math.sin(2 * math.pi * 38 * t) * math.exp(-5 * t)
    return 0.5 * crack + 0.20 * noise * echoes + rumble + 0.16 * bass


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    clips = [
        ("rocket-whoosh.wav", "Rocket", "An accelerating air sweep with a rising tone.", 0.85, rocket),
        ("bomb-impact.wav", "Bomb", "A sharp impact, low thump and short debris tail.", 0.85, bomb),
        ("thunder-crack.wav", "Thunder", "An irregular crack with echoes and a rolling low tail.", 1.3, thunder),
    ]
    cards = []
    for filename, title, description, duration, sample in clips:
        render(filename, duration, sample)
        cards.append(f'<section><h2>{title}</h2><p>{description}</p><audio controls preload="none" src="{filename}"></audio></section>')
    html = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Save the Baby — sound auditions</title>
<style>body{font:18px system-ui;background:#142332;color:#f8f0dc;max-width:720px;margin:40px auto;padding:20px}section{background:#24384b;padding:20px;border-radius:16px;margin:20px 0}audio{width:100%}p{line-height:1.5}</style>
<h1>Sound auditions</h1><p>Original synthesized previews. These have not replaced the game's sounds. Play each clip to choose the direction you prefer.</p>
''' + "\n".join(cards) + "</html>"
    (OUT / "listen.html").write_text(html, encoding="utf-8")
    print(f"Created {len(clips)} original WAV previews and {OUT / 'listen.html'}")


if __name__ == "__main__":
    main()
