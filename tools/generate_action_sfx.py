"""Original puzzle-action sound palette. No sampled recordings or borrowed melodies."""
import json
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio/sfx/actions"
PREVIEW = ROOT / ".test-data/audio-actions"
RATE = 44100


def note(start, length, hz, end=None, voice="pluck", gain=1):
    return (start, length, hz, hz if end is None else end, voice, gain)


def melody(notes, step=.065, length=.14, voice="pluck"):
    return [note(i * step, length, hz, voice=voice) for i, hz in enumerate(notes)]


CUES = {
    "ui_click": [note(0,.045,1046,voice="wood")],
    "ui_confirm": melody([659,1046],.055,.10),
    "ui_back": melody([784,523],.04,.08),
    "tile_swap": [note(0,.09,510,880,"bubble")],
    "invalid_move": [note(0,.13,260,160,"wood")],
    "booster_select": melody([440,659],.04,.09,"bell"),
    "tile_match": melody([659,880,1046],.032,.09),
    "tile_match_2": melody([784,1046,1318],.029,.10),
    "tile_match_3": melody([1046,1318,1760],.027,.11),
    "tile_burst": [note(0,.045,920,520,"bubble")],
    "tile_fall": [note(0,.12,480,260,"air",.3)],
    "tile_drop": [note(0,.065,400,220,"wood")],
    "objective_collected": melody([1318,1760],.038,.11,"bell"),
    "obstacle_destroyed": [note(0,.19,160,65,"crumble"),note(.025,.09,330,180,"wood",.45)],
    "special_created": melody([523,784,1046],.05,.17,"bell"),
    "special_rocket_created": melody([659,880,1318],.045,.15,"bell"),
    "special_bomb_created": melody([523,659,1046],.055,.16,"bell"),
    "special_thunder_created": melody([784,1174,1568,2093],.045,.17,"bell"),
    "rocket_launch": [note(0,.30,200,1700,"air"),note(0,.21,360,1440,"bubble",.24)],
    "rocket_combo": [note(0,.40,180,2000,"air"),note(.04,.28,220,1100,"bubble",.3)],
    "powerup_bomb": [note(0,.34,185,48,"crumble"),note(0,.26,130,48,"bubble",.7)],
    "powerup_thunder": [note(0,.14,2300,500,"zap"),note(.06,.16,1700,320,"zap",.65),note(.14,.16,1200,220,"zap",.4)],
    "powerup_hammer": [note(0,.10,280,85,"wood"),note(0,.14,220,80,"crumble",.25)],
    "powerup_ethan": melody([659,880,1046,1318],.04,.16,"bell"),
    "ethan_earned": melody([523,659,880,1318],.07,.20,"bell"),
    "victor_arrived": melody([220,207.65,146.83],.11,.22,"wood"),
    "powerup_victor": [note(0,.40,900,100,"air"),note(0,.3,180,50,"crumble",.5)],
    "board_rumble": [note(0,.15,105,65,"crumble",.3)],
    "case_open": [note(0,.10,500,950,"air",.5),note(.025,.08,523,voice="wood")],
    "case_close": [note(0,.08,420,220,"wood")],
    "door_open": [note(0,.13,330,660,"wood")],
    "door_close": [note(0,.11,240,120,"wood")],
    "win_sting": melody([523,659,880,1046,1318],.085,.22,"bell"),
    "lose_sting": melody([392,329.63,261.63],.11,.18,"wood"),
}


def render(name, events):
    rng = random.Random(name)
    duration = max(start + length for start, length, *_ in events) + .025
    samples = []
    low = 0
    for i in range(math.ceil(duration * RATE)):
        t = i / RATE
        noise = rng.uniform(-1,1)
        low += .075 * (noise - low)
        value = 0
        for start, length, hz, end, voice, gain in events:
            u = t - start
            if not 0 <= u < length:
                continue
            p = u / length
            phase = 2 * math.pi * (hz*u + (end-hz)*u*u/(2*length))
            tone = math.sin(phase)
            if voice == "pluck": tone += .25*math.sin(2*phase) + .09*math.sin(3*phase)
            elif voice == "bell": tone += .35*math.sin(2.76*phase)*math.exp(-8*p)
            elif voice == "wood": tone = .6*tone + .25*math.sin(1.61*phase) + .12*noise*math.exp(-18*p)
            elif voice == "air": tone = 2.3*low + .15*noise + .14*tone
            elif voice == "crumble": tone = .48*tone + 1.6*low + .35*noise*math.exp(-12*p)
            elif voice == "zap": tone = .55*math.tanh(3*tone) + .3*noise
            decay = 2.5 if voice == "air" else 5
            envelope = min(1,u/.002,(length-u)/.008) * math.exp(-decay*p)
            value += gain * envelope * tone
        samples.append(value)
    peak = max(abs(x) for x in samples) or 1
    samples = [x/peak*.6 for x in samples]
    path = OUT / f"{name}.wav"
    with wave.open(str(path),"wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(b"".join(struct.pack("<h",round(x*32767)) for x in samples))
    return {"file":path.name,"seconds":round(duration,3),"peak":round(max(abs(x) for x in samples),3)}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    PREVIEW.mkdir(parents=True,exist_ok=True)
    report = {name:render(name,events) for name,events in CUES.items()}
    (PREVIEW/"manifest.json").write_text(json.dumps(report,indent=2)+"\n")
    sequence = ["tile_swap", "tile_match", "tile_drop", "tile_match_2", "special_rocket_created", "rocket_launch", "objective_collected", "special_bomb_created", "powerup_bomb", "special_thunder_created", "powerup_thunder", "ethan_earned", "victor_arrived", "powerup_victor", "win_sting"]
    with wave.open(str(PREVIEW/"action-demo.wav"), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(RATE)
        for name in sequence:
            with wave.open(str(OUT/f"{name}.wav"), "rb") as source:
                target.writeframes(source.readframes(source.getnframes()))
            target.writeframes(b"\0\0" * int(RATE * .4))
    cards=[]
    cards.append('<section><strong>Quick action sequence</strong><audio controls preload="none" src="action-demo.wav"></audio><p>Swap, match, land, cascade, rocket creation and launch, collect, bomb creation and blast, Thunder creation and zap, Ethan, Victor, board wipe, win.</p></section>')
    for name in CUES:
        path = (OUT/f"{name}.wav").as_uri()
        cards.append(f'<section><strong>{name.replace("_"," ").title()}</strong><audio controls preload="none" src="{path}"></audio></section>')
    (PREVIEW/"listen.html").write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Save the Baby — action sounds</title><style>body{font:18px system-ui;background:#142332;color:#fff3d8;max-width:780px;margin:32px auto;padding:20px}section{background:#24384b;border-radius:12px;padding:16px;margin:12px 0}audio{width:100%;display:block;margin-top:12px}</style><h1>Save the Baby: action sounds</h1><p>Original synthesized effects, organized by their in-game action. Speech and background music are separate.</p>''' + "\n".join(cards)+"</html>",encoding="utf-8")
    print(f"Generated {len(report)} original cues; audition at {PREVIEW/'listen.html'}")


if __name__ == "__main__":
    main()
