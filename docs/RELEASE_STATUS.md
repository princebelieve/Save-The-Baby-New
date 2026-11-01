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


## Academy revision ? November 2, 2026

Reauthored the validation pack with balanced evidence spawn weights, larger collection goals, staged booster visibility, and increasing blocker count/durability. New mechanics are explained before interaction, with guided targeting at levels 4/6/8 and blocker practice at 9/12/16/20. Level 41 now applies established skills. `configs/academy.json` contains the curriculum; no ending was added at level 50.

Tutorial banners paginate short readable copy with Next/Continue and X. Skipping clears input restrictions and waits for an in-flight move to settle. Presented lessons, practice notes and map instructions are saved in Amara's case file. Individual case cards open illustrated paged popups with corner navigation and a close button. Interrupted and completed lessons have separate saved state.

Every chapter offers three new choices. Consequence previews support Back and confirmation; choices persist individually and select distinct narrative branches in later chapters. Route decisions do not change puzzle content or move budgets.

Rendered pointer-input walkthroughs passed the curriculum, card details, all three booster exercises, and all six chapter decisions at normal and short portrait sizes. The release regression suite passed after updating move-budget fixtures. `tests/academy_content_checks.py` enforces teaching order as content grows. A deterministic 21-run diagnostic found no first-turn wins; later cases still defeated a simple goal-first bot in several samples. Human difficulty testing remains required. Audio source files were preserved byte-for-byte.


## Illustrated popups and returning-player tutorial fix

Tutorials, case-file details and choice confirmations now share an illustrated mint-and-gold popup card with David, contextual art, short copy, previous/next corner controls and a top-right X. Action instructions use a smaller card positioned clear of their target. Existing artwork is reused; no audio changes were made.

Fixed a returning-player path at level 8: a completed practice flag could skip the practice while leaving the academy card visible. Final acknowledgement now hides its card before advancing state, and a skipped/completed practice explicitly clears the overlay. The rendered walkthrough covers both fresh practice and the existing-completion save path, previous-page navigation, closing details and confirming choices. A layout assertion prevents the large popup's text width from leaking into compact action cards.


## Scope correction: gameplay guidance and discovered-skill journal

The illustrated popup is now a separate `IllustratedPopup` class used for case-file details and story choices. `TutorialOverlay` restores the compact guided speech bubble, spotlight and gesture, with complete action instructions. Both retain the final-Continue dismissal fix.

`CaseJournal` records explicitly mapped facts when their tutorial page is presented or the player performs the corresponding skill. Stable skill/fact IDs prevent duplicate cards and repeated paraphrases. Titles and illustrations are assigned in content rather than inferred by scanning unrelated text. The case file no longer shows seeded evidence references, full unseen lessons, raw practice logs or generic factory recaps. Old save fields are retained but those placeholder sections are not rendered. Actual confirmed story decisions remain separate.

Regression coverage checks unread/skip behavior, repeated rules, journal persistence, card-label/art identity, interactive booster lessons, the returning-player level 8 path and all six story confirmations at normal and short sizes.
