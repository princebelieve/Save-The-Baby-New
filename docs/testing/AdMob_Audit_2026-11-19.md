# AdMob read-only audit - 19 November 2026

The existing owner-authorized Desktop OAuth connection with admob.readonly succeeded. No account settings changed. This is the local tool documented in docs/Google_Admin_Access.md; do not claim the project lacks authenticated AdMob access.

Command: `node server/scripts/google-admin-access.js admob-audit`.

App approved and linked to com.savethebaby.game. Both configured unit IDs match AdProvider.gd:

| Unit | Format | Allowed types | Recorded impressions | Served types |
| --- | --- | --- | --- | --- |
| Level End /3957444262 | INTERSTITIAL | RICH_MEDIA, VIDEO | 9 | HTML 3, image 3, text 1, video 2 |
| Optional Rewards /7596260199 | REWARDED | RICH_MEDIA, VIDEO | 2 | HTML 1, video 1 |

Report range: 21 October through 19 November 2026. Returned activity is on 18-19 November. Figures are the reporting snapshot, not a count of every current phone test; reporting latency applies. All returned request rows were matched, so the lower number of impressions than preloads does not establish no-fill. No clicks were recorded. Estimated app earnings total 21,351 USD micros ($0.021351); not finalized. This tiny sample cannot establish which ad type maximizes revenue.

The short Card Wallet interstitial is independently recorded in .test-data/sb-fast-close-followthrough.mp4. Its visible yellow bar fills in approximately 3.5-4 seconds and is replaced by an X, with native show-to-close 7.451 seconds. Most reported level-end impressions are non-video, which supports mixed creative inventory as a contributor to the observed difference; it does not prove a specific response's backend classification or the High-engagement setting.

The audit now retrieves a separate creative delivery report grouped by AD_TYPE. Google disallows combining AD_TYPE with AD_REQUESTS, so request/match reporting stays separate. Read-only report POSTs generate reports; they do not modify AdMob configuration.

## API limits and remaining configuration

The public v1 AdUnit read response exposes IDs, name, format and adTypes. Neither High-engagement ads nor rewarded Ad pods is a field in that response. v1beta adds rewardSettings, not those switches. These values need dashboard inspection; an existing read-only OAuth grant does not reveal fields absent from the API.

For the owner's requested longer video experience: inspect High-engagement ads in app settings and Ad pods in the rewarded unit's advanced settings. They are default-enabled according to Google, but this account's values remain unverified. A video-only unit configuration can exclude the non-video creatives confirmed here; removing allowed inventory may reduce fill and does not guarantee higher earnings or a fixed watch duration. Do not substitute rewarded ads for automatic interstitials or force ad clicks/installs.

Sources:
- https://developers.google.com/admob/api/reference/rest/v1/accounts.adUnits/list
- https://developers.google.com/admob/api/reference/rest/v1beta/accounts.adUnits
- https://developers.google.com/admob/api/v1/report-metrics-dimensions
- https://support.google.com/admob/answer/6128738?hl=en
- https://support.google.com/admob/answer/15525707?hl=en
- https://support.google.com/admob/answer/7372450?hl=en

Raw snapshot remains in .private/google-access/admob-audit.json, ignored by Git and excluded from game exports. Credentials were not printed. No runtime code or APK changed during this audit.

## Screenshot confirmation and focused countdown investigation

The owner subsequently supplied an app-settings screenshot confirming High-engagement ads is already On. Do not keep treating that switch as disabled or unverified. Owner rejected video-only selection as a substitute for investigating the countdown; retain existing ad types unless separately authorized.

Google interstitial guidance explicitly permits close controls after about five seconds for some ads, up to twelve seconds for high-engagement video, and up to thirty for some third-party bidding videos. High-engagement On is eligibility for those experiences, not a minimum duration. The measured short bar alone therefore does not prove a broken timer. The response-level cause for the specific ad remains unresolved.

Diagnostic source change: log request content/age-treatment flags, whitelist response ID, adapter and ad-source name from the SDK response, and measure native displayed-to-reward/displayed-to-dismissed elapsed milliseconds for each presentation. No ad timer, close control or reward threshold is overridden. Response extras and adapter mappings/credentials are excluded. ad_provider_checks passed with response-field and stale native-show callback tests. Diagnostic APK preparation started; installation/runtime flag capture waits for the disconnected phone. No claim that countdown duration has been fixed.

https://support.google.com/admob/answer/6066980?hl=en
https://developers.google.com/admob/android/response-info

## Focused research: install/end-card linger

The owner clarified the issue is the persistent install/end screen, not a two-ad reward bundle. Do not implement a two-ad bundle as a substitute.

Google Authorized Buyers documentation explicitly describes video -> bidder end card -> Google end card sequences for high-engagement interstitial/rewarded ads, including required end-card viewing time and up to three exit steps. Clicking a video/end card can open an inline app-store overlay inside the publisher app. These rendering stages explain the type of multi-stage experience demonstrated by the owner, without establishing that Bus Fever requires an install click or identifying its exact ad response.

Important new scope detail: Google says High-engagement experiences do not apply to non-playable standalone HTML creatives. It does apply to eligible video and playable HTML. Thus the screenshot showing HEA On does not guarantee that every allowed non-video creative receives longer rendering. Aggregate AD_TYPE=html is insufficient to distinguish playable from non-playable HTML or classify the specific Card Wallet response.

Unity documentation independently says a playable may be followed by its own SDK-provided install end card; publishers do not construct that card. These stages belong to the ad supplier/creative and renderer. No documented AdMob publisher control found that makes clicking Install mandatory to close. Missing/nonfunctional exit controls are also reported as ad/SDK defects by game publishers; do not mistake forced advertiser interaction for a required normal implementation.

Primary sources:
- https://support.google.com/authorizedbuyers/answer/16891088?hl=en
- https://docs.unity.com/en-us/grow/acquire/creatives/playable/best-practices
- https://docs.unity.com/en-us/grow/programmatic/unity-exchange/video-ads
- https://crazylabs.freshdesk.com/support/solutions/articles/201000104511-i-can-t-close-the-ads-there-is-no-x-button-available-gp-

## Additional publisher controls and integration boundary

Unity's official placement documentation explicitly describes controls for skipping and an end card on close. Its support article directs mediated publishers to Monetization Dashboard > Placements > Edit ad unit and placement, and says rewardedVideo skipping is disabled by default. This establishes that some ad suppliers have publisher-side experience controls beyond AdMob's High-engagement switch. It does not establish a configurable 45-second minimum, a requirement to click Install, or the network used by Bus Fever. A developer discussion reports these advanced controls missing from its UI; availability must be checked rather than promised.

The current project includes Google Mobile Ads 24.9.0, but no enabled Unity Ads mediation setting or installed Unity Ads adapter was found in the inspected export configuration. The addon's generic list of supported networks is not an active integration. Google also includes some external buyers automatically inside AdMob Network, so absence of an adapter must not be described as absence of every external buyer.

A concrete expansion is Unity Ads bidding through AdMob for both existing formats. Google's integration requires the Unity project/placements, an active bidding partnership and mediation configuration, SDK/adapter integration, and privacy configuration. Current read-only AdMob authorization cannot establish that partnership or write mediation settings. No new network or speculative skip/countdown parameter has been enabled. Adding a source expands demand and rendering options; it does not guarantee that it wins auctions, that every ad is longer, or that revenue/installs increase.

Sources:
- https://docs.unity.com/en-us/grow/dashboard/ad-units/manage
- https://support.unity.com/hc/en-us/articles/212982383-Where-can-I-choose-whether-an-ad-can-be-skipped
- https://developers.google.com/admob/android/mediation/unity
- https://support.google.com/admob/answer/11555701?hl=en
- https://discussions.unity.com/t/settings-for-interstitial-ads/1690286

Owner confirmed there is no existing Unity Ads monetization project and requested setup help. A read-only GET to the v1beta mediationGroups endpoint using the existing grant returned HTTP 403. Google documents this endpoint as limited access even with admob.readonly. This result does not prove no mediation groups exist and does not invalidate the successful app/unit/report reads. Do not expand OAuth scope to fix it without evidence.

Compatibility preparation: Google's adapter changelog explicitly pairs Unity Ads 4.16.6 / adapter 4.16.6.0 with the project's Google Mobile Ads 24.9.0; that release also forwards tagForUnderAgeOfConsent. This is a candidate dependency set, not a deployed integration. Consent propagation, current SDK eligibility and Unity project settings still require review before activation. No adapter has been added while account setup is pending.
