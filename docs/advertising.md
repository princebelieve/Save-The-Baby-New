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

The privacy policy source and generated HTML now describe advertising. Publish those updated legal pages at the URLs used by the store listing, and update Google Play's ads/Data safety declarations for the SDK before distributing the ads-enabled release. All ad requests use child-directed treatment and maximum content rating G, applied before SDK initialization. UMP receives the under-age-of-consent flag. The export manifest removes AD_ID permission. Only the Google ads bridge is installed; no third-party mediation adapters are bundled.

Test the debug APK on Android for ad load, optional reward completion/cancel, full-screen failure, resume, offline behavior and regional consent. AdMob account/store review and inventory can still limit live ad serving. No store upload is performed by this integration.

## Verification

Run `Godot --headless --path . --script res://tests/ad_checks.gd` for manager callback/claim checks, `--script res://tests/ad_provider_checks.gd` for the native adapter lifecycle checks, and `tools/run_checks.ps1` for release checks.

Sources: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0 and https://poingstudios.github.io/godot-admob-plugin/latest/.

## Godot editor preview

Set `--ad-preview` as a user argument when running the project, or launch the Godot executable with `--path . -- --ad-preview`. Preview rewards use the active save, so use an isolated APPDATA profile for automated tests. Run `res://tests/editor_ad_playthrough.tscn` with that argument and a `.test-data` APPDATA profile to exercise canceled and completed mock video, coins, failure continuation, life restore and end-of-level navigation. The mocks continue processing while gameplay is paused; the input cover sits below their ad UI. This validates the game integration, not native Android consent, rendering or Google inventory.

## Audience decision

Android asks for an age group before starting ad consent or loading ads. No option is preselected; Prefer not to say is available. Only a coarse category is saved locally in user://ad_age_group.cfg, never a date of birth, and it is not uploaded. All choices retain the same gameplay, ads, optional login and purchases. All users receive child-directed, G-rated ads; the prompt does not enable personalized ads for adults.

For this implementation, select Yes to child-suitable ads from a certified network, and select the neutral age screen certification. These declarations must describe the eventual uploaded build, not earlier APKs. Native Android ad delivery still requires device verification. AdMob dashboard changes (for example adding mediation networks) must preserve this policy.

Families SDK list: https://support.google.com/googleplay/android-developer/answer/12955712
Targeting: https://developers.google.com/admob/android/targeting
Pinned native release: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v4.3.1
