# Advertising integration

Automatic interstitials are requested only when leaving a completed or failed level result, once per attempt. Story, map, loading, pause and briefing transitions never request ads. Completing a rewarded ad suppresses the result interstitial for that attempt. Missing inventory never blocks navigation.

Optional offers: first-clear bonus matching the level coin payout; five extra moves after failure (once per attempt, restoring the deducted life); one life in the life shop; one rocket, bomb, thunder or Ethan assist from its supply dialog. Supply/life offers are limited to once per board attempt. No ads in academy practice results. Rewards are saved through the existing campaign inventory flow. Stars and story progress are never sold as ad rewards.

## Installed integration

Poing Studios Godot AdMob 5.1.0 is vendored in `addons/admob`, with its editor mocks. Android is deliberately pinned to the official 4.3.1 bridge compiled for Godot 4.6.3, using Google play-services-ads 24.9.0 (the package listed in Google Playâ€™s Families self-certified SDK list). The Android installer and exporter preserve this pin; do not replace it with the Next-Gen bridge without checking certification and initialization compatibility. `AdProvider` is registered as an autoload, initializes consent and the SDK, preloads both formats, retries load failures after 60 seconds, discards ads after 50 minutes, and restores audio/pause state after dismissal or show failure. Ads remain unavailable on desktop by default. An explicit `--ad-preview` user argument enables the plugin mock ads only in a graphical debug run from the editor executable; this never runs on Android or in exported release builds.

Debug Android builds use Google's demo interstitial and rewarded units. Release Android builds use:

- App: `ca-app-pub-7480928068306811~8170975262`
- Interstitial: `ca-app-pub-7480928068306811/3957444262`
- Rewarded: `ca-app-pub-7480928068306811/7596260199`

Android exports use Gradle and minimum API 24. Install the Godot 4.6.3 Android build template when preparing a fresh checkout. Binaries and license are committed with the addon; Gradle downloads the Google SDK dependencies during export. iOS is disabled and has no configured App ID.

Vendor changes skip downloading unused iOS binaries when iOS is disabled (`binary_installer.gd`, `editor_menu.gd`), and skip desktop mock allocation in headless runs (`MobileSingletonPlugin.gd`). The Android addon ignore file was adjusted to retain installed AARs in source control.

## Account and device verification

The publisher must configure the applicable messages for this app in AdMob Privacy & messaging. Consent update/form errors do not bypass consent: ads remain unavailable until consent is obtained or not required. AD PRIVACY OPTIONS is available in settings when UMP requires it. This repository does not have access to the AdMob dashboard or publishing credentials.

The privacy policy source and generated HTML now describe advertising. Publish those updated legal pages at the URLs used by the store listing, and update Google Play's ads/Data safety declarations for the SDK before distributing the ads-enabled release. All ad requests retain maximum content rating G, applied before SDK initialization. Child-directed/under-age treatment is applied to existing known under-age answers, rather than every player. A G ad content cap does not imply a child-directed audience. The merged Android release manifest includes `android.permission.AD_ID` and the `ACCESS_ADSERVICES_*` permissions contributed by Google Mobile Ads SDK 24.9.0. Keep the Play Console ads and Data safety declarations consistent with the SDK and these manifest permissions. Only the Google ads bridge is installed; no third-party mediation adapters are bundled.

Test the debug APK on Android for ad load, optional reward completion/cancel, full-screen failure, resume, offline behavior and regional consent. AdMob account/store review and inventory can still limit live ad serving. No store upload is performed by this integration.

## Verification

Run `Godot --headless --path . --script res://tests/ad_checks.gd` for manager callback/claim checks, `Godot --headless --path . res://tests/ad_provider_checks.tscn` for adapter lifecycle checks, and `tools/run_checks.ps1` for release checks. The provider scene loads after project autoloads, matching normal game startup.

Sources: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0 and https://poingstudios.github.io/godot-admob-plugin/latest/.

## Godot editor preview

Set `--ad-preview` as a user argument when running the project, or launch the Godot executable with `--path . -- --ad-preview`. Preview rewards use the active save, so use an isolated APPDATA profile for automated tests. Run `res://tests/editor_ad_playthrough.tscn` with that argument and a `.test-data` APPDATA profile to exercise canceled and completed mock video, coins, failure continuation, life restore and end-of-level navigation. The mocks continue processing while gameplay is paused; the input cover sits below their ad UI. This validates the game integration, not native Android consent, rendering or Google inventory.

## Audience decision

The added age questionnaire has been removed. Existing coarse age answers from
older releases are reused only for known under-age handling. No birth date is
collected and the category is not uploaded. A 7+ store content rating and choosing
child-suitable ads do not, by themselves, classify every player as a child.

On the connected Vivo test phone, Google UMP reported **publisher misconfiguration:
no form(s) configured** for app ID `ca-app-pub-7480928068306811~8170975262`.
This blocks the valid privacy state before ads are requested; it is distinct from
AdMob app verification and from an ad server no-fill response. Publish an
applicable message for this exact app in AdMob Privacy & messaging. Do not work
around a missing publisher configuration by pretending consent was obtained.

The native wrapper also connected its initialization/consent listeners after
invoking the native operation. Those listeners now connect first, with a
synchronous-completion regression test. Local logs distinguish initialization,
loaded ads and load errors (code/domain/message).

Families SDK list: https://support.google.com/googleplay/android-developer/answer/12955712
Targeting: https://developers.google.com/admob/android/targeting
Pinned native release: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v4.3.1

### Published-message retest — 18 November 2026

After the European consent message was published, the corrected v11 APK was installed with adb install -r on the authorized Vivo test device. UMP returned IABTCF_gdprApplies=0; the previous no-forms error cleared. Runtime logs confirmed AdMob SDK initialized, interstitial loaded, and rewarded loaded. This confirms inventory loaded, not a completed impression or reward. Evidence: .test-data/published-consent-device-test.log. The auth-return URI query now resolves to one dedicated AuthReturnActivity.


### Ethan cascade earning and ad research - 19 November 2026

Final owner-approved earning rule: one player swap causing eight or more matching waves awards one Ethan gift in the tray. The initial match is wave one. The chain is resolved before awarding; nine or sixteen waves still award only one gift for that swap. Further qualifying swaps can earn more in the same level. There is no per-level or inventory cap, no accumulated hat-trick progress, and no award for ordinary tile matches or shape/special achievements. The existing character introduction at level 24 is retained. Setup and tray-booster cascades do not qualify. Existing stock, purchases, rewarded-ad offers, special creation, score and move rewards are preserved. Academy and shop instructions match this rule.

Ad provider callbacks are presentation-specific: old callbacks cannot reward or dismiss the next ad. Rewarded supplies require the earned-reward callback, never dismissal alone. No local forced-watch timeout or replacement close control was added.

AdMob supports ad pods: two videos within one rewarded impression, included by default through rewarded-unit Advanced settings. High-engagement ads permit rewarded skip/reward times up to sixty seconds and interstitial skip times up to twelve seconds. These are upper bounds, not minimum durations. This game's single SDK presentation supports Google's pods without manually launching a second presentation. Account settings remain unverified and unchanged. Explicit multi-ad reward bundles are separately permitted if clearly disclosed, but are not implemented here.

Research:
- https://support.google.com/admob/answer/7372450?hl=en
- https://support.google.com/admob/answer/15525707?hl=en
- https://support.google.com/admob/answer/7313578?hl=en
- Developer report: https://www.reddit.com/r/incremental_games/comments/1it5i6y/
- Player/developer discussion: https://www.reddit.com/r/AndroidGaming/comments/1h9v4ci/

Godot validation: character_booster_checks passed 1,347 checks, zero failures. Includes a real legal player swap with controlled refill producing eight waves, threshold boundaries, one award per swap, repeat earning, no automatic board placement, setup/tray exclusion, retained inventory and existing booster behavior. No APK built or installed. This confirms mechanics, not the natural occurrence rate across human play.

### USB release verification - 19 November 2026

Built and installed a fresh release APK (build/android/SaveTheBaby-v11.apk, 246024353 bytes) over the existing Vivo V2111 installation with adb install -r; no uninstall or data clear. Android lastUpdateTime: 2026-11-19 13:09:55. Runtime logs at 13:10:48 confirmed units=production, SDK initialization succeeded at 13:10:49, rewarded loaded at 13:10:59 and interstitial loaded at 13:11:00. This establishes production-unit selection and load, not a completed native impression, reward or number of exit steps. Added presentation-specific shown/earned/closed diagnostic logs without changing Google's native exit UI. No custom Skip control or timer is implemented in the game.

The broader navigation check found an empty authored story briefings dictionary replacing all fallback route text, causing access to the absent alone key. Merge authored overrides into defaults instead. continuation_checks passes with the fix; ad_provider_checks also passes. Final APK contains both the fallback fix and eight-wave Ethan rule.

The first sandboxed build failed on access to a cached Gradle JAR. The normal-access build succeeded; subsequent packaging succeeded. Original build logs are .test-data/android-v11-apk-output.log and android-v11-apk-error.log. User was asked to open the exact easy-to-close ad for direct native observation; no claim of exit-screen reproduction yet.

### Captured fastest-close attempt

Direct observation now confirms the short exit behavior. In .test-data/sb-fast-close-followthrough.mp4, the Card Wallet interstitial's yellow bar is visibly filling at clip 70.50s, reaches nearly full at 73.75s, and is replaced by an X by 74.00s (quarter-second frame samples). The visible bar phase is approximately 3.5-4 seconds; initial native surface loading occurs before the bar is visible. Native events: displayed 18:14:41.921, dismissed 18:14:49.372, elapsed 7.451 seconds. It returns after one close without a second video/install screen. This is a confirmed contrast with the much longer Bus Fever rewarded sequence, not an unverified user report. Format logged by our app: interstitial, placement level_end, presentation 2. No earned-reward event for this automatic interstitial. The recordings compare different formats; account-side high-engagement/ad-pod settings remain unverified. Evidence: .test-data/fast-ad-detail-contact.png and .test-data/fast-close-native-events.log. No input was sent by the agent during the user's attempt.
