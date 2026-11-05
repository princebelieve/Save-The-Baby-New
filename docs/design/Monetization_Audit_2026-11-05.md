# Economy and monetization audit — 5 November 2026

Status: source and competitor-support audit, not validated human balance. No gameplay prices or level files changed by this audit.

Implementation follow-up: `Monetization_Implementation_2026-11-05.md` records the changes now made; `../testing/Economy_Balance_2026-11-05.md` contains the measured comparison. The findings below describe the pre-change economy.

## Verified project findings

- `configs/economy.json`: five-life refill costs 100 earned coins. `configs/game.json`: five maximum lives, 30-minute regeneration, 100 starting coins.
- `configs/rewards.json`: each added level, 51–1050, awards 50 base coins on its first clear. Two first clears therefore fund five lost lives, excluding all other rewards. This ratio needs validation; the number 100 alone says nothing about its monetary value.
- Five new-level wins yield 250 base coins. Five subsequent losses and one full refill cost 100, leaving 150, before boosters, daily rewards and special-piece rewards are considered. This is an illustrative sequence, not a measured player session.
- Special-piece creation grants three coins and a booster every three creations. Daily activities also supply coins: two portrait completions yield 60, missions yield 45, and streak/weekly rewards add more. These sources must be measured together with spending.
- `scripts/online/AccountPanel.gd` shows Google Play packs and purchased-wallet supplies only after sign-in. Purchased coins are a separate server wallet from earned campaign coins. The ordinary life shop uses earned campaign coins. Identically named currency in separate spending flows creates purchase friction and confusion.
- The refill price is duplicated: economy JSON, AccountPanel's supply array, and `server/src/domain.js`. Changing only the JSON would leave paid and earned spending inconsistent.
- Rewarded life and booster offers already exist. `AdProvider.gd` depends on the Android plugin, consent and loaded inventory. A visible offer is not proof of a completed, revenue-generating impression. Desktop ad previews are simulated.

## Competitor evidence

Official support pages checked on 5 November 2026:

| Game | Verified behavior | Useful lesson |
| --- | --- | --- |
| Candy Crush Saga | Five lives; a failed level costs one; each life regenerates in 30 minutes; players can buy lives, buy extra moves, or ask friends for lives. | Sell a useful continuation at the point of need while retaining a free recovery route. |
| Royal Match | Five normal lives, eight with Royal Pass; failure costs a life; regeneration takes 30 minutes; team life requests. | The standard five-life limit itself is not the problem; progression, offers and value matter. |
| Homescapes | Coins are earned through levels and other activities, bought with real money, and spent on boosters, additional moves/time and refills. | Earned and paid coins can coexist coherently; free earnings are not inherently incompatible with purchases. |

Sources:

- https://candycrush.zendesk.com/hc/en-us/articles/360000750878-How-do-lives-work
- https://dreamgames.helpshift.com/hc/en/3-royal-match/faq/5-lives/
- https://playrix.helpshift.com/hc/en/14-homescapes/faq/1070-in-game-coins/

These sources do not establish comparable localized cash prices, exact refill-price ratios, conversion rates, or a suitable failure rate for this game. Do not invent those figures or copy an unsupported competitor price.

## Limits of the previous level tests

The saved baseline report contains 63 bot attempts: 49 wins and 14 losses. EASY: 21/21 wins; MEDIUM: 12/18; HARD: 16/24. A focused level-783 follow-up lost another three attempts. These tests establish some mechanical behavior and identify difficult cases. They do not establish human win rates, retention, willingness to watch ads, purchase conversion or profitable balance. Repeated policy attempts must not be counted as repeated first-clear coin rewards.

## Recommended implementation order

1. Repair the spending journey: expose the store from the HUD and insufficient-funds/refill dialogs; clearly show which balance is usable. Design one coherent coin experience while preserving server verification, purchase ledger, existing balances and cloud ownership safeguards. Do not simply copy purchased funds into an editable local balance.
2. Collect attempt-level outcomes: level and seed, attempt number, win/loss, remaining objectives, moves used, booster use, coin sources and sinks. Include currency and inventory carried across sessions. Compare fresh players with players who already have stocked rewards.
3. Run difficulty tests explicitly covering losses and retries across early/middle/late progression, followed by human Play testing. Identify trivial, repeatedly frustrating and technically unwinnable cases separately. Tune move budgets and objectives with evidence; do not assume making every level harder improves revenue.
4. Balance the whole economy: first-clear coins, special-piece coins, free boosters, daily rewards, refill and continuation costs, and coin-pack purchasing power. Check replay farming and repeated failure/retry rewards. Make prices consistent between client and server. Do not pick another arbitrary refill number before measuring the combined income.
5. Offer optional rewarded recovery where useful: one life when depleted, and an explicitly bounded continuation if implemented. Grant only on the reward callback, never on ad close or load failure. Keep a visible waiting option and verify live Android delivery and completion events.
6. Test real purchase cancellation, pending payment, verified payment, interrupted delivery, duplicate callbacks and restoration through a Google Play test track. Actual regional pack prices must come from Play product details.
7. Evaluate retention, attempts per level, coin balance over time, rewarded-ad availability/completion, purchase conversion and revenue together. No revenue or release-readiness claim follows from bot wins alone.

The first correction should be the confusing paid spending path and missing economy evidence, followed by coordinated balance changes. Raising only the life price would leave both issues in place.
