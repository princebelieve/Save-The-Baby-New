# Play Store visibility review — 12 November 2026

Production listing: https://play.google.com/store/apps/details?id=com.savethebaby.game

The owner confirmed production availability. A public English/Nigeria request returned the actual listing, an Install action and structured availability `InStock`. This proves public listing availability in that context, not every country, account or device. Snapshot: `.test-data/play-store-production.html` and readable text alongside it.

## Confirmed listing findings

- Title: Save The Baby. The short description already identifies match-3, but the title does not. A more descriptive title may help players understand the game; it does not guarantee search ranking.
- The full description says 50 puzzle levels. The current release contains 1,050 level files. Update this copy when version 9 goes live; do not advertise unreleased content as already available.
- Visible update date: 4 November 2026. Public download band: 0+. This is not an exact installation count and is not evidence that the game is hidden.
- Nigeria content rating: 7+, Mild Violence. This can legitimately limit installation on accounts with stricter parental filters. Keep the rating truthful; do not lower it to bypass filters.
- The listing exposes support/privacy links, Puzzle category, ads and purchases disclosures, and a Families policy commitment.

## Package compatibility review

Version 9 uses `com.savethebaby.game`, Android target API 36 and minimum API 24. ARMv7 and ARM64 are included. All small/normal/large/xlarge screen flags are supported. There is no camera, telephony, location or GPS hardware requirement.

The first APK inspection exposed a real device filter: `android.hardware.vulkan.version` was required. The separate Vulkan hardware-level flag was optional; that did not remove the version requirement. Fixed by setting the mobile renderer override to `gl_compatibility` for this 2D game, then rebuilding both formats. The release verification script rejects APKs that still require Vulkan. OpenGL ES 3.0 remains required. This confirms a restriction in the local package configuration, not a count of devices excluded by the older production release.

Intentional reach limits: Android below 7.0/API 24, devices without OpenGL ES 3.0 and devices without either included ARM ABI. Native x86-only support is not included. These limits should not hide the game on ordinary supported Android phones. Physical-device performance and installation on representative older phones still need checking.

Target API 36 meets the currently documented update requirement. This does not establish the target SDK of the older production artifact. Verify the active production version in Play Console. Native alignment and signing checks are recorded with the version 9 artifacts.

## Checks that require Play Console

The available integrations do not expose Play Console. No claim is made about live country targeting, manual device exclusions, Android vitals, policy notices, rollout percentages, acquisition performance or an unlisted distribution setting.

Review Production > Countries/regions; Publishing overview; Policy status; Reach and devices > Device catalog; and Android vitals. Compare direct-link installation with search results on a supported device and Google Play account. Low search placement is different from an unavailable listing.

## Sources

- [Google: app visibility and discovery](https://support.google.com/googleplay/android-developer/answer/9042516?hl=en-en)
- [Google: country availability](https://support.google.com/googleplay/android-developer/answer/7550024)
- [Android: target API requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Google: listing best practices](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en-en)
- [Google: parental rating filters](https://support.google.com/families/answer/16398726?hl=en)
