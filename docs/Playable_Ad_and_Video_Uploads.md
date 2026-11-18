# Playable preview and upload destinations

Prepared 13 November 2026.

## What is available

- Website preview: `https://sbi.globalcreest.com/save-the-baby/play`.
- Homepage embeds the preview directly; the game page embeds both the preview and the animated video.
- Google Ads playable: `exports/marketing-v9/playable/Save-The-Baby-Google-Ads-Playable.zip`.
- Source: `tools/playable/`; rebuild with `python tools/build_playable.py`.
- The promotional preview is a separate small HTML5 implementation of real match-three swaps, key collection, cascades and rockets. It is not the full Godot game or a cloud-save session. It discloses that distinction and does not save progress, run ads, collect analytics or make purchases.
- The Google package uses Google's ExitApi for its post-game Install button. Google Ads supplies the campaign's store destination. The website version opens the actual Play Store link only on a tap after play.
- A separate MRAID adapter is generated for further network-specific testing. Its bridge behavior is tested locally; it has not been submitted for network approval or certified for every network's requirements.

## 1. Play Store preview video

Upload this file to YouTube:

`exports/marketing-v9/Save-The-Baby-Match-3-Rescue-Trailer-YouTube.mp4`

This is the longer gameplay trailer, approximately 42 seconds. Suggested title: `Save The Baby: Match 3 Rescue | Gameplay Trailer`.

Use `exports/marketing-v9/youtube-thumbnail-landscape.jpg` as its thumbnail. Make the upload Public or Unlisted, allow embedding, and answer YouTube's audience question accurately. For Play listing use, turn off video monetization if enabled and avoid age or territorial restrictions that prevent viewing.

Copy the resulting individual YouTube watch URL. In **Play Console → Save The Baby → Grow users → Store presence → Main store listing → Graphics → Preview video**, paste that URL and save. Submit the listing change through Publishing overview. Do not paste the MP4 file path, channel URL, playlist URL or game download link into Preview video.

## 2. Animated video advertisement

Upload this second file to YouTube:

`exports/marketing-v9/Save-The-Baby-Animated-Ad-YouTube.mp4`

This is the approximately 27-second animated ad with fades and moving text. Suggested title: `Save The Baby: Match 3 Rescue | Play, Match, Rescue`.

Use Public or Unlisted visibility. Copy its individual YouTube video URL. In a **Google Ads App campaign for app installs → Ad group → Ad assets → Videos**, add/select this YouTube video. The portrait alternative is `exports/marketing-v9/Save-The-Baby-Animated-Ad-Portrait.mp4`; it can be uploaded as an additional vertical video asset.

For the campaign's app selection, choose Android/Google Play and locate **com.savethebaby.game** using:

`https://play.google.com/store/apps/details?id=com.savethebaby.game`

The website already plays the animated MP4 directly. It does not require a YouTube URL to work.

## 3. Play-then-install advertisement

In that Google Ads app-install campaign's ad group, open the **HTML5** asset section and upload:

`exports/marketing-v9/playable/Save-The-Baby-Google-Ads-Playable.zip`

Upload the ZIP file itself, not the website URL. The package contains a single responsive UTF-8 `index.html`, is under 5 MB, and uses the official exit bridge. The intended store destination is the app selected for the campaign above.

If HTML5 assets are not offered, the campaign/account must be checked for that asset capability; a Play Console or AdMob field is not a substitute. Successful local tests do not constitute Google's ad moderation approval.

No campaign has been created, launched or funded. Review countries, budget and conversion settings before publishing an advertising campaign; running one incurs advertising costs.

## AdMob

These promotion assets are not uploaded to AdMob. AdMob manages advertisements shown *inside* your game and their earnings. Google Ads manages paid promotion to acquire players.

## Verification

Rule checks cover valid/invalid swaps, objective credit, free tray rocket, earned rocket creation, exhausted moves and reset. Chrome tests exercise four viewport sizes, end cards, replay, the website store link, Google ExitApi and MRAID ready/viewability/open behavior. Website tests cover the homepage/game-page frames on phone and desktop and verify video metadata. This is a staged promotional demo, not a claim of full campaign or restoration functionality in the browser.

References:

- https://support.google.com/google-ads/answer/9981650
- https://support.google.com/googleplay/android-developer/answer/9866151
- https://docs.unity.com/en-us/grow/acquire/creatives/playable/specifications
