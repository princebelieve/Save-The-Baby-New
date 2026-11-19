"""Generate original looping music with shared harmony and event-specific arrangements."""
import math, wave, struct, json
from pathlib import Path
RATE=22050
BPM=96
BEAT=60/BPM
SECONDS=BEAT*32
CHORDS=[(57,60,64),(53,57,60),(48,52,55),(55,59,62)]
def hz(n): return 440*2**((n-69)/12)
def render(name, energy, major=False):
    out=Path('assets/audio/music')/('case_'+name+'.wav')
    samples=[]
    for i in range(int(RATE*SECONDS)):
        t=i/RATE; beat=t/BEAT; bar=int(beat//4)%4
        chord=CHORDS[(bar+2)%4] if major else CHORDS[bar]
        pad=sum(math.sin(2*math.pi*hz(n)*t) for n in chord)/3
        pulse=(beat%1); envelope=math.exp(-pulse*7)
        note=chord[int(beat*2)%3]+12
        pluck=math.sin(2*math.pi*hz(note)*t)*math.exp(-(beat*2%1)*7)
        bass=math.sin(2*math.pi*hz(chord[0]-12)*t)*envelope
        # Deliberate phrase-length loop, with quiet boundary fades.
        edge=min(1,t/.04,(SECONDS-t)/.04)
        v=(pad*.09+pluck*(.035+energy*.07)+bass*energy*.08)*edge
        samples.append(v)
    peak=max(abs(v) for v in samples)
    gain=min(1,.32/max(peak,.001))
    with wave.open(str(out),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',round(v*gain*32767)) for v in samples))
    return {'path':'res://'+str(out).replace('\\','/'),'loop':True}
if __name__=='__main__':
    p=Path('configs/audio.json'); config=json.loads(p.read_text())
    for name,energy,major in [('investigation',.15,False),('play',.5,False),('pressure',.9,False),('victory',.5,True),('setback',.05,False),('restoration',.3,False)]:
        config['music']['case_'+name]=render(name,energy,major)
    p.write_text(json.dumps(config,indent=2)+'\n')
