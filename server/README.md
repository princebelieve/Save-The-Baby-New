# Save The Baby API

Express + MongoDB backend for Google OAuth login, revision-checked saves and Google Play coin-purchase verification. No Firebase and no Gmail API.

See [the setup handoff](../docs/online-setup.md) for deployment and account configuration. Start with `npm ci` and `npm test`. Production starts with `npm start` after the documented environment variables are configured. Never commit `.env` or credential JSON.

The production entry point is `src/server.js`; `test-support` contains isolated fake integrations for automated tests only. MongoDB must support replica-set transactions. `GET /health` is available after startup connects; `GET /account-deletion` supplies player deletion instructions.

After deploying, run `node scripts/check-auth-return.js https://save-the-baby-new.onrender.com` from this directory. A healthy `/health` response alone does not prove the login return page is deployed. The checker requires the visible **Return to Save the Baby Game** button and the Android app-opening link. Then complete a real Google login on the phone and tap the button to verify the installed app resumes. Rebuilding an APK does not update this server-rendered page.
