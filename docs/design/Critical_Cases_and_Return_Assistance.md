# Critical Cases and return assistance

Implemented on 5 November 2026 on top of the economy revision. The game uses **Critical Case** as its player-facing label.

## Authored challenge cases

Levels 100, 150, 200 and every 50 levels through 1050 are Critical Cases: 20 physical JSON definitions in the existing levels folder. They retain evidence goals and normal obstacle mechanics, with one reinforced evidence seal.

The seal survives ordinary matches, board-created special blasts and Ethan assists. A Rocket, Bomb or Thunder fired from the inventory can break it. Cascades triggered by ordinary play do not change this rule. A booster can be earned, received as a scout gift, awarded for a completed ad, or bought; its source does not change its effectiveness. Boosters still require aiming, and using one does not guarantee that the remaining evidence objective will be completed.

The briefing says **CRITICAL CASE**, recommends a supply, and offers access to its shop. It does not announce a mandatory booster or disable Play when inventory is empty. The obstacle is marked **SEAL**. Prices and coin purchases retain their explicit confirmation screens.

Recommendations rotate across Rocket, Bomb and Thunder. Cases 100, 300, 500, 700 and 900 offer one matching scout supply before play. Each gift is saved with its claim marker in the same progress transaction; revisiting or restarting cannot claim it again. Critical first clears award 80 base coins. The other first-clear tiers remain Easy 30, Medium 40 and Hard 60.

## Return assistance

The settings live in `configs/difficulty_policy.json`. The current rule requires:

- An added Medium, Hard or Critical Case with at least three failed attempts.
- At least six hours since the saved last activity, followed by a return session.
- A 30-minute window to choose the assisted attempt.
- No previous assisted attempt for that case and no other return assistance within 24 hours.

An eligible attempt gets four extra moves, a refreshed opening seed and 1.6 times the mission tile's authored spawn weight. Its refill generator has a 20% chance to allow an ordinary weighted spawn instead of rejecting an immediately matching refill, allowing more favorable cascades. The initial board still starts stable and must contain a legal move.

The preview is deterministic within the saved return window, so reopening a briefing does not repeatedly reroll it. The bonus is consumed when Play starts, not when the briefing opens. Failure history and claims persist in the player's progress and travel with that profile's cloud save. Clock rollback cannot claim a window. Returning never removes a Critical Case seal's inventory-booster rule.

The authored level files remain the base definitions. Runtime assistance makes an attempt-only copy; it does not rewrite the levels folder or silently replace the whole campaign. Spending history is not an input. A failed continuation is counted as part of the same attempt rather than a fresh failure toward the three-attempt threshold.

## Evidence and limits

King's support describes boosters as assistance for difficult levels. Community players report that returning can feel easier, but those reports do not verify King's exact spawn algorithm, absence timer or a rule that its levels necessarily require boosters. This project's return policy is our implementation, not a claimed reproduction of a confirmed King algorithm.

- Official booster explanation: https://candycrush.zendesk.com/hc/en-us/articles/360000750998-What-are-Boosters
- Player observations, not developer confirmation: https://community.king.com/en/candy-crush-saga/discussion/comment/3460766

## Validation

- `difficulty_checks`: 93 passing checks covering all 20 Critical Case definitions and labels; repeated ordinary damage; board-special blasts; Ethan exclusion; all three inventory booster kinds; real inventory consumption; one-time scout supplies; saved return eligibility; a refreshed seed; increased target weights; rollback protection; and one-time assistance consumption.
- All 1,000 added level definitions and opening boards pass the progression suite after these changes.
- Six actual Critical Case playthroughs, three policies each on cases 100 and 1050, use one inventory Rocket at the start. Case 100 wins two of three; case 1050 wins one of three. No technical assertions fail. A booster opens the seal without automatically winning the case.
- Three actual assisted playthroughs on case 105 win three of three, compared with one of three in its ordinary economy-revision definition using the same three policies. Assisted case 105 has 30 moves versus 26 ordinarily. These are bot-policy observations, not human probability estimates.
- A rendered 450-by-800 briefing check verifies the Critical Case presentation and recommendation flow.

Raw results: `.test-data/difficulty-checks.json`, `.test-data/critical-case-trials.json`, `.test-data/return-assistance-trials.json`. The earlier 57-playthrough economy report predates the inventory seals; its free-win observations must not be interpreted as a promise that current Critical Cases are winnable without tray boosters.

The signed version 6 client is the artifact for these additions. Version 5 contains the earlier economy revision. Combined spending still requires the updated backend, and live Google Play payments and actual AdMob inventory require device/Play-track validation.
