# Unity Ads bidding integration

Owner dashboard screenshots verify the two saved, enabled AdMob mediation groups and mappings:

| Format | AdMob unit | Unity Game ID | Unity placement |
| --- | --- | --- | --- |
| Interstitial | Level End /3957444262 | 800445752 | BP_Interstitial_Android |
| Rewarded | Optional Rewards /7596260199 | 800445752 | BP_Rewarded_Android |

Partnership is Active. Group IDs: interstitial 3162555861; rewarded 7760312983. Google retains control of the auction; Unity is an additional bidding source, not guaranteed to win every request. No application-made ad countdown or close overlay is introduced.

## Project changes

The Android export dependencies explicitly include Google Mobile Ads 24.9.0, Unity Ads 4.16.6 and Google's Unity mediation adapter 4.16.6.0. Google's changelog lists this exact tested SDK pair; this adapter forwards child-directed and under-age-of-consent request flags. Do not accidentally upgrade the whole bridge to Next-Gen SDK. Existing AdMob unit IDs and earned-reward callbacks remain in use; Game/Placement IDs are mapped in AdMob, not separately initialized by GDScript.

The UnityAdsPrivacy native Godot plugin synchronously commits gdpr.consent=false and privacy.consent=false before MobileAds.initialize and before loading either format. Unity remains contextual-only because UMP OBTAINED alone does not establish consent for this partner. No new audience prompt is added. Known age flags still come from AdProvider's RequestConfiguration, with Unity's mixed-audience dashboard designation needed for per-user handling. If the native privacy bridge is absent, Android does not initialize/request ads. The integration does not claim to enable Unity personalization.

SDK initialization diagnostics report adapter class names and state. Existing response diagnostics identify the selected source and response ID; live delivery must be verified on Android, not inferred from Godot mocks or a successful APK build.

## Remaining account verification

- The declared audience selection (currently child-directed + mixed in screenshots) has not been reconciled with the actual Play Console target age groups. A 7+ content rating is not that declaration.
- Verify Unity Ads in AdMob's European and applicable US regulations ad partner lists.
- Obtain Unity's app-specific authorized seller entries and add them to the published app-ads.txt; do not invent seller IDs.
- Use a registered test device, Unity test mode and Ad Inspector single-source testing for a deterministic Unity delivery check. Production auction behavior and duration vary.

## Sources

- https://developers.google.com/admob/android/mediation/unity
- https://docs.unity.com/en-us/grow/ads/privacy/ccpa-compliance
- https://docs.unity.com/en-us/monetization/dashboard/child-directed-settings
