"""Create a true 16:9 Google Ads video from Godot gameplay captures."""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".tmp/media-python"))
from PIL import Image, ImageDraw, ImageFont, ImageOps
import imageio_ffmpeg

OUT = ROOT / "exports/marketing-v9"
WORK = OUT / "raw/landscape-ad"
FONT = ROOT / "assets/fonts/Baloo2-Variable.ttf"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
SIZE = (1920, 1080)
NAVY = (13, 34, 50)
CREAM = (255, 246, 224)
GOLD = (255, 195, 79)
TEAL = (37, 174, 187)


def font(size):
    return ImageFont.truetype(str(FONT), size)


def wrap(draw, text, face, width):
    words = text.split()
    lines, current = [], ""
    for word in words:
        candidate = (current + " " + word).strip()
        if draw.textbbox((0, 0), candidate, font=face)[2] <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def background():
    image = Image.new("RGB", SIZE)
    pix = image.load()
    for y in range(SIZE[1]):
        t = y / (SIZE[1] - 1)
        color = tuple(round(NAVY[i] * (1 - t) + (22, 68, 83)[i] * t) for i in range(3))
        for x in range(SIZE[0]):
            pix[x, y] = color
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rectangle((608, 0, 623, 1080), fill=(*GOLD, 255))
    draw.rectangle((624, 0, 1920, 14), fill=(*TEAL, 255))
    draw.ellipse((1510, -260, 2080, 310), fill=(255, 195, 79, 13))
    draw.ellipse((980, 760, 1400, 1180), fill=(37, 174, 187, 12))
    return image


def add_card(canvas, image_path):
    card = Image.open(image_path).convert("RGB")
    card = ImageOps.fit(card, (530, 298), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    mask = Image.new("L", card.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 529, 297), radius=22, fill=255)
    canvas.paste(card, (1310, 358), mask)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((1307, 355, 1843, 659), radius=24, outline=GOLD, width=4)


def make_panel(scene, index, total):
    image = background()
    d = ImageDraw.Draw(image)
    d.text((700, 82), "SAVE THE BABY", font=font(42), fill=GOLD)
    d.rounded_rectangle((700, 144, 1112, 193), radius=20, fill=(*TEAL, 255))
    d.text((722, 150), "MATCH 3  •  STORY  •  RESTORATION", font=font(20), fill=NAVY)
    title_face = font(61)
    y = 255
    for line in wrap(d, scene["title"], title_face, 570):
        d.text((700, y), line, font=title_face, fill=CREAM, stroke_width=1, stroke_fill=NAVY)
        y += 76
    body_face = font(31)
    y += 10
    for line in wrap(d, scene["body"], body_face, 550):
        d.text((704, y), line, font=body_face, fill=(220, 230, 226))
        y += 44
    add_card(image, ROOT / scene["still"])
    d = ImageDraw.Draw(image)
    d.text((1310, 690), scene["card_label"], font=font(25), fill=GOLD)
    d.rounded_rectangle((700, 820, 1840, 824), radius=2, fill=(*GOLD, 180))
    d.text((700, 852), "A continuing rescue mystery. Every level moves the search forward.", font=font(27), fill=CREAM)
    d.text((700, 1001), f"SAVE THE BABY  /  {index:02d} — {total:02d}", font=font(18), fill=(164, 190, 192))
    return image


def make_endcard():
    image = background()
    d = ImageDraw.Draw(image)
    d.text((710, 155), "SAVE THE BABY", font=font(84), fill=GOLD)
    d.text((716, 270), "MATCH 3  •  STORY  •  RESTORATION", font=font(32), fill=TEAL)
    d.text((716, 415), "The search continues.", font=font(58), fill=CREAM)
    d.text((720, 510), "Play the puzzle adventure.", font=font(36), fill=(220, 230, 226))
    d.rounded_rectangle((714, 650, 1205, 744), radius=28, fill=(*GOLD, 255))
    d.text((770, 666), "PLAY ON GOOGLE PLAY", font=font(36), fill=NAVY)
    add_card(image, ROOT / "exports/marketing-v9/raw/08-gameplay.png")
    d = ImageDraw.Draw(image)
    d.text((1310, 690), "REAL GODOT GAMEPLAY", font=font(25), fill=GOLD)
    d.text((716, 917), "Meet Amara and David. Match clues. Restore the evidence.", font=font(27), fill=CREAM)
    return image


def encode(args, name):
    with (WORK / (name + ".log")).open("w", encoding="utf-8") as log:
        result = subprocess.run([FFMPEG, "-hide_banner", "-y", *args], stdout=log, stderr=log)
    if result.returncode:
        raise RuntimeError(f"Encoding failed; see {WORK / (name + '.log')}")


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    scenes = [
        {"name": "story", "source": "raw/gameplay.avi", "start": 6.3, "duration": 5.0,
         "title": "A rescue story begins", "body": "Join Amara and David as they search for Ethan and follow a trail of clues.",
         "still": "exports/marketing-v9/raw/02-david-story.png", "card_label": "MEET DAVID AND AMARA"},
        {"name": "match", "source": "raw/gameplay.avi", "start": 25.4, "duration": 4.2,
         "title": "Match 3. Follow the clues.", "body": "Make smart matches and push the investigation forward, one level at a time.",
         "still": "exports/marketing-v9/raw/08-gameplay.png", "card_label": "PUZZLES WITH A PURPOSE"},
        {"name": "boosters", "source": "raw/gameplay.avi", "start": 36.5, "duration": 2.4,
         "title": "Blast through blockers", "body": "Fire rockets, bombs and thunder to clear the board and collect clues.",
         "still": "exports/marketing-v9/raw/09-thunder-blast.png", "card_label": "ROCKETS  •  BOMBS  •  THUNDER"},
        {"name": "restore", "source": "raw/gameplay.avi", "start": 43.5, "duration": 6.2,
         "title": "Restore the evidence", "body": "Piece damaged images together and uncover details hidden in the case.",
         "still": "exports/marketing-v9/raw/11-restoration.png", "card_label": "A DIFFERENT KIND OF PUZZLE"},
        {"name": "rewards", "source": "raw/gameplay.avi", "start": 51.8, "duration": 3.2,
         "title": "Every win helps", "body": "Collect rewards and useful boosters as the rescue mystery unfolds.",
         "still": "exports/marketing-v9/raw/13-restoration-reward.png", "card_label": "RESTORE  •  COLLECT  •  CELEBRATE"},
    ]
    panel_paths = []
    for i, scene in enumerate(scenes, 1):
        panel_path = WORK / f"panel-{i:02d}.png"
        make_panel(scene, i, len(scenes)).save(panel_path)
        panel_paths.append(panel_path)
        src = OUT / scene["source"]
        target = WORK / f"scene-{i:02d}.mp4"
        graph = (
            "[0:v]fps=30,scale=608:1080:flags=lanczos,setsar=1[game];"
            "[1:v]format=rgba[panel];[panel][game]overlay=0:0:shortest=1,format=yuv420p[v]"
        )
        encode(["-ss", str(scene["start"]), "-t", str(scene["duration"]), "-i", str(src),
                "-loop", "1", "-framerate", "30", "-i", str(panel_path),
                "-filter_complex", graph, "-map", "[v]", "-map", "0:a:0", "-t", str(scene["duration"]),
                "-r", "30", "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-threads", "4",
                "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2",
                str(target)], f"scene-{i:02d}")
    end_png = WORK / "endcard.png"
    make_endcard().save(end_png)
    end_mp4 = WORK / "endcard.mp4"
    encode(["-loop", "1", "-framerate", "30", "-i", str(end_png), "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
            "-t", "3.5", "-vf", "fade=t=in:d=0.3,fade=t=out:st=3.1:d=0.3,format=yuv420p",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-threads", "4", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2", str(end_mp4)], "endcard")
    clips = [WORK / f"scene-{i:02d}.mp4" for i in range(1, len(scenes) + 1)] + [end_mp4]
    durations = [s["duration"] for s in scenes] + [3.5]
    args = []
    for clip in clips:
        args += ["-i", str(clip)]
    filters = []
    for i in range(len(clips)):
        filters += [f"[{i}:v]settb=AVTB,setpts=PTS-STARTPTS,fps=30[v{i}]",
                    f"[{i}:a]asetpts=PTS-STARTPTS[a{i}]"]
    video, audio, elapsed = "v0", "a0", durations[0]
    for i in range(1, len(clips)):
        filters.append(f"[{video}][v{i}]xfade=transition=fade:duration=0.3:offset={elapsed-0.3}[vx{i}]")
        filters.append(f"[{audio}][a{i}]acrossfade=d=0.3:c1=tri:c2=tri[ax{i}]")
        video, audio = f"vx{i}", f"ax{i}"
        elapsed += durations[i] - 0.3
    output = OUT / "Save-The-Baby-Landscape-Ad.mp4"
    encode([*args, "-filter_complex_threads", "2", "-filter_complex", ";".join(filters),
            "-map", f"[{video}]", "-map", f"[{audio}]", "-c:v", "libx264", "-preset", "veryfast",
            "-crf", "20", "-threads", "4", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
            "-ar", "48000", "-ac", "2", "-movflags", "+faststart", str(output)], "final")
    info = {"file": output.name, "resolution": "1920x1080", "fps": 30, "duration_seconds": round(elapsed, 2),
            "composition": "native landscape layout with full-height live Godot gameplay, separate story/features panel, and real gameplay stills; no blurred portrait fill",
            "source": "Godot gameplay capture and project screenshots", "published": False}
    (OUT / "landscape-ad-manifest.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(info, indent=2))


if __name__ == "__main__":
    main()
