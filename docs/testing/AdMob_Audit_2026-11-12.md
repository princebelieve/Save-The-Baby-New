# AdMob audit — 12 November 2026

Authenticated access is verified using the owner's Desktop OAuth client and `admob.readonly` authorization. No ad settings were changed.

## Confirmed

- Publisher: `pub-7480928068306811`.
- Save The Baby app ID: `ca-app-pub-7480928068306811~8170975262`; platform Android; approval state `APPROVED`.
- Store linkage is `com.savethebaby.game`.
- App ID matches project.godot. Interstitial `3957444262` (Level End) and rewarded `7596260199` (Optional Rewards) match AdProvider.gd and have the expected formats.
- Network report for 14 October–12 November 2026, filtered to this app and grouped by date/ad unit, returned a header/footer and no activity rows. This is not proof of the reason for absent activity, nor a guarantee about serving restrictions.
- `https://sbi.globalcreest.com/app-ads.txt` returns HTTP 200, text/plain, with the correct Google DIRECT publisher authorization line. AdMob's own crawler verification status was not retrieved. The first-level subdomain matches Google's documented supported crawling pattern.
- The bare `globalcreest.com` hostname did not resolve during the check. This does not by itself establish an app-ads.txt blocker because the listed developer subdomain serves the file successfully.

Raw authorized inventory/report snapshot: `.private/google-access/admob-audit.json` (not tracked or exported).

## Remaining checks and exact owner actions

1. In AdMob, open **Policy centre** and inspect any account-level or Save The Baby issues. Send a screenshot if there is a warning, ad-serving limit or disabled serving notice. App approval alone does not prove there are no such issues.
2. Open **Apps > View all apps > app-ads.txt**. Find Save The Baby and check whether the file is authorized/verified. If the status is pending or not found, use **Check for updates** if offered and capture the result; the public file itself is already present.
3. On a physical Android device use the regular signed release or production app. Godot desktop previews and Android debug builds intentionally use no live production inventory/test ad IDs. Do not click live ads as a test.

Play Store discovery remains a separate investigation: broad production country availability was verified earlier; manual device exclusions and search ranking are not covered by this AdMob audit.

Sources: [ad units API](https://developers.google.com/admob/api/reference/rest/v1/accounts.adUnits/list), [report API](https://developers.google.com/admob/api/reference/rest/v1/accounts.networkReport/generate), [app-ads.txt subdomain rules](https://support.google.com/admob/answer/9363762?hl=en).
