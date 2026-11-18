"""Package the promotional preview for the website and two ad environments."""
from pathlib import Path
import base64
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools/playable'
OUT = ROOT / 'exports/marketing-v9/playable'
OUT.mkdir(parents=True, exist_ok=True)
FILES = {
    'logo': 'assets/sprites/ui/game_logo_cutout.png',
    'key': 'assets/sprites/powerups/tiles/key_objective_icon.jpeg',
    'fingerprint': 'assets/sprites/powerups/tiles/fingerprint_evidence_icon.jpeg',
    'document': 'assets/sprites/powerups/tiles/evidence_document_icon.jpeg',
    'recorder': 'assets/sprites/powerups/tiles/recorder_evidence_icon.jpeg',
    'timer': 'assets/sprites/powerups/tiles/timer_objective_icon.jpeg',
    'rocket': 'assets/sprites/powerups/rocket_powerup_icon.jpeg',
}
assets = {}
for name, file in FILES.items():
    path = ROOT / file
    mime = 'image/png' if path.suffix == '.png' else 'image/jpeg'
    assets[name] = f'data:{mime};base64,' + base64.b64encode(path.read_bytes()).decode()
template = (SOURCE / 'demo.html').read_text(encoding='utf-8')
template = template.replace('@@assets@@', json.dumps(assets))
for key, value in assets.items():
    template = template.replace('@@' + key + '@@', value)
template = template.replace('// ENGINE', (SOURCE / 'engine.js').read_text(encoding='utf-8'))
template = template.replace('// APP', (SOURCE / 'app.js').read_text(encoding='utf-8'))
manifest = {}
for mode in ['web', 'google', 'mraid']:
    html = template.replace('// CONFIG', f"const MODE='{mode}';const STORE='https://play.google.com/store/apps/details?id=com.savethebaby.game';")
    api = '<script src="https://tpc.googlesyndication.com/pagead/gadgets/html5/api/exitapi.js"></script>' if mode == 'google' else ''
    html = html.replace('<!-- AD_API -->', api)
    folder = OUT / mode
    folder.mkdir(exist_ok=True)
    target = folder / 'index.html'
    target.write_bytes(html.encode('utf-8'))
    assert target.stat().st_size < 5_000_000
    if mode == 'google':
        with zipfile.ZipFile(OUT / 'Save-The-Baby-Google-Ads-Playable.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
            archive.write(target, 'index.html')
    manifest[mode] = {'bytes': target.stat().st_size, 'path': str(target.relative_to(ROOT))}
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))
