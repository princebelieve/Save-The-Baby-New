# Local Google Play and AdMob access

This is a local operator helper, separate from Google sign-in inside the game and from the Render backend. It does not publish releases or change account, ad, listing or purchase settings.

## Verified on 12 November 2026

The existing Save the Baby service account successfully called the Play reviews endpoint for `com.savethebaby.game`. The response contained no reviews. This proves authenticated app access to that endpoint, not access to every Console setting.

Command, from the repository root:

```powershell
node server/scripts/google-admin-access.js play-status "C:\Users\ASUS\Downloads\save-the-baby-513514-546f88e42474.json"
```

No extra service-account invitation was needed. The subsequent `play-visibility` audit also succeeded: it read tracks, production country availability and listings through a temporary edit, then deleted that edit without committing anything. Reporting/Android vitals may require enabling the separate Google Play Developer Reporting API. Manual device exclusions are still not checked by this helper.

```powershell
node server/scripts/google-admin-access.js play-visibility "C:\Users\ASUS\Downloads\save-the-baby-513514-546f88e42474.json"
```

That command saves its response in `.private/google-access/play-visibility.json`. Confirmed: production version 8 has completed rollout; the country response includes Nigeria, the UK and US and enables rest-of-world distribution; only en-GB listing copy was returned, still advertising 50 levels. Version 9's local compatibility fix is not yet in production.

## AdMob: remaining owner steps

1. Select `save-the-baby-513514` in [Google Cloud Console](https://console.cloud.google.com/).
2. Open Google Auth Platform > Clients, or APIs & Services > Credentials. Create an OAuth client ID with application type **Desktop app** and name it **Save the Baby Local Audit**.
3. Download its JSON file into Downloads. Keep the JSON contents private; only its local file path is needed by the tool. Do not reuse the game's web/Android Google sign-in client.
4. If the OAuth consent screen is in Testing, add the Google account that manages AdMob under Audience > Test users.

Then run, replacing the placeholder with the downloaded filename:

```powershell
node server/scripts/google-admin-access.js connect-admob "C:\Users\ASUS\Downloads\client_secret_YOUR_NEW_DESKTOP_CLIENT.json"
node server/scripts/google-admin-access.js admob-status
```

The first command opens Google in the browser. Sign in personally and approve the `admob.readonly` scope. It requests no AdMob write access. The second command verifies API access, counts accessible apps and identifies the app linked to `com.savethebaby.game`. Other dashboard-only settings may still need manual inspection.

The helper uses an expiring loopback callback bound only to 127.0.0.1, random state validation and PKCE. Refresh authorization is saved under `.private/google-access`, excluded from Git and game exports. Tokens and secret-bearing error objects are never printed. Treat the local credential and token files as private: they are not encrypted by this helper, and local filesystem access still matters. Google OAuth testing status may require reauthorization when test refresh tokens expire.

The owner completed consent, and both `admob-status` and `admob-audit` succeeded on 12 November 2026. Save The Baby is approved and correctly linked, with both configured ad units present. See `docs/testing/AdMob_Audit_2026-11-12.md` for findings and remaining dashboard checks. Run `node server/scripts/google-admin-access.js admob-audit` to refresh the app inventory and 30-day activity report.

References: [Play setup](https://developers.google.com/android-publisher/getting_started), [AdMob OAuth setup](https://developers.google.com/admob/api/v1/auth), [desktop OAuth and PKCE](https://developers.google.com/identity/protocols/oauth2/native-app).
