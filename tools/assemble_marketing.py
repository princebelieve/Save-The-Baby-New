"""Compose store images and encode a trailer from actual Godot captures."""
from pathlib import Path
import json
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".tmp/media-python"))
from PIL import Image, ImageDraw, ImageFont, ImageOps
import imageio_ffmpeg

OUT = ROOT / "exports/marketing-v9"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
FONT = str(ROOT / "assets/fonts/Baloo2-Variable.ttf")


def font(size):
    return ImageFont.truetype(FONT, size)


def background(caption, subtitle="MATCH 3 • STORY • RESTORATION"):
    canvas = Image.new("RGB", (1080, 1920))
    draw = ImageDraw.Draw(canvas)
    for y in range(1920):
        t = y / 1919
        draw.line((0, y, 1080, y), fill=tuple(round(a*(1-t)+b*t) for a,b in zip((20,43,67),(10,112,125))))
    draw.rounded_rectangle((45, 38, 1035, 207), radius=34, fill=(255,248,230))
    size = 74
    while draw.textbbox((0,0),caption,font=font(size))[2] > 940: size -= 2
    draw.text((540, 83),caption,font=font(size),fill=(53,38,33),anchor="mm")
    draw.text((540, 164),subtitle,font=font(31),fill=(107,66,125),anchor="mm")
    draw.text((540, 1883),"SAVE THE BABY: MATCH 3 RESCUE",font=font(30),fill=(255,232,171),anchor="mm")
    return canvas


def run(args, name):
    log = OUT / "raw" / (name + ".log")
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run([FFMPEG,"-hide_banner","-y",*args], stdout=stream, stderr=stream)
    if result.returncode:
        raise RuntimeError(f"Media encoding failed; see {log}")


def package_screenshots(manifest):
    native=OUT/'unframed'
    native.mkdir(exist_ok=True)
    for shot in manifest['shots']:
        path=OUT/'raw'/(shot['name']+'.png')
        Image.open(path).convert('RGB').save(native/path.name,optimize=True)
    with zipfile.ZipFile(OUT/'play-store-screenshots.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted((OUT/'phone').glob('*.png')):archive.write(path,path.name)
        for path in sorted(native.glob('*.png')):archive.write(path,'unframed/'+path.name)


def main():
    manifest = json.loads((OUT/"capture-manifest.json").read_text())
    assert all(shot["saved"] for shot in manifest["shots"])
    phone = OUT / "phone"
    phone.mkdir(exist_ok=True)
    working = OUT / "raw/edited"
    working.mkdir(exist_ok=True)
    selections = [
        ("08-gameplay","Match the clues"),
        ("09-thunder-blast","Unleash your boosters"),
        ("11-restoration","Restore the evidence"),
        ("06-david-lesson","Learn with David"),
        ("03-amara-instructions","Bring Ethan home"),
        ("13-restoration-reward","Restore. Collect. Celebrate."),
        ("15-victory","Celebrate every victory"),
        ("05-chapter","Follow the story"),
    ]
    previews = []
    for index,(name,caption) in enumerate(selections,1):
        canvas = background(caption)
        screen = Image.open(OUT/"raw"/(name+".png")).convert("RGB")
        assert screen.size == (1080,1920), (name, screen.size)
        screen = ImageOps.contain(screen,(930,1635),Image.Resampling.LANCZOS)
        canvas.paste(screen,((1080-screen.width)//2,228))
        target = phone/f"{index:02d}-{name}.png"
        canvas.save(target,optimize=True)
        previews.append(canvas)
    sheet = Image.new("RGB",(1440,1340),(17,36,54))
    for index,canvas in enumerate(previews):
        thumb=canvas.resize((324,576),Image.Resampling.LANCZOS)
        x=30+(index%4)*355
        y=35+(index//4)*650
        sheet.paste(thumb,(x,y))
        ImageDraw.Draw(sheet).text((x+162,y+600),str(index+1),font=font(30),anchor="mm",fill="white")
    sheet.save(OUT/"screenshots-preview.jpg",quality=92)
    package_screenshots(manifest)
    scenes={scene["name"]:scene for scene in manifest["segments"]}
    sequence=[("matching",4.0),("story",3.2),("lesson",3.2),("rocket",2.3),("bomb",2.3),("thunder",2.3),("ethan",2.7),("restoration",6.5),("restoration-reward",3.0),("chapter",2.7),("victory-bonus",4.0),("victory",2.7)]
    clip_files=[]
    durations=[]
    for index,(name,maximum) in enumerate(sequence):
        scene=scenes[name]
        duration=min(maximum,float(scene["duration"])-0.03)
        assert duration>0.1,(name,duration)
        frame=working/(name+"-background.png")
        background(scene["caption"]).save(frame)
        target=working/f"clip-{index:02d}.mp4"
        source=OUT/scene.get("source","raw/gameplay.avi")
        if target.exists() and target.stat().st_mtime > source.stat().st_mtime:
            clip_files.append(target)
            durations.append(duration)
            continue
        video_filter="[0:v]scale=900:1600:force_original_aspect_ratio=decrease,pad=900:1600:(ow-iw)/2:(oh-ih)/2:color=0x102b43,setsar=1[screen];[1:v][screen]overlay=90:238:shortest=1,format=yuv420p[v]"
        run(["-ss",str(scene["start"]),"-t",str(duration),"-i",str(source),"-loop","1","-i",str(frame),"-filter_complex",video_filter,"-map","[v]","-map","0:a:0","-af",f"afade=t=in:d=0.08,afade=t=out:st={max(0,duration-.12)}:d=0.12,alimiter=limit=0.95","-t",str(duration),"-r","30","-c:v","libx264","-preset","veryfast","-crf","21","-threads","4","-c:a","aac","-b:a","160k","-ar","48000","-ac","2","-movflags","+faststart",str(target)],name)
        clip_files.append(target)
        durations.append(duration)
        print(f"Encoded {name}: {duration:.1f}s",flush=True)
    end=background("Save The Baby", "MATCH 3 RESCUE")
    portrait=Image.open(ROOT/"assets/sprites/characters/amara_and_ethan_portrait_cutout.png").convert("RGBA")
    portrait=ImageOps.contain(portrait,(870,1080),Image.Resampling.LANCZOS)
    end.paste(portrait,((1080-portrait.width)//2,380),portrait)
    draw=ImageDraw.Draw(end)
    draw.text((540,1570),"Match clues. Rescue Ethan.",font=font(58),fill=(255,243,211),anchor="mm")
    draw.rounded_rectangle((170,1680,910,1790),radius=40,fill=(255,203,99))
    draw.text((540,1732),"Get it on Google Play",font=font(49),fill=(46,36,48),anchor="mm")
    endfile=OUT/"youtube-thumbnail.png"
    end.save(endfile)
    endclip=working/"end.mp4"
    run(["-loop","1","-i",str(endfile),"-f","lavfi","-i","anullsrc=r=48000:cl=stereo","-t","3","-r","30","-c:v","libx264","-preset","veryfast","-crf","21","-threads","4","-pix_fmt","yuv420p","-c:a","aac","-b:a","160k","-ar","48000","-ac","2",str(endclip)],"endcard")
    clip_files.append(endclip)
    listing=working/"concat.txt"
    listing.write_text("\n".join("file '"+str(path).replace("\\","/")+"'" for path in clip_files)+"\n")
    trailer=OUT/"Save-The-Baby-Match-3-Rescue-Trailer-Portrait.mp4"
    run(["-f","concat","-safe","0","-i",str(listing),"-c","copy","-movflags","+faststart",str(trailer)],"portrait-final")
    landscape=OUT/"Save-The-Baby-Match-3-Rescue-Trailer-YouTube.mp4"
    run(["-i",str(trailer),"-filter_complex","[0:v]split=2[a][b];[a]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=35:3,eq=brightness=-0.15[bg];[b]scale=-2:1080[fg];[bg][fg]overlay=(W-w)/2:0,format=yuv420p[v]","-map","[v]","-map","0:a","-c:v","libx264","-preset","veryfast","-crf","21","-threads","4","-c:a","copy","-movflags","+faststart",str(landscape)],"youtube-final")
    # A proper 16:9 upload thumbnail, using the approved brand and actual art.
    thumb=Image.new("RGB",(1920,1080),(17,43,63))
    art=ImageOps.contain(portrait,(860,980),Image.Resampling.LANCZOS)
    thumb.paste(art,(1010,80),art)
    d=ImageDraw.Draw(thumb)
    for text,y,size,color in [("SAVE THE BABY",320,108,(255,238,198)),("MATCH 3 RESCUE",470,76,(255,203,99)),("Match clues. Restore memories.",680,49,(220,247,245)),("Bring Ethan home.",760,64,(220,247,245))]:d.text((90,y),text,font=font(size),fill=color)
    thumb.save(OUT/"youtube-thumbnail-landscape.jpg",quality=95)
    summary={"screenshots":len(selections),"raw_captures":len(manifest["shots"]),"portrait_size":[1080,1920],"landscape_size":[1920,1080],"planned_seconds":sum(durations)+3,"video_files":[trailer.name,landscape.name],"source":"Godot Movie Maker capture; preconfigured isolated demonstration save","audio":"Captured game music and effects; silent three-second end card"}
    (OUT/"media-verification.json").write_text(json.dumps(summary,indent=2)+"\n")
    print(json.dumps(summary,indent=2))


if __name__=="__main__":main()
