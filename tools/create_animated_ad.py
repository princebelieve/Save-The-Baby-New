"""Render an ad cut with animated captions and real gameplay, without publishing."""
from pathlib import Path
import json
import subprocess
import sys
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'.tmp/media-python'))
from PIL import Image,ImageDraw,ImageFont,ImageOps
import imageio_ffmpeg
FFMPEG=imageio_ffmpeg.get_ffmpeg_exe()
OUT=ROOT/'exports/marketing-v9'
WORK=OUT/'raw/animated-ad'
FONT=str(ROOT/'assets/fonts/Baloo2-Variable.ttf')


def run(args,name):
    with (WORK/(name+'.log')).open('w',encoding='utf-8') as log:
        result=subprocess.run([FFMPEG,'-hide_banner','-y',*args],stdout=log,stderr=log)
    if result.returncode:raise RuntimeError('Encoding failed: '+str(WORK/(name+'.log')))


def text_layer(title,subtitle,target):
    image=Image.new('RGBA',(1080,220),(0,0,0,0))
    draw=ImageDraw.Draw(image)
    size=82
    def font(s):return ImageFont.truetype(FONT,s)
    while draw.textbbox((0,0),title,font=font(size))[2]>990:size-=2
    draw.text((540,83),title,font=font(size),fill='#fff4d9',anchor='mm',stroke_width=1,stroke_fill='#173143')
    draw.text((540,163),subtitle,font=font(39),fill='#ffc85a',anchor='mm')
    image.save(target)


def main():
    WORK.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((OUT/'capture-manifest.json').read_text())
    scenes={scene['name']:scene for scene in manifest['segments']}
    sequence=[
        ('matching',4.0,'CAN YOU HELP DAVID?','A match-3 rescue adventure'),
        ('rocket',2.3,'MATCH. BLAST. RESCUE.','Unleash your boosters'),
        ('thunder',2.3,'MAKE IT COUNT','Clear the way to Ethan'),
        ('story',3.6,'BRING ETHAN HOME','Follow David and Amara'),
        ('restoration',6.5,'RESTORE THE EVIDENCE','Swipe the pieces into place'),
        ('restoration-reward',3.2,'RESTORE. COLLECT. CELEBRATE.','Earn coins and useful boosters'),
        ('victory-bonus',3.7,'EVERY MOVE MATTERS','Watch your victory bonus grow'),
    ]
    durations=[]
    clips=[]
    for index,(name,desired,title,subtitle) in enumerate(sequence):
        scene=scenes[name]
        start=float(scene['start'])
        available=float(scene['duration'])-.035
        if name=='story':start+=3.85;available-=3.85
        duration=min(desired,available)
        durations.append(duration)
        layer=WORK/(name+'-text.png')
        text_layer(title,subtitle,layer)
        source=OUT/scene.get('source','raw/gameplay.avi')
        target=WORK/f'clip-{index:02d}.mp4'
        slide=f"if(lt(t,0.5),-W*pow(1-t/0.5,3),if(gt(t,{duration-.48}),W*pow((t-{duration-.48})/.48,3),0))"
        fadeout=max(.1,duration-.42)
        graph=(
            '[0:v]fps=30,scale=908:1614:force_original_aspect_ratio=decrease,'
            'pad=908:1614:(ow-iw)/2:(oh-ih)/2:color=0x102b43,setsar=1,'
            'pad=1080:1920:86:226:color=0x102b43,settb=AVTB[game];'
            f'[1:v]format=rgba,fade=t=in:st=0.1:d=0.35:alpha=1,fade=t=out:st={fadeout}:d=0.35:alpha=1[text];'
            f"[game][text]overlay=x='{slide}':y=0:shortest=1,format=yuv420p[v]"
        )
        run(['-ss',str(start),'-t',str(duration),'-i',str(source),'-loop','1','-framerate','30','-i',str(layer),'-filter_complex',graph,'-map','[v]','-map','0:a:0','-t',str(duration),'-r','30','-c:v','libx264','-preset','veryfast','-crf','21','-threads','4','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-ar','48000','-ac','2',str(target)],name)
        clips.append(target)
        print(f'Animated {name}: {duration:.2f}s',flush=True)
    # End card uses gentle motion plus a fade in/out.
    end=Image.open(OUT/'youtube-thumbnail.png').convert('RGB')
    endfile=WORK/'endcard.png'
    end.save(endfile)
    last=WORK/'endcard.mp4'
    run(['-loop','1','-framerate','30','-i',str(endfile),'-f','lavfi','-i','anullsrc=r=48000:cl=stereo','-t','3.6','-vf',"scale=1120:1992,crop=1080:1920:x='20+12*sin(t*1.8)':y='36+12*cos(t*1.8)',fade=t=in:d=0.4,fade=t=out:st=3.2:d=0.4,setsar=1",'-c:v','libx264','-preset','veryfast','-crf','21','-threads','4','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-ar','48000','-ac','2',str(last)],'endcard')
    clips.append(last);durations.append(3.6)
    overlap=.35
    args=[]
    for clip in clips:args+=['-i',str(clip)]
    filters=[]
    for i in range(len(clips)):
        filters.extend([f'[{i}:v]settb=AVTB,setpts=PTS-STARTPTS,fps=30[v{i}]',f'[{i}:a]asetpts=PTS-STARTPTS[a{i}]'])
    video='v0';audio='a0';elapsed=durations[0]
    for i in range(1,len(clips)):
        filters.append(f'[{video}][v{i}]xfade=transition=fade:duration={overlap}:offset={elapsed-overlap}[vx{i}]')
        filters.append(f'[{audio}][a{i}]acrossfade=d={overlap}:c1=tri:c2=tri[ax{i}]')
        video=f'vx{i}';audio=f'ax{i}';elapsed+=durations[i]-overlap
    portrait=OUT/'Save-The-Baby-Animated-Ad-Portrait.mp4'
    run([*args,'-filter_complex_threads','2','-filter_complex',';'.join(filters),'-map',f'[{video}]','-map',f'[{audio}]','-c:v','libx264','-preset','veryfast','-crf','21','-threads','4','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-ar','48000','-ac','2','-movflags','+faststart',str(portrait)],'portrait-final')
    landscape=OUT/'Save-The-Baby-Animated-Ad-YouTube.mp4'
    run(['-i',str(portrait),'-filter_complex','[0:v]split=2[a][b];[a]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=35:3,eq=brightness=-0.15[bg];[b]scale=-2:1080[fg];[bg][fg]overlay=(W-w)/2:0,format=yuv420p[v]','-map','[v]','-map','0:a','-c:v','libx264','-preset','veryfast','-crf','21','-threads','4','-c:a','copy','-movflags','+faststart',str(landscape)],'landscape-final')
    (OUT/'animated-ad-manifest.json').write_text(json.dumps({'files':[portrait.name,landscape.name],'planned_seconds':elapsed,'fps':30,'transitions':'0.35-second crossfades','text':'slide in, fade in, slide out, fade out','source':'actual Godot capture and recorded game audio; prepared demonstration scenarios','published':False},indent=2)+'\n')
    print(f'Animated ad complete: {elapsed:.2f}s',flush=True)


if __name__=='__main__':main()
