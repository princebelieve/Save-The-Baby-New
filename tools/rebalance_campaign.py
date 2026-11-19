"""Apply bounded, progressive campaign tuning once; preserve opening lessons."""
import json
from pathlib import Path
REVISION=1

def tune(d):
    meta=d.setdefault('metadata',{})
    if meta.get('balance_revision')==REVISION: return False
    level=int(d['level_id'])
    if level<=20:return False
    difficulty=str(d.get('difficulty','')).upper()
    base=int(d['moves']['total'])
    reduction=0 if level<=30 else (1 if difficulty=='EASY' else 2)
    if level>=101 and difficulty in ('HARD','VERY_HARD','CRITICAL_CASE'):reduction=3
    d['moves']['total']=max(16,base-reduction)
    # Keep the board readable: reinforce selected existing positions, without
    # adding more blockers or changing destruction objective counts.
    count=0 if level<24 else 1
    if level>=101 and difficulty not in ('EASY','NORMAL'):count=2
    if level>=301 and difficulty in ('HARD','VERY_HARD','CRITICAL_CASE'):count=3
    if difficulty=='EASY':count=0
    changed=[]
    for o in d.get('obstacles',{}).get('items',[]):
        if len(changed)>=count:break
        if int(o.get('health',1))==1 and not o.get('inventory_only',False):
            changed.append({'x':o['x'],'y':o['y'],'health':1})
            o['health']=2
    meta['balance_revision']=REVISION
    meta['balance_base_moves']=base
    meta['balance_reinforced_cells']=changed
    return True
if __name__=='__main__':
    count=0
    for p in sorted(Path('levels').glob('level*.json')):
        d=json.loads(p.read_text())
        if tune(d):
            p.write_text(json.dumps(d,indent=2)+'\n');count+=1
    print('Progressively tuned',count,'levels; levels 1?20 preserved')
