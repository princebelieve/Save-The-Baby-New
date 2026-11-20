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

## Validation

20 November follow-up: owner reported five level transitions without ads. The initially connected process had no retained startup diagnostics; its old logs must not be treated as proof of today's failure. A controlled restart produced process 12970: consent NOT_REQUIRED, Google and Unity adapters READY at 05:07:32, interstitial loaded 05:07:39, rewarded loaded 05:07:42. Private DNS mode was off; no device setting changed. These observations establish successful fresh delivery, not the cause of the earlier five skipped transitions.

Recovery fixes: AppPrivacy schedules another consent update after a failed update or unresolved status, while keeping requests gated until a valid result. AdProvider now logs request attempts, detects a missing load callback after 120 seconds, waits the existing 60-second retry interval, and uses per-format generation tokens to discard obsolete successes/failures. Consent invalidation also invalidates pending request generations. No timeout grants a reward or marks an ad presentation complete. Google remains an active bidder in each configured group; group priority is not a Unity-before-Google source order. Unit tests exercise timeout/retry, late callback isolation, independent formats, internal-error recovery and consent retry without bypassing consent.

This recovery revision passed ad_provider_checks and continuation_checks (0 failures), and the release APK build completed successfully. The first installation attempt returned adb: no devices/emulators found after the USB connection dropped. Do not claim the recovery revision is installed until a later successful install is recorded. The initial 20 November account audit also failed with HTTP 400; it did not verify fresh account configuration or supply.

After reconnection, adb install -r returned Success for the recovery revision. Final startup verification initially waited on Android's NotificationShade/lock screen being foreground. The preceding process 12970 also showed an automatic level-end ad at 05:08:59, returned at 05:10:03 and reloaded at 05:10:09; it demonstrates delivery before the recovery patch, not proof of the earlier failure's cause. No timeout recovery should be presented as the confirmed cause of the owner's five missed ads.

Final verification completed on process 17263: Android permitted wake/dismiss-keyguard without authentication; game focus restored. Both Google and Unity adapters READY at 05:17:37; new request-attempt diagnostics appeared for both formats; rewarded loaded 05:17:43.477 and interstitial loaded 05:17:43.564. Evidence saved to .test-data/ad-recovery-2026-11-20.log. This confirms the installed recovery build starts and loads both formats. The owner did not need to launch the game manually, and future foreground requests should first try the available Android controls before asking for help.

Guided device recording .test-data/sb-unity-guided-test.mp4 captured level 71 completion, result buttons, a Unity video and install end card. The foreground activity was com.unity3d.ads.adplayer.FullScreenWebViewDisplay, confirming actual Unity display. Owner later confirmed the close control was white on white. A tap on the visible top-right X returned Android focus to Godot and produced dismissal callbacks; no game-made timeout or forced install was required. Native showed and dismissed callbacks were processed together on return, so the displayed-to-dismissed diagnostic of 4 ms is not the ad's actual duration. Do not use that number to characterize ad timing; use the video/show-request timestamps.

Button-feedback follow-up: the provider now draws a clear Opening advertisement message and yields one frame before calling the native show method. This gives pending result-button feedback a chance to render before native presentation work. It does not change the supplier's close control or shorten native SDK startup. Tests cover the deferred presentation and prevent a failed presentation from opening late on the following frame. Broader post-win input latency is not established as resolved by this change.

The feedback update passed ad_provider_checks and continuation_checks (0 failures), exported successfully, and was installed with adb install -r on the owner's phone. Installation returned Success. The game's native ad startup and post-win response timing require a new live observation; do not claim this patch changes the Unity end-card X's contrast.

Godot ad_provider_checks passes, including reward-only-on-earned, no reward on dismissal, stale callback isolation and response-field filtering. Android release export succeeded and the final APK was installed with adb install -r (no uninstall/data clear). APK inspection confirms UnityMediationAdapter, UnityAds and UnityAdsPrivacyPlugin classes, plus native plugin manifest registration.

The initial device run exposed optional paid-event signal connections unsupported by the pinned 4.3.1 bridge. MobileSingletonPlugin now checks has_signal before connecting/disconnecting optional events; actual fullscreen/reward callbacks remain intact.

Final device process 11770, 19 November 2026: privacy bridge metadata committed at 21:05:08 before MobileAds initialization; both Google Mobile Ads and UnityMediationAdapter reported READY (state 1) at 21:05:16. Interstitial loaded at 21:05:40 and rewarded loaded at 21:05:48. No optional paid-signal errors or AndroidRuntime crash appear in the captured final startup. Evidence: .test-data/unity-final-startup.log. These observations prove installed native integration and initialization, not that Unity won a particular auction, that a live reward completed, or that the close countdown is now longer. The pinned bridge returned no response-level descriptor for these loaded ads, so their supplier is unverified.
