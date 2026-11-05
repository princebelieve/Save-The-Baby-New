# Release readiness: 4 November 2026

Recommendation: hold the public production release. The source checks passed, but the existing Android bundle predates the additions, Android device testing has not been completed in this session, and level 783 needs human playtesting.

| Check | Result |
| --- | --- |
| Added level files and opening boards | 1,000 checked; zero assertion failures |
| Random gameplay sample | 21 cases, 63 initial bot attempts, 49 wins |
| Level 783 follow-up | 3 additional attempts, zero wins |
| Actual swaps exercised | 1409; zero rejected legal swaps, frozen turns, unstable final boards, or incomplete refills |
| Level 435 | 3 wins; 20, 21 and 22 moves of its 28-move allowance |
| Daily activities | 305 checks passed; zero failures |
| Existing release regression suite | Zero failures |
| Rendered desktop boot | Splash transitions into the game successfully |

The reproducible sample seed was 20261104. Cases tested: 51, 105, 112, 133, 153, 156, 192, 370, 415, 420, 435, 511, 561, 573, 637, 660, 714, 783, 940, 966, 1050. The sample contains six randomly selected additions per difficulty, plus cases 51, 435 and 1050. Twenty of these 21 cases had at least one winning baseline attempt.

The initial policies prioritized evidence, blockers or varied legal swaps. The follow-up on 783 additionally allowed every earned-special activation and prioritized remaining blockers after completing evidence. The initial policies only selected a special swap when it also passed the ordinary match validator. All runs used real Board swaps, cascades, refills, obstacle damage and move spending, with no purchased/tray boosters or extra moves. Simulations ran at Engine.time_scale = 50, so their wall-clock timings do not measure phone performance. No product level parameters were changed during testing.

Level 783 cleared all four blockers, but collected 16-21 of 24 keys in the baseline attempts and 15-22 keys in the follow-up, using all 30 moves. This is a difficulty flag, not proof that no free solution exists. Manually play this case and assess its move allowance before approving its medium difficulty label. Successful sample cases do not prove all 1,000 additions are solvable or appropriately balanced.

Daily checks cover 35 consecutive simulated UTC dates, exact seven-day reward amounts, five weekly payouts, same-day duplicates, Monday/week and midnight/day boundaries, missed-day grace and cooldown, both portrait slots, expiry, and mission reset/duplicate claims. A second real Godot process reloaded a saved in-progress portrait, preserved its arrangement/deadline, and verified claim and next-day streak persistence. Actual system time was not changed. The existing integration suite also solved the portrait through its tap handler, verified coin persistence and duplicate protection, and checked that campaign lives were untouched.

The existing bundle at `build/android/SaveTheBaby.aab` contains **50 level JSON files**, no daily-activity configuration, and `max_levels = 0`. It is not the updated 1,050-level game. Its SHA-256 is `c2dfee6ba6c91dbd83a6ab31549d5ded70228bfcc2c30a7e2aad8badc3ad9598`. A fresh signed AAB must be built from the tested source; the newly built artifact must then be tested on Android. This session did not upload or replace the bundle.

The Windows test environment reports that Godot cannot read the root certificate store. Network behavior on Android has not been verified by these desktop runs. The backup-recovery regression deliberately emits a corrupt-config diagnostic before successfully loading its backup. The release harness also emits an ObjectDB shutdown warning; this does not establish an in-game memory leak, and mobile memory/performance has not been certified.

Use the fresh bundle on [Google Play internal testing](https://support.google.com/googleplay/android-developer/answer/9845334) before public rollout. If the account is subject to Google's new-personal-account rules, its separate [closed-testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465) also apply. Store/account approval was not checked here.

Re-run the source suites from PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite random_release_checks
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite streak_release_checks
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite streak_release_checks -Resume
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite progression_daily_checks
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite release_checks
```

The random harness now includes unrestricted legal earned-special activation, so future random-suite results may differ from the recorded baseline policy. Raw results are in `.test-data/random-release-report.json`, `.test-data/random-release-focused.json`, `.test-data/streak-release-calendar.json`, `.test-data/streak-release-restart.json` and `.test-data/android-bundle-audit.json`. Each profile is isolated below `.test-data/`; normal player saves were not modified. The test launcher now waits for the actual Windows Godot process, returns its exit status, times out stuck runs, and rejects GDScript errors even if the process reports success.
