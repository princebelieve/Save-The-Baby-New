# Measured economy and difficulty check — 5 November 2026

Historical phase: this comparison predates the Critical Case inventory seals. Current Critical Cases intentionally require a tray booster. See `../design/Critical_Cases_and_Return_Assistance.md` for current mechanics and the additional nine playthroughs.

These are actual Board swaps, cascades, obstacle damage and refills. Initial outcomes exclude tray boosters and extra moves. A separate five-move probe then tests recovery on each failed board. These are deterministic bot-policy outcomes, not estimated human probabilities or revenue.

Baseline: committed level definitions at `e764ce9`. Three policies per case, nine selected cases (three per difficulty), using the same seed and policies before and after. Both batches completed without technical assertion failures.

| Difficulty | Before wins / losses | After wins / losses | Revised losses rescued by five moves |
| --- | ---: | ---: | ---: |
| EASY | 9 / 0 | 9 / 0 | 0 |
| MEDIUM | 5 / 4 | 6 / 3 | 1 |
| HARD | 7 / 2 | 6 / 3 | 3 |

Before: 21 wins and 6 losses in 27 initial attempts; five extra moves rescued 5 failed attempts.

After: 21 wins and 6 losses in 27 initial attempts; five extra moves rescued 4 failed attempts.

| Case | Difficulty | Old free wins | Revised free wins | Revised continuation wins |
| --- | --- | ---: | ---: | ---: |
| 51 | EASY | 3/3 | 3/3 | 0 |
| 105 | HARD | 2/3 | 1/3 | 2 |
| 133 | MEDIUM | 3/3 | 3/3 | 0 |
| 435 | HARD | 3/3 | 3/3 | 0 |
| 511 | EASY | 3/3 | 3/3 | 0 |
| 637 | MEDIUM | 2/3 | 2/3 | 0 |
| 783 | MEDIUM | 0/3 | 1/3 | 1 |
| 966 | EASY | 3/3 | 3/3 | 0 |
| 1050 | HARD | 2/3 | 2/3 | 1 |

Cases without an initial free win under these policies: none. A bot loss is not proof of an impossible level.

The first revised batch had 19/27 wins and no free win on level 1050. That case was adjusted from 24 to 26 moves and all three policies were rerun; its follow-up replaces that case in the final comparison above. Raw first-trial results remain unchanged. Total completed playthroughs: 57 (27 baseline, 27 first revision, three final follow-ups). Follow-up: `.test-data/balance-final-1050.json`.

## Currency purchasing power

| First-clear tier | Base coins | Clears to fund one 200-coin life | Clears to fund a 900-coin refill |
| --- | ---: | ---: | ---: |
| EASY | 30 | 6.67 | 30.00 |
| MEDIUM | 40 | 5.00 | 22.50 |
| HARD | 60 | 3.33 | 15.00 |

Even an upper-bound daily combination of two portraits, both missions, the largest stamp and the weekly chest is 145 coins, below one 200-coin life. This excludes campaign clears and character rewards and is not a total player-income measurement.

Previously two 50-coin first clears funded five lives. The revised refill requires 15 hard clears, 22.5 medium clears or 30 easy clears before other income. Existing balances are retained.

## Reproduce and limitations

Run `powershell -ExecutionPolicy Bypass -File tools/run_balance_checks.ps1`, then `python tools/report_economy_balance.py`. Raw reports and per-attempt outcomes are in `.test-data/balance-before/report.json` and `.test-data/balance-after/report.json`.

All 1,000 added boards have separate schema/opening-board validation. These nine cases do not establish full-campaign human balance. Automated payment checks use a local test server; actual Google Play transactions, AdMob inventory and human retention still require Play-track testing. See `docs/design/Monetization_Implementation_2026-11-05.md` for implementation and sourced competitor price distinctions.
