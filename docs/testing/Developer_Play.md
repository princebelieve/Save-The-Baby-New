# Developer Play

Double-click **Start-Developer-Game.cmd** in the project root. It opens the desktop game with a **DEV TOOLS (F8)** button. Click the button or press F8 to open or close the panel.

On Android, install `build/android/SaveTheBaby-Dev.apk`. It appears as **Save The Baby Dev** and installs alongside the regular game under the separate `com.savethebaby.developer` package. Tap **DEV TOOLS** to use the same level, calendar and supply controls. Android Back closes an open developer panel. This APK does not handle the regular game's Google return link. Accounts, billing and ad initialization are disabled in developer sessions.

- Enter any level from 1 to 1050, choose an approach, and select **PLAY SELECTED LEVEL**. By default it goes straight to the board and skips tutorials. Enable **Show story and briefing before play** to test the narrative entrance instead. Jumping unlocks the test map without marking skipped levels as won.
- **DAILY REWARDS SCREEN** opens the real rewards page.
- **CLAIM TODAY'S STAMP (TEST)** awards the real daily stamp and coins once per simulated UTC day. Clicking twice verifies the duplicate-claim guard.
- **NEXT UTC DAY** moves the test clock to the next daily reset. Claim again to test a consecutive streak and the seven-reward cycle.
- **SKIP ONE DAY** moves forward two dates to test missed-day grace and its cooldown.
- **NEXT PORTRAIT SLOT** opens the next 12-hour availability window. **PLAY PORTRAIT PUZZLE** uses the real timed puzzle and reward flow.
- **REFILL TEST LIVES AND BOOSTERS** supplies five lives, twenty of each inventory booster and two Ethan assists.
- **RESET DAILY TEST PROGRESS** clears the test daily records, including streak and portrait usage, while keeping test coins and level progress.

The launcher stores all user data under `.test-data/developer-play/manual/`. It never opens the normal player save. Test time persists between developer sessions in that profile; Windows time is unchanged. Account sign-in, cloud sync and purchases are disabled in this session. To test real service integrations, use the normal test-track procedures.

Desktop controls require the editor executable, a debug build, `--developer-tools`, and an isolated developer-play profile together. Phone controls require a debug build with the `developer_phone` export feature. The separate Android Developer APK preset supplies that feature and package identity. Controls are inactive in release exports and normal F5 runs. The previously built version 7 AAB does not include these new developer tools or gallery saving.

Run `tools/run_checks.ps1 -Suite developer_checks` for level jumps, supplies, daily claims, duplicate prevention, consecutive/missed days, slot expiration, the actual portrait screen/reward, clock persistence and account/purchase blocking. That suite uses its own `.test-data/developer-play/checks/` profile.

Verified locally: 66 developer checks, 292 calendar/streak checks, and 10,673 story/normal-mode checks passed. Normal-mode checks included the developer command-line flag in a non-developer profile and confirmed that no controls appeared and the test clock was ignored.
