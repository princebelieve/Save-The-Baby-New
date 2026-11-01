# Release status — 1 November 2026

This is a polished development build, not a certified Play Store release or a claim of parity with Candy Crush or Gossip Harbor.

## Campaign contract

The 50 authored levels are the current validation pack. The campaign is extensible: level discovery reads the levels directory, saves retain stable level identifiers, and completing the latest available case returns to the map. There is no level-50 game ending. Add further level/chapter data to continue the same campaign.

## Implemented in this pass

- Campaign saves use a temporary replacement file and a previous-save backup; unreadable primary saves recover from that backup.
- Life regeneration survives restarts, accounts for offline time, and starts a fresh countdown when spending a life from a full meter.
- Route choices, completed tutorials, independent audio volumes, and music/effects toggles persist.
- Music starts from the title and campaign map, including saved-route continuation, and repeated requests do not restart the same track. Missing audio buses are created safely.
- Special swaps enforce adjacency and resolve fully before unlocking or emitting one completed-turn signal. Rocket/rocket, rocket/bomb, bomb/bomb, bomb/thunder, and thunder/thunder combinations and chained specials resolve together. Thunder targets the swapped partner's color.
- Dead boards shuffle into stable, playable layouts; if necessary, normal pieces regenerate without resetting objectives, obstacles, or remaining moves.
- Touch input tracks one finger and ignores synthesized duplicate mouse events. Canceled gestures and booster targeting no longer leave input stuck.
- Board sizing reserves space for the HUD and booster tray on short, standard, and tall portrait viewports.
- Chapter art paths, chapter title legibility, booster counts, pause/tutorial layering, and settings touch targets were corrected. UI typography uses the supplied Baloo font.
- Boot assigns the active game scene correctly so returning to the title can reload it. Economy/reward/helper node ownership was corrected to avoid leaking them across reloads.
- Release exports include JSON content and exclude test scenes and development documents. A Windows release preset was added.

## Verification

`tests/release_checks.tscn` verifies save recovery; offline lives; independent persisted audio; all 50 board openings and chapter-art references; representative animated turns; special combinations and turn timing; dead-board recovery; three phone aspect ratios; booster cancellation; title-to-map continuation; and a playable level-51 map entry.

Tests require an isolated profile and refuse to run against the normal player-data directory. From PowerShell:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.test-data'
& 'C:\Users\ASUS\My Tools\Godot\4.6.3\Godot_v4.6.3-stable_win64.exe' --headless --path . res://tests/release_checks.tscn
```

Use a separate PowerShell session for that command, or restore APPDATA afterward. `tools/run_checks.ps1` automates the temporary profile when local PowerShell execution policy allows scripts.

The corrupt-save test intentionally produces one ConfigFile parse diagnostic before successful backup recovery. This Windows environment also reports a root-certificate-store diagnostic. Neither is a successful hardware-audio or Android-device test.

Actual rendered title, campaign, gameplay, and pause screens were inspected. The visual-review scene is excluded from release exports. The Windows release exported and was smoke-tested headlessly. Forced process shutdown still reports an ObjectDB/resource cleanup warning; the regression suite explicitly frees its game scene, lets timers retire, and exits without that warning. Hardware audio output remains unverified. Rebuild after further source changes.

## Remaining release work

- Android AAB export reached Gradle but was blocked by a cache-write permission error. Permission to rerun outside the sandbox was declined. No validated Android release bundle is claimed.
- Physical-device performance, audible output, touch ergonomics, interruptions, storage failures, and a full player progression/balance pass remain required.
- Obstacle-specific behavior, including configured countdown threats and key-only locks, still needs implementation/content review; the current starter obstacles predominantly take adjacent-match damage.
- Final art consistency, accessibility/localization coverage, store listing/support/privacy materials, and release signing/device distribution need review before publishing.
- Ads and online services remain staged roadmap features, not implemented production services.
