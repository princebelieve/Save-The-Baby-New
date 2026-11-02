"""Create engine-compatible, level-matched praise; preserve all source clips.

Uses an installed VLC for decoding and Python's standard library for DSP.
"""
from array import array
import json
import math
from pathlib import Path
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/audio/sfx/kenney/voiceover"
OUTPUT = ROOT / "assets/audio/sfx/praise"
SCRATCH = ROOT / ".test-data/audio-edit"
VLC = Path(r"C:\Program Files\VideoLAN\VLC\vlc.exe")
RATE = 44100


def decode(name):
    destination = SCRATCH / (name + ".wav")
    command = [str(VLC), "--intf", "dummy", "--ignore-config", "--no-one-instance", "--no-video", "--sout",
               f"#transcode{{acodec=s16l,channels=1,samplerate={RATE}}}:std{{access=file,mux=wav,dst={destination.as_posix()}}}",
               "--play-and-exit", str(SOURCE / (name + ".ogg")), "vlc://quit"]
    subprocess.run(command, check=True, timeout=25, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   creationflags=subprocess.CREATE_NO_WINDOW)
    with wave.open(str(destination)) as stream:
        samples = array("h", stream.readframes(stream.getnframes()))
    return [sample / 32768.0 for sample in samples]


def active_rms(samples):
    frames = [samples[i:i+441] for i in range(0, len(samples), 441)]
    active = [v for frame in frames if sum(x*x for x in frame) / max(1, len(frame)) > 0.0001 for v in frame]
    return math.sqrt(sum(x*x for x in active) / max(1, len(active)))


def process(samples, target):
    # Retain consonant onsets and short natural tails, remove recorder silence.
    activity = [i for i, x in enumerate(samples) if abs(x) > 0.008]
    if not activity:
        raise ValueError("Silent praise source")
    samples = samples[max(0, activity[0]-882):min(len(samples), activity[-1]+2646)]
    highpass_alpha = math.exp(-2*math.pi*100/RATE)
    lowpass_alpha = 1-math.exp(-2*math.pi*7200/RATE)
    previous_input = high = low = 0.0
    filtered = []
    for sample in samples:
        high = highpass_alpha * (high + sample - previous_input)
        previous_input = sample
        low += lowpass_alpha * (high - low)
        filtered.append(low)
    gain = min(6.0, target / max(0.0001, active_rms(filtered)))
    limit = 10**(-3/20)
    result = []
    for i, sample in enumerate(filtered):
        value = sample * gain
        # Gentle peak compression; hard ceiling is only the final safeguard.
        if abs(value) > 0.45:
            value = math.copysign(0.45 + (abs(value)-0.45)/3.0, value)
        edge = min(1.0, i/220.0, (len(filtered)-1-i)/441.0)
        result.append(max(-limit, min(limit, value)) * max(0.0, edge))
    return result


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    SCRATCH.mkdir(parents=True, exist_ok=True)
    references = {name: decode(name) for name in ["power_up", "objective_achieved", "mission_completed"]}
    target = sum(active_rms(samples) for samples in references.values()) / len(references)
    # Short praise sits slightly behind the existing mission announcements.
    target = min(target * 0.8, 10**(-18/20))
    report = {"reference_active_rms_db": {n: round(20*math.log10(active_rms(s)), 2) for n, s in references.items()},
              "target_active_rms_db": round(20*math.log10(target), 2), "clips": {}}
    for name in ["nice", "excellent", "wonderful"]:
        original = decode(name)
        edited = process(original, target)
        pcm = array("h", (round(x*32767) for x in edited))
        with wave.open(str(OUTPUT / (name + ".wav")), "wb") as stream:
            stream.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
            stream.writeframes(pcm.tobytes())
        report["clips"][name] = {"seconds": round(len(edited)/RATE, 3),
                                  "active_rms_db": round(20*math.log10(active_rms(edited)), 2),
                                  "peak_db": round(20*math.log10(max(abs(x) for x in edited)), 2)}
    (SCRATCH / "mastering_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
