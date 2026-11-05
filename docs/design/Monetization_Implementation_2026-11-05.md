# Implemented economy revision — 5 November 2026

This revision adds a normal in-game buying flow, changes rewards and level budgets, and tests losing and recovery. It applies to the 1,050-file campaign. Original story levels 1–50 retain their authored definitions.

Version 6 follow-up: `Critical_Cases_and_Return_Assistance.md` adds 20 Critical Cases, occasional scout gifts and saved return assistance. Its additional tests supersede the assumption that every case should have an inventory-free winning path. The measurements below describe the earlier economy-only phase.

## Competitor comparison: one life versus a refill

| Game | Single-life evidence | Refill evidence | Reliability and limits |
| --- | --- | --- | --- |
| Candy Crush Saga | A firsthand King Community report lists one heart at 4 gold bars. | The same report lists five hearts at 12 bars: 2.4 bars per life in the bundle. | Historical player report, not a verified November 2026 Android offer. King support confirms buying lives but does not publish a universal numeric price. |
| Royal Match | No current standalone single-life price verified. | A December 2025 gameplay guide reports 900 coins for five lives: 180 coins per life in that bundle. | Reported gameplay price; 180 is arithmetic, not evidence that the game sells one life individually for 180. |
| Homescapes | No current standalone single-life price verified. | Reports commonly describe a 900-coin refill; older coverage conflicts about whether that means one life or a refill. | Do not use the old claim that one life universally costs 900 as a verified current benchmark. Official Playrix help confirms coins buy refills, moves and boosters, without a numeric refill price. |

Sources checked:

- Firsthand Candy Crush price report: https://community.king.com/en/candy-crush-saga/discussion/comment/2374090
- King life rules: https://candycrush.zendesk.com/hc/en-us/articles/360000750878-How-do-lives-work
- Royal Match reported refill: https://simplegameguide.com/how-to-get-free-lives-royal-match/
- Royal Match official coin uses: https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/21-how-can-i-obtain-and-use-coins/
- Homescapes official coin uses: https://playrix.helpshift.com/hc/en/14-homescapes/faq/1070-in-game-coins/

Nigeria's Apple storefront currently lists Candy Crush's 10-bar package at NGN 1,500 and an Extra Moves product at NGN 1,500. At that pack's rate, four bars have NGN 600 of currency value **if** the historical four-bar life offer is available. This is not a verified current NGN 600 single-life Android transaction, and the minimum pack purchase is still NGN 1,500. Royal Match's Nigeria listing includes a Mini Coin Package at NGN 3,200 but does not state its coin quantity, so its naira price per life cannot be calculated reliably from that listing.

- https://apps.apple.com/ng/app/candy-crush-saga/id553834731
- https://apps.apple.com/ng/app/royal-match/id1482155847

## Difficulty and reasons to recover

King describes Hard, Super Hard, Nightmarishly Hard and Legendary levels. Playrix describes Regular, Hard, Super Hard and Ultra Hard levels and increased rewards for harder levels. Dream Games confirms coins buy moves, lives and boosters. These establish the product pattern; they do not publish human failure-rate targets that can be copied into this game.

- https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find
- https://playrix.helpshift.com/hc/en/14-homescapes/faq/43938-match-3-level-types-by-difficulty/

The implemented recovery choices address different needs:

- A life buys another attempt from a fresh board.
- A five-move continuation preserves the current board and objective progress. One coin continuation and one existing rewarded-ad continuation are allowed per attempt. Each restores the life deducted on its respective failure; another failure still costs a life.
- An optional rewarded ad offers recovery without spending coins, when loaded. Closing an ad without the SDK reward event grants nothing. There is no promise of an ad being available or of receiving advertising revenue.
- The free 30-minute life timer remains available.

## Implemented prices and rewards

| Item | Previous | New |
| --- | ---: | ---: |
| One life | No dedicated offer | 200 coins |
| Full life refill | 100 coins | 900 coins, up to five lives |
| Five extra moves | Ad continuation only | 500 coins or the existing available rewarded-ad continuation |
| Rocket | 35 | 150 |
| Bomb | 50 | 250 |
| Thunder | 70 | 350 |
| Ethan assist | 90 | 400 |
| Added-level first clear | 50 regardless of difficulty | Easy 30; Medium 40; Hard 60 |
| Coin reward for every created special | 3 | 0 |
| Free booster milestone | Every 3 created specials | Every 15 |
| Victor coin reward | 10 per collected Victor tile | 2 per tile |
| Character assist reward | One assist per character tile | One per three collected Ethan/Detective tiles in an attempt |
| Remaining-special clear bonus | Unbounded at 5 per special | At most 25 per clear |
| Portrait completion | 30 | 15, twice daily |
| Daily mission rewards | 20 and 25 | 10 and 15 |
| Seven-day stamp cycle | 10/15/20/25/30/40/60 | 5/10/15/20/25/30/40 |
| Weekly chest | 75 | 50 |

These are initial settings for this game, not claimed competitor prices or proven optimal prices. Existing balances and inventories are preserved. Cash prices for coin packs are supplied by Google Play and have not been changed through local code.

The added campaign keeps the existing ten-case Easy/Medium/Hard cadence. Normal move budgets are now 28/26/24, with two additional moves in levels 51–100. Level 105 has 26 moves after the first trial found no free win at 24. Level 783 has 28 moves and a 20-item objective, addressing repeated failures in its earlier definition. The final level, 1050, has 26 moves after its 24-move trial lost all three policies. Its follow-up won two of three. These exceptions are stored in the offline builder configuration as well as the level JSON files.

## Spending and payment correctness

- The HUD coin counter opens the store. Life offers, booster offers and the result-screen Play On button use the same store.
- Buy Coins is visible at the top of the store. Pack prices come from Google Play product details; no invented cash prices are displayed.
- Earned and purchased balances are shown separately and can fund the same supply purchase. Earned coins are used first. The paid ledger remains on the server; purchased currency is not copied into an editable local coin balance.
- Combined spending uploads the current snapshot, checks the authoritative price and revision, debits both sources atomically, and returns the updated supply inventory. A lost response retries the same request ID instead of buying twice.
- Applying a purchased supply updates the economy in place, preserving the active board. An ambiguous unrecoverable response stops further synchronization until the cloud save is reconciled.
- Full-life and full-assist purchases are rejected. Coin purchases require confirmation. Sign-in is accessible from a level result as well as the map and title screen.
- Online catalog version 2 identifies the new spending contract. Old servers cannot silently substitute their previous prices; old clients without an expected price are rejected by the new server instead of being charged an unconfirmed higher price.
- Client offline prices and server prices have a contract test to catch drift. The account screen reads live server prices rather than maintaining another hardcoded price table.

## Validation and operational limits

Automated checks cover actual earned-coin deductions, insufficient funds, full-life rejection, continuation consumption, active-board preservation, atomic combined spending, concurrent/replayed requests, stale prices, interrupted responses, and rewarded-ad closure/duplicate callbacks. Campaign schema and board checks cover all 1,000 additions. Calendar and cross-process restart checks cover daily rewards.

`tools/run_balance_checks.ps1` compares committed revision `e764ce9` with the revised files using identical initial seeds and three playing policies across nine selected cases, three per difficulty. It records initial wins/losses and separately probes whether five extra moves rescue a failed board. Per-attempt checkpoints preserve partial results; only a completed run is a full result. The first larger comparison exceeded its time limit and is not presented as a completed result.

Use `tools/report_economy_balance.py` after the comparison to generate the measured report. Bot outcomes are not human win rates or revenue forecasts. No level has been made dependent on a player's payment history.

Completed measurements: 57 playthroughs including the final-level follow-up. The final matched comparison has 21 wins and six losses in 27 attempts on each version; hard-case losses increased from two to three while medium-case losses decreased from four to three. Five extra moves rescued four of the six final revised losses. Each sampled case has at least one free win. Full results are in `docs/testing/Economy_Balance_2026-11-05.md`.

The game now records local `user://balance_events.jsonl` diagnostics for attempt outcomes, earned coin changes, shop results and rewarded-ad results. The log rotates at approximately 1 MB, has no account identifiers and is not uploaded. It does not replace live ad or Google Play financial reports.

Both the updated backend and Android client must be deployed for combined paid spending. The signed v5 bundle does not deploy Render. Real Google Play purchase confirmation and actual AdMob delivery still need validation on the Play test track; local test adapters and the in-memory backend cannot certify those external services.
