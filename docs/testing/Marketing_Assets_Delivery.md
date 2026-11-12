# Marketing assets delivered — 12 November 2026

Created from actual graphical Godot runs using Compatibility rendering, isolated demonstration profiles and the game's own music/effects. Player saves were not used. Restoration and victory use preconfigured demonstration states to show existing mechanics; this is an edited preview rather than a continuous unaided playthrough.

Location: `exports/marketing-v9/` (generated media excluded from Git and Godot imports).

- 20 original game captures, converted to 1080×1920 RGB PNGs under `unframed/`.
- 8 framed 1080×1920 RGB store images under `phone/`.
- `play-store-screenshots.zip`: all 28 images, with ZIP integrity checked.
- `screenshots-preview.jpg`: review contact sheet.
- `Save-The-Baby-Match-3-Rescue-Trailer-YouTube.mp4`: approximately 42 seconds, 1920×1080, H.264/AAC.
- `Save-The-Baby-Match-3-Rescue-Trailer-Portrait.mp4`: approximately 42 seconds, 1080×1920, H.264/AAC.
- YouTube thumbnail and copy-ready title/description under `UPLOAD-TO-YOUTUBE.txt`.

Content includes active matching, all three booster effects, Ethan, David's first-match instruction, David/Amara story screens, chapter introduction, restoration swaps and their real reward screen, remaining-move/booster settlement and victory. Native screenshot pixels were captured at 1080×1920. Godot's source movie initialized at its default 600×1067 recording size; delivered videos are encoded at the stated HD output sizes. No claim of native full-HD source movie resolution is made.

Both delivered videos were completely decoded successfully. Audio is present, with mean level approximately −21.5 dB; the final three-second end card is silent. PNG dimensions/mode and archive entries are verified. Extracted gameplay/lesson/restoration frames and screenshot contact sheet were visually inspected. Godot reports the known Windows certificate-store diagnostic and shutdown resource warnings; no capture script failures occurred in the final runs.

Reproducible sources: `tests/marketing_capture.gd`, `tests/marketing_victory_capture.gd`, `tools/assemble_marketing.py`, `tools/verify_marketing.py`. Local encoder dependencies are in `.tmp/media-python`, outside shipped game content.

## Company website

Updated `C:\Users\ASUS\Documents\sibibhadodetecnologies\save-the-baby.html`: prominent accessible Play Store button links to `com.savethebaby.game`; approved descriptive title applied. Verified the anchor with an HTML parser. Removed an invalid null redirect from that project's `vercel.json` and validated JSON parsing. No other site content was changed.

Vercel is available as an integration but was not connected during this work; no local Vercel authentication was found in the checked standard app-data locations. The source changes are saved, but live deployment has not been performed. No Play listing media or YouTube video was published.
