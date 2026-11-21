"""Create a 16:9 ad that features the Google Play feature graphic as the banner."""
from pathlib import Path
import json
import subprocess

from create_landscape_ad import ROOT, OUT, WORK, FONT, FFMPEG, Image, ImageDraw, ImageFont, ImageOps, encode

BANNER = ROOT / "exports/play-store-listing/feature-graphic-1024x500.png"
SIZE = (1920, 1080)


def font(size):
    return ImageFont.truetype(str(FONT), size)


def card(kind):
    image = Image.new("RGB", SIZE, (9, 28, 44))
    draw = ImageDraw.Draw(image)
    # Soft gold and teal framing keeps the original feature graphic intact.
    draw.rounded_rectangle((45, 38, 1875, 930), radius=42, fill=(23, 58, 75), outline=(255, 196, 80), width=5)
    banner = Image.open(BANNER).convert("RGB")
    banner = ImageOps.contain(banner, (1780, 870), method=Image.Resampling.LANCZOS)
    x, y = (SIZE[0] - banner.width) // 2, 50 + (860 - banner.height) // 2
    image.paste(banner, (x, y))
    if kind == "opening":
        message = "A MATCH-3 RESCUE ADVENTURE"
        cta = "MATCH CLUES  •  RESTORE EVIDENCE  •  FOLLOW THE STORY"
    else:
        message = "THE SEARCH CONTINUES"
        cta = "PLAY SAVE THE BABY ON GOOGLE PLAY"
    draw = ImageDraw.Draw(image)
    draw.text((960, 978), message, font=font( forty := 40), fill=(255, 213, 112), anchor="mm")
    draw.text((960, 1033), cta, font=font(27), fill=(255, 248, 228), anchor="mm")
    return image


def still_clip(source, output, duration, label):
    source.save(WORK / f"{label}.png")
    args = ["-loop", "1", "-framerate", "30", "-i", str(WORK / f"{label}.png"),
            "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", str(duration),
            "-vf", "zoompan=z='min(zoom+0.00012,1.025)':d=1:s=1920x1080:fps=30,fade=t=in:d=0.35,fade=t=out:st=3.1:d=0.35,format=yuv420p",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-threads", "4",
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2", str(output)]
    encode(args, label)


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    opening, closing = WORK / "banner-opening.mp4", WORK / "banner-closing.mp4"
    still_clip(card("opening"), opening, 3.5, "banner-opening")
    still_clip(card("closing"), closing, 3.5, "banner-closing")
    gameplay = OUT / "Save-The-Baby-Landscape-Ad.mp4"
    output = OUT / "Save-The-Baby-Landscape-Banner-Ad.mp4"
    args = ["-i", str(opening), "-i", str(gameplay), "-i", str(closing)]
    graph = (
        "[0:v]settb=AVTB,setpts=PTS-STARTPTS,fps=30[v0];"
        "[0:a]asetpts=PTS-STARTPTS[a0];"
        "[1:v]settb=AVTB,setpts=PTS-STARTPTS,fps=30[v1];"
        "[1:a]asetpts=PTS-STARTPTS[a1];"
        "[2:v]settb=AVTB,setpts=PTS-STARTPTS,fps=30[v2];"
        "[2:a]asetpts=PTS-STARTPTS[a2];"
        "[v0][v1]xfade=transition=fade:duration=0.4:offset=3.1[x1];"
        "[a0][a1]acrossfade=d=0.4:c1=tri:c2=tri[y1];"
        "[x1][v2]xfade=transition=fade:duration=0.4:offset=25.7[x2];"
        "[y1][a2]acrossfade=d=0.4:c1=tri:c2=tri[y2]"
    )
    encode([*args, "-filter_complex_threads", "2", "-filter_complex", graph, "-map", "[x2]", "-map", "[y2]",
            "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-threads", "4", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart", str(output)], "banner-final")
    info = {"file": output.name, "resolution": "1920x1080", "fps": 30, "duration_seconds": 29.3,
            "banner": "exports/play-store-listing/feature-graphic-1024x500.png",
            "composition": "full feature graphic opening and end card; true landscape Godot gameplay between; no portrait blur-fill",
            "published": False}
    (OUT / "landscape-banner-ad-manifest.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(info, indent=2))


if __name__ == "__main__":
    main()
