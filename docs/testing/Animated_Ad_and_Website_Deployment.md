# Animated ad and website deployment — 12 November 2026

## Delivered ad creative

- `exports/marketing-v9/Save-The-Baby-Animated-Ad-Portrait.mp4`: 1080×1920, H.264/AAC, 26.80 seconds.
- `exports/marketing-v9/Save-The-Baby-Animated-Ad-YouTube.mp4`: 1920×1080, H.264/AAC, 26.80 seconds.
- Text slides in/out with alpha fades. Scenes crossfade for 0.35 seconds; game audio crossfades between clips. The end card fades and moves gently.
- Uses the actual game recording, including restoration and its rewards, boosters, David/Amara and victory settlement. Prepared demonstration scenarios are documented with the source capture.
- Both video files were fully decoded successfully, and audio was verified (mean approximately −22.8 dB). Extracted text-entry, full-text, transition and end-card frames were visually inspected.
- These are video creatives, not interactive playable ads. A drawn install button in an MP4 becomes actionable only through the advertising platform's clickable CTA overlay or a linked end card.

Sources: `tools/create_animated_ad.py`, `tools/verify_animated_ad.py`. Verification: `exports/marketing-v9/animated-ad-checks.json`.

## Git-based website update

The Documents folder provided earlier was a source copy without Git history. Located the existing repository at `https://github.com/princebelieve/sbibhadodetecchnologies` and cloned it into the isolated `.tmp/company-website-git` directory. The current Git version contained additional story content; that was preserved.

Committed and pushed only `save-the-baby.html` to the existing `main` branch:

- Commit: `c93c798` — Add Google Play download button to game page.
- Prominent button sits before the long story section and links to `com.savethebaby.game` on Google Play.
- Page title uses the owner-approved Save The Baby: Match 3 Rescue name.
- The existing routing configuration and other site files were preserved.

GitHub's Vercel status returned success / Deployment has completed. Public HTTP verification returned 200, confirmed the Play Store button, correct package link and approved title at `https://sbi.globalcreest.com/save-the-baby`.

No direct Vercel deployment was used. The Vercel integration connection was offered for future access to settings/logs; connecting it was not required for the successful Git-triggered deployment.

## What a playable ad requires

A playable is a small HTML5 interactive experience bundled for an advertising network, not the Android APK. A limited match-3 or restoration puzzle can demonstrate the same mechanics, then show an install CTA that opens the store after a tap. Platform requirements differ: Google App campaigns accept supported HTML5 ZIP assets; Unity Ads requires an offline self-contained MRAID-compatible build. Publishing and campaign spend are separate from producing the creative.

References: [Google playable assets](https://support.google.com/google-ads/answer/9981650), [Unity playable requirements](https://docs.unity.com/en-us/grow/acquire/creatives/playable/specifications), [Vercel Git deployment](https://vercel.com/docs/git).
