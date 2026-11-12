"""Decode delivered videos, check screenshot dimensions and extract review frames."""
from pathlib import Path
import json
import re
import subprocess
import sys
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT/'.tmp/media-python'))
from PIL import Image
import imageio_ffmpeg
OUT=ROOT/'exports/marketing-v9'
encoder=imageio_ffmpeg.get_ffmpeg_exe()
results={"screenshots":[],"videos":[]}
for path in sorted((OUT/'phone').glob('*.png')):
    with Image.open(path) as im:
        assert im.size==(1080,1920) and im.mode=='RGB'
        results['screenshots'].append({"file":path.name,"size":list(im.size),"mode":im.mode})
assert len(results['screenshots'])==8
for suffix,expected in [('Portrait',(1080,1920)),('YouTube',(1920,1080))]:
    path=OUT/f'Save-The-Baby-Match-3-Rescue-Trailer-{suffix}.mp4'
    proc=subprocess.run([encoder,'-hide_banner','-i',str(path),'-af','volumedetect','-f','null','-'],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    assert proc.returncode==0,proc.stderr[-1000:]
    assert 'h264' in proc.stderr and 'Audio: aac' in proc.stderr
    assert f'{expected[0]}x{expected[1]}' in proc.stderr
    assert 'moov atom not found' not in proc.stderr
    mean=re.search(r'mean_volume: ([\-\w.]+) dB',proc.stderr)
    assert mean and mean.group(1)!='-inf','The trailer must have audible game audio'
    results['videos'].append({"file":path.name,"bytes":path.stat().st_size,"size":list(expected),"decoded_successfully":True,"audio_mean_db":float(mean.group(1)),"duration":re.search(r'Duration: ([\d:.]+)',proc.stderr).group(1)})
for name,time in [('gameplay',2),('lesson',8),('restoration',25),('victory',35)]:
    target=OUT/'raw'/f'video-review-{name}.jpg'
    subprocess.run([encoder,'-hide_banner','-loglevel','error','-y','-ss',str(time),'-i',str(OUT/'Save-The-Baby-Match-3-Rescue-Trailer-Portrait.mp4'),'-frames:v','1',str(target)],check=True)
(OUT/'delivery-checks.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
