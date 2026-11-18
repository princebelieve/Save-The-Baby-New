# Advertising integration

Automatic interstitials are requested only when leaving a completed or failed level result, once per attempt. Story, map, loading, pause and briefing transitions never request ads. Completing a rewarded ad suppresses the result interstitial for that attempt. Missing inventory never blocks navigation.

Optional offers: first-clear bonus matching the level coin payout; five extra moves after failure (once per attempt, restoring the deducted life); one life in the life shop; one rocket, bomb, thunder or Ethan assist from its supply dialog. Supply/life offers are limited to once per board attempt. No ads in academy practice results. Rewards are saved through the existing campaign inventory flow. Stars and story progress are never sold as ad rewards.

## Installed integration

Poing Studios Godot AdMob 5.1.0 is vendored in `addons/admob`, with its editor mocks. Android is deliberately pinned to the official 4.3.1 bridge compiled for Godot 4.6.3, using Google play-services-ads 24.9.0 (the package listed in Google Play’s Families self-certified SDK list). The Android installer and exporter preserve this pin; do not replace it with the Next-Gen bridge without checking certification and initialization compatibility. `AdProvider` is registered as an autoload, initializes consent and the SDK, preloads both formats, retries load failures after 60 seconds, discards ads after 50 minutes, and restores audio/pause state after dismissal or show failure. Ads remain unavailable on desktop by default. An explicit `--ad-preview` user argument enables the plugin mock ads only in a graphical debug run from the editor executable; this never runs on Android or in exported release builds.

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
