# TikTok promotion measurement and Android integration review

Updated: 18 November 2026.

## Purpose and final interface

TikTok promotes Save The Baby outside the game. Its App Events SDK reports
install, app-open and retention events so TikTok Ads Manager can measure the
campaign. It does not display TikTok ads inside the game. AdMob separately
provides the game's interstitial and rewarded advertisements.

The custom TikTok Allow/Don't allow popup and TIKTOK MEASUREMENT settings button
have been removed. The added age questionnaire has also been removed. Measurement
starts in the background where the shared regional privacy state permits it.
Existing coarse age answers from older releases are reused only for known
under-age handling; a missing answer is not automatically classified as a child.
The obsolete promotion_measurement.cfg choice is no longer read.

A 7+ store content rating and selecting child-suitable advertisements do not
mean every player must receive child-directed treatment. The G ad-content limit
is retained. Child-directed treatment is now applied to an existing known
under-13 answer; under-age treatment applies to known under-16 answers. Play
Console declarations were not changed. Standard Google regional privacy messages
and a required AD PRIVACY OPTIONS entry remain separate from the removed custom UI.

## Actual cause of unavailable ads

The connected phone returned this Google UMP error for
`ca-app-pub-7480928068306811~8170975262`:

> Publisher misconfiguration: Failed to read publisher's account configuration;
> no form(s) configured for the input app ID.

This occurs before an ad request, rather than being an ad-server no-fill result.
AdMob app verification does not configure Privacy & messaging. Publish an
applicable message for this exact app in AdMob Privacy & messaging, then retry
the shared privacy update. Do not pretend consent was obtained to bypass this
account configuration error.

The GDScript wrapper also invoked native initialization/consent updates before
connecting their callbacks. The order is fixed and a synchronous-completion
regression test now proves callbacks are not lost. Local diagnostic logs expose
privacy failures and ad initialization/load results, including load error code,
domain and message.

## Architecture

- AudienceSettings reads legacy age answers without creating UI.
- AppPrivacy owns UMP updates and standard regional privacy options. An unknown
  or failed privacy update remains off; it does not depend on ad inventory.
- AdProvider and PromotionAttribution independently consume that shared state.
  TikTok does not wait for AdMob initialization or for an ad to load.
- The native TikTok privacy gate checks applicable opt-out and vendor/purpose
  signals instead of treating Google's OBTAINED status as blanket TikTok consent.

For GDPR-required measurement, configure the actual TikTok provider ID from the
publisher's shared CMP as `consent_vendor_id` in `.private/tiktok-events.cfg`, or
`TIKTOK_CONSENT_VENDOR_ID` during export. The configured vendor consent and
purposes 1, 7, 9 and 10 are required. Unknown publisher restrictions remain off.
No provider ID is currently supplied, so GDPR-required measurement remains off
pending that account configuration. US sale opt-outs block measurement; GPP
signals conservatively block it until applicable-section/vendor handling is
configured. These are coverage limits, not reasons for another custom TikTok UI.

The exporter pins TikTok Business SDK 1.7.1, Lifecycle and Install Referrer,
uses JitPack, copies the Java bridge and writes Android resources. Automatic
installs/opens/retention are enabled. Automatic purchases, enhanced data
postback, diagnostics monitoring and advertising ID collection are disabled.
Our code sends no account identity, purchase tokens or game campaign progress.
No manual duplicate install event is added.

TikTokTrackingSession initializes once with disableAutoStart, waits for local
initialization and initial remote configuration, then starts event transmission
when allowed. Withdrawal disables the event switch and requests queue clearing;
the SDK instance is retained for resumption without restarting the game. Stale
starts/late callbacks respect newer stops, and TikTok's remote disable decision
is retained. Explicit pre-singleton failures can retry; partial native failures
remain failed_until_restart. This depends on pinned 1.7.1's initial config-fetch
ordering and must be re-audited on upgrade. Sent/in-flight requests cannot be
recalled. Failed remote configuration remains waiting_for_configuration, not
falsely initialized.

## Duplicate sign-in and Android chooser fixes

The account dialog previously displayed both SIGN IN WITH GOOGLE and PARENT /
GUARDIAN SIGN-IN, then renamed both Signing in while busy. It now has one Google
entry point, retaining guardian routing for an existing known minor/guardian
account. Reopening browser sign-in no longer adds a second cancel button.

Android also resolved savethebaby://auth/complete to both GodotApp and its
launcher alias. The export activity hook was being injected into both. A single
AuthReturnActivity now owns that URI and explicitly forwards it to the existing
singleTask game activity. The normal launcher remains separate. Server login
verification and purchase/account APIs are unchanged.

## Builds, tests and phone verification

- Focused Godot tests cover background measurement, no added controls, shared
  privacy state, age-treatment flags, initialization races and ad lifecycle.
- Native Java tests cover privacy decisions, remote configuration races,
  stop/resume, remote disable and retry. The Java bridge compiles against real
  Android/Godot/TikTok APIs.
- Button feedback/account dialog regression: 21 checks, zero failures.
- Full game release regression: zero failures.
- The phone is a Vivo V2111. Play Store v9 was Google-signed and rejected an
  upload-key-signed local update. Following explicit owner approval, that store
  copy was uninstalled and the local signed v11 APK installed. Later local
  updates use install -r and preserve the current game data.
- An earlier revision reached real SDK initialized status after a manual Allow.
  That custom flow was subsequently removed. Final background/UI/handler results
  must be distinguished from that earlier test.
- The phone defaults to error-only logs. Only scoped diagnostic tags are enabled
  temporarily during testing; those overrides should be restored afterwards.
- Final signed APK/AAB content verification passes: 1,281 source JSON files,
  2,582 matching assets, ARM64 alignment and expected manifest metadata. The
  bundled policy matches the final source, all native Java copies match, and
  release TikTok test mode is off. APK signature verification passes.
- The packaged manifest now declares the auth URI exactly once. Runtime handler
  counts and final UI installation await reconnection of the test phone.
- The publisher is creating the missing AdMob message. Fallback consent collection
  is optional; UMP remains the primary path. The publisher was advised to leave
  fallback off during this initial setup and publish the app's normal message.
- Event receipt in TikTok Events Manager and real campaign attribution remain
  unconfirmed; an initialized log message does not establish either.

## Publisher configuration and release

Package: `com.savethebaby.game`.
TikTok App ID: `7708890795843059732`.
Local connection: `.private/tiktok-events.cfg` (ignored by Git).
The exposed App Secret should be regenerated in TikTok and replaced in that
file's access_token field. Environment variables TIKTOK_APP_ID and
TIKTOK_SDK_ACCESS_TOKEN override those values at export. SDK credentials are in
compiled Android resources as required for client initialization; excluding the
local file does not make an APK a secret store.

Build using tools/build_android_release.ps1. TIKTOK_SDK_TEST_MODE=true is honored
only for debug exports; release exports force it off. The separate developer
package deliberately does not report production promotion events. No Play Store
upload has been made. Version code remains 11; choose a new code for Play if 11
was already uploaded.

The local policy and generated docs/legal/privacy-policy.html are updated.
Publishing https://sbi.globalcreest.com/save-the-baby/privacy-policy requires
updating the separate company website repository; it was not changed/deployed
here. No Render backend change is needed. Preserve unrelated working-tree edits.

References:
- https://github.com/tiktok/tiktok-business-android-sdk/tree/1.7.1
- https://ads.tiktok.com/resources/help/article/how-to-integrate-tiktok-app-events-sdk?lang=en
- https://developers.google.com/admob/android/privacy/gdpr
- https://developers.google.com/admob/android/targeting
- https://support.google.com/googleplay/android-developer/answer/9859655
