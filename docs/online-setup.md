# Google login, cloud saves and coin purchases: setup handoff

The implementation uses Google OAuth/OpenID Connect, a Node/Express API on Render, MongoDB Atlas, and Google Play Billing. It does not use Firebase or Gmail API. Nothing has been deployed to your accounts.

## What is implemented

- Settings ? Account & Coins: guest play, Google login in the system browser, cloud upload/download, sign-out and online account deletion.
- The browser returns to an HTTPS backend callback, then the game redeems the result by polling with a private login verifier. No Google client secret is embedded in the game. Google ID tokens are verified on the server, including audience, issuer, expiry and a per-login nonce; the account key comes from Google's stable subject, not an email address.
- Local saves remain available offline. Guest/account saves are backed up separately in app-private storage. Existing cloud progress is loaded only after confirmation. A revision mismatch stops automatic uploads rather than overwriting another device's newer progress. Guest uploads do not merge inventories into an existing cloud account.
- Coin packs: `coins_500`, `coins_1500`, `coins_3500`. The game displays prices returned by Google Play, never hardcoded currency amounts.
- Paid coins are a separate server-managed wallet. They can buy field supplies from the Account & Coins screen while online. Earned coins continue working in the existing offline shop. Local save uploads cannot change the paid wallet. General gameplay progress is client-supplied and is not a server-verified anti-cheat system.
- Payment tokens are checked with Google for completed payment and the signed-in account identifier. A MongoDB transaction records the token and credits the wallet once. Consumption happens on the server after the credit is durable. Pending, canceled, consumed-without-record and wrong-account payments are rejected. Retries recover outstanding purchases; refunds are periodically reconciled while the service runs. Refunded credit can make a wallet negative, preventing additional spending until resolved.
- Supply debits and inventory grants update the cloud save in a transaction, with a revision check and idempotency key. An ambiguous network failure pauses uploads until the player downloads cloud progress.
- The official Godot Google Play Billing 3.3.0 plugin is included (its declared Billing dependency is 9.1.0). Android Gradle exports are configured. Server source and credentials are excluded from game exports.
- `configs/online.json` deliberately has an empty API URL. Online features cannot operate until the deployment below is configured. Native checkout is also disabled until the backend reports purchase verification credentials are configured.

## Your part: account setup

### 1. Google Cloud: identity

Use a Google Cloud project for Save The Baby. In Google Auth Platform:

1. Complete Branding (app name, support email, homepage, privacy-policy and terms URLs).
2. Choose the appropriate Audience. For external testing, add the Google accounts that will test login. Complete Google's publishing/verification steps before public rollout as applicable.
3. Under Data Access, request only `openid`, `email`, and `profile`. Do not enable Gmail API or request mailbox scopes.
4. Create an OAuth client with application type **Web application**, because the backend handles the browser callback. Name it `Save The Baby backend`.
5. Keep the Client ID and Client secret for the Render environment. For local development you may authorize `http://localhost:3000/auth/google/callback`. After Render assigns your real HTTPS hostname, add this exact production redirect URI:

   `https://YOUR-SERVICE.onrender.com/auth/google/callback`

This flow does not need an Android OAuth client, SHA certificate fingerprint, or JavaScript origin. It opens the external browser and uses the confidential server's web OAuth client.

Reference: https://developers.google.com/identity/protocols/oauth2/web-server

### 2. Google Cloud and Play Console: purchase verification

1. Enable the Google Play Android Developer API in that Cloud project.
2. Create a dedicated service account, for example `save-the-baby-purchases`.
3. In Play Console ? Users and permissions, invite its service-account email and scope access to `com.savethebaby.game`. Grant the billing permissions Google specifies: **View financial data, orders, and cancellation survey responses**, and **Manage orders and subscriptions**.
4. Create a JSON key for that service account if your organization permits keys. Put the complete JSON into Render's private `GOOGLE_SERVICE_ACCOUNT_JSON` environment variable. Do not commit it or paste it into chat. This implementation uses that credential directly on the server.

Reference: https://developers.google.com/android-publisher/getting_started

### 3. Play Console: products

For `com.savethebaby.game`, create and activate these consumable one-time products (not subscriptions):

| Product ID | Coins credited | Suggested title |
| --- | ---: | --- |
| `coins_500` | 500 | 500 Ethan Coins |
| `coins_1500` | 1,500 | 1,500 Ethan Coins |
| `coins_3500` | 3,500 | 3,500 Ethan Coins |

Choose the real prices, countries and currencies yourself. Use a standard buy purchase option; the game reads its option ID and localized price from Google. Keep multi-quantity purchases disabled for this initial implementation. Product descriptions should explain these are virtual coins for field supplies in Save The Baby.

Add your test accounts to license testing and the internal test track. Complete any merchant/payment-profile setup Play Console requires for sales. Purchase tests must use the signed build installed through the Play internal test track with the matching application ID and configured products; a sideloaded debug APK is not proof that live billing works.

### 4. MongoDB Atlas: full setup

Atlas hosts the database. Render hosts the API. The game connects to Render; only Render connects to Atlas. You do not need MongoDB installed on your computer, MongoDB Compass, or a MongoDB server hosted inside Render.

1. Sign in at https://cloud.mongodb.com and create/select an Atlas project, for example `Save The Baby`.
2. Create a database deployment. Select the **Free (M0)** option for initial development/testing, rather than a paid Dedicated or Flex option. Use any available supported region reasonably close to the Render service. Give the cluster a name such as `SaveTheBaby`. Wait for provisioning. Check the selected tier before confirming.
3. Open **Database Access / Database Users** (the location may appear under Security). Add a database user using password authentication. This is a database login, separate from your Atlas website login. Use a name such as `save_the_baby_api` and generate/store a strong password privately.
4. Give that user the built-in **readWrite** role for database **`save_the_baby`**, rather than Atlas administrator access. The database does not have to contain collections yet.
5. In the cluster's **Connect** dialog, select **Drivers**, then **Node.js**. Copy the `mongodb+srv://...` driver connection string. Replace its username/password placeholders with the database user's credentials. URL-encode reserved characters in credentials; generating a long password using letters/digits avoids URI punctuation mistakes.
6. The result looks like this example (your hostname will differ):

   `mongodb+srv://save_the_baby_api:YOUR_PASSWORD@savethebaby.ABCDE.mongodb.net/?retryWrites=true&w=majority`

   Put the real value only in Render's `MONGODB_URI` environment variable. Set `MONGODB_DATABASE=save_the_baby` separately; the server explicitly selects that database.
7. Open **Network Access / IP Access List** in Atlas. Once your Render web service exists, find **Connect ? Outbound** or the service's outbound-IP section in Render. Add all the listed outbound IP ranges to Atlas. This is permission for the API server to reach MongoDB, not permission for players' phones. Add your own public IP only if you will run the backend locally.
8. Do not use `0.0.0.0/0` as the normal deployment configuration; it allows connections from all IP addresses. The Render outbound ranges are the intended allowlist.
9. The backend creates its collections and indexes automatically when it connects and data is written. You do not need to create `users`, `sessions`, `flows`, `purchases`, `spends`, or `rates` manually, or import sample data.
10. Free Atlas is useful for initial testing. Before production, choose capacity and backup arrangements appropriate to the game; backup capabilities depend on the tier. The backend requires replica-set transactions, so a standalone local MongoDB instance is not sufficient.

Reference: https://www.mongodb.com/docs/atlas/connect-to-database-deployment/ and https://www.mongodb.com/docs/atlas/security/add-ip-address-to-list/

### 5. Render: manual Web Service setup

**A Render Web Service is the correct service type.** `render.yaml` is optional: a Blueprint reads that file to create/configure a web service; the dashboard lets you enter the same settings manually. It is not a different hosting product.

To avoid Blueprint setup, use **New ? Web Service**, connect this repository, and enter:

| Field | Value |
| --- | --- |
| Name | `save-the-baby-api` (or another available name) |
| Language/runtime | Node |
| Root directory | `server` |
| Build command | `npm ci --omit=dev` |
| Start command | `npm start` |
| Instance type | **Free**, for initial testing |
| Health check path | `/health` |

Do not choose **Static Site**: this backend runs Node code and handles authentication/database requests.

Set these environment variables in the service's Environment page:

| Variable | Value |
| --- | --- |
| `NODE_VERSION` | `22.19.0` |
| `PUBLIC_BASE_URL` | The actual Render HTTPS URL, without a trailing slash |
| `MONGODB_URI` | Your private Atlas connection string |
| `MONGODB_DATABASE` | `save_the_baby` |
| `GOOGLE_CLIENT_ID` | The Web application OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | That client's secret |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Complete purchase-verification service-account JSON |

Render supplies `PORT`; do not hardcode a public port in the game. If your service URL is not assigned until creation, finish the URL-dependent settings after Render shows it, then redeploy. A failed initial deploy due to missing environment variables or Atlas network access does not require creating a second service.

Once you have the actual hostname:

1. Set `PUBLIC_BASE_URL` to that HTTPS URL.
2. Add `https://YOUR-SERVICE.onrender.com/auth/google/callback` as an authorized redirect URI in your Google Web OAuth client.
3. Allow the service's outbound IP ranges in Atlas as described above.
4. Save the environment changes and redeploy.
5. Visit `https://YOUR-SERVICE.onrender.com/health`; after a successful startup it should return `{"ok":true}`. Deployment logs should say `Save The Baby API ready`.

The Blueprint remains available if you prefer it. It now explicitly uses `plan: free`; omitting `plan` can select paid compute for a new service. Check the dashboard's displayed plan/cost before provisioning anything.

A free web service can test the initial setup, but sleeps after inactivity and can take about a minute to wake. The game's API timeout is 25 seconds, so a first request after sleeping may fail and need retrying. The in-process purchase reconciliation timer does not run while the service is asleep. For reliable production payment processing, use an always-on service or separately arrange reliable scheduled processing. No paid service or subscription has been provisioned by this change.

References: https://render.com/docs/web-services and https://render.com/docs/blueprint-spec and https://render.com/docs/configure-environment-variables and https://render.com/docs/free

## What to send back

Send only:

- The deployed public API URL.
- Confirmation that Google OAuth callback/client configuration is complete.
- Confirmation that the three product IDs are active, along with their coin amounts and selected prices.
- Confirmation that the service account and Atlas access are configured in Render.

Keep passwords, client secrets, database connection strings and service-account JSON in Render's private environment settings. I can then set the public API URL in `configs/online.json`, rebuild the game, and help verify real sign-in and Play test purchases. Prices do not need to be embedded in the game.

## Before public release

Publish the updated privacy/terms pages, update Play's account/Data safety/ads/IAP declarations as applicable, and provide the account-deletion link `https://YOUR-SERVICE.onrender.com/account-deletion`. The in-game screen includes the Player ID for support requests. Google authentication and checkout are not live until the external configuration and licensing tests pass.

Check login/guest migration, a second device download, offline progress, simultaneous-device conflicts, successful and pending purchases, purchase retry after process termination, refunds, sign-out, and account deletion on a real configured environment. Confirm transaction behavior against your Atlas deployment. Automated API tests use a deterministic in-memory store and do not verify the live MongoDB driver, Google OAuth, Google payment API, or account permissions.

## Local verification

From `server`, run `npm ci` then `npm test`. `node test-support/game-client-check.js` runs the Godot client against a local test-only API using an isolated `.test-data/online` profile (set `GODOT_EXECUTABLE` if Godot is installed elsewhere). The local test fixtures are not part of the deployed API entry point. `tools/run_checks.ps1` runs game release checks.

For a real local MongoDB replica set and real Google test credentials, load environment variables from `server/.env.example` using your shell, then run `node --env-file=.env src/server.js`. A standalone MongoDB instance without replica-set transactions is unsupported. Secrets and `node_modules` are ignored by Git.
