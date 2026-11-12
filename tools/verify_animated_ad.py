"""Decode the animated ad, verify audio and export transition review frames."""
from pathlib import Path
import json,re,subprocess,sys
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'.tmp/media-python'))
import imageio_ffmpeg
OUT=ROOT/'exports/marketing-v9'
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
report=[]
for kind,size in [('Portrait','1080x1920'),('YouTube','1920x1080')]:
    path=OUT/f'Save-The-Baby-Animated-Ad-{kind}.mp4'
    result=subprocess.run([ffmpeg,'-hide_banner','-i',str(path),'-af','volumedetect','-f','null','-'],capture_output=True,text=True)
    assert result.returncode==0,result.stderr[-1200:]
    assert size in result.stderr and 'Video: h264' in result.stderr and 'Audio: aac' in result.stderr
    audio=re.search(r'mean_volume: ([\-\w.]+) dB',result.stderr)
    assert audio and audio.group(1)!='-inf'
    report.append({'file':path.name,'bytes':path.stat().st_size,'size':size,'duration':re.search(r'Duration: ([\d:.]+)',result.stderr).group(1),'audio_mean_db':float(audio.group(1)),'decoded_successfully':True})
review=OUT/'raw/animated-ad/review'
review.mkdir(exist_ok=True)
for name,seconds in [('entering-text',.24),('full-text',1.2),('crossfade',3.8),('restoration',15.8),('end-card',25)]:
    target=review/(name+'.jpg')
    subprocess.run([ffmpeg,'-hide_banner','-loglevel','error','-y','-ss',str(seconds),'-i',str(OUT/'Save-The-Baby-Animated-Ad-Portrait.mp4'),'-frames:v','1',str(target)],check=True)
(OUT/'animated-ad-checks.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
