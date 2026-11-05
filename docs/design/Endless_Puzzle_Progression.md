# Save the Baby: Puzzle, Progression, and Economy Rules

This is the product and implementation contract for campaign and future endless play. David is the player solving Victor's increasingly demanding puzzles. Amara is the in-world source of useful supplies and earned rewards. Victor designs the pressure and obstacles. Ethan is the rescue stake and a rare special tile.

The goal is a puzzle game where each move has a consequence. A board must not quietly complete itself after a few refills, and a player must always understand the goal, the remaining moves, and why a win or loss occurred.

## Player-facing rules

1. Show one clear primary objective before the first move. Show its symbol in the middle of the objective card and the required/collected count below it. Do not print redundant names such as “KEY” beside a recognizable key icon.
2. Show blockers as a separate, counted requirement whenever the board contains blockers. A blocker counts as cleared only when its health reaches zero. Every hit visibly reduces its health, emits particles, and sends the remaining-health value upward.
3. A level wins only after every required objective is complete. It fails when the move allowance ends with any required objective incomplete. Show the unmet requirement on the result screen.
4. Every accepted swap spends a move, including a swap that creates a special piece. Invalid swaps return to their original cells and do not spend a move.
5. A special piece is earned by the match shape described in the field guide. It remains on the board until the player swaps it, then visibly performs its configured clear. Special creation and activation must never silently grant a win.
6. Failure removes one life. Render lives as a horizontal row of hearts; remove one heart on failure and persist that count between games. Refill lives through regeneration or the configured shop.
7. The HUD uses a small target symbol, large readable numbers, and concise labels. Booster symbols stay smaller than their stock counts and sit below the board. An empty booster remains selectable to open its purchase offer.
8. A win names the completed case, shows the reward being added, and unlocks the next case. Only the last case in a chapter completes that story objective. Do not play those two completion cues together.

Tutorial cases are the only intentionally extremely easy cases. A tutorial must teach one rule, give the player a safe first move, and explain the move, objective, obstacle, or booster consequence before normal pressure resumes.

## Difficulty cadence

Use the level's difficulty field as authored intent, then tune board geometry, move budget, objective counts, tile weights, and obstacle health together. A label by itself does not make a level difficult.

For each ten-case band after its tutorial:

- Cases 1–2: very easy onboarding or recovery.
- Cases 3–4: easy, introducing one new pressure.
- Cases 5–6: medium, combining known rules.
- Cases 7–8: hard, requiring a plan and meaningful trade-offs.
- Case 9: a recovery or skill-check case chosen to vary the rhythm.
- Case 10: chapter finale with a distinctive board, story beat, and milestone reward.

Across multiple bands, rotate which cases are easy, hard, extremely easy, and extremely hard. Do not put the hardest case on the same ordinal every time. Do not make every chapter finale the same board with a larger count. The endless sequence uses a seeded challenge schedule that alternates pressure and recovery; it must never scale objective counts without also checking whether the target remains reachable.

Every case must be winnable from at least one legal move sequence within its move budget. The board generator must ensure a legal opening, avoid dead boards, and reject a generated objective that cannot be completed from the placed obstacles and tile pool. Difficulty comes from meaningful choices, blockers, limited moves, and objective combinations—not from a goal that is impossible or random refill luck alone.

## Endless generation contract

The campaign contains 1,050 numbered JSON files in levels/: level001.json through level1050.json. The original 50 files remain intact. Cases 051 through 1050 were composed offline and written as complete, editable files using the existing Levels API schema. LevelManager and the map read these files directly; missing files are not generated at runtime, and saved generation snapshots do not override them. Reward entries for the additional cases live in configs/rewards.json. The map displays 50 cases per page.

The optional content-building tool is tools/materialize_campaign.tscn, backed by tools/CampaignLevelBuilder.gd and configs/endless_progression.json. It skips existing files to preserve manual edits and is never called by gameplay. To add or tune a shipped case, edit its numbered JSON file and reward entry using the existing project system.

The following is a future endless-play proposal, separate from the current file-backed campaign:

1. Add configs/endless_progression.json for chapter length, difficulty cadence, objective pools, board templates, allowed modifiers, reward bands, and caps.
2. Add an EndlessLevelGenerator that accepts a level number and stable seed and returns the same full Level JSON schema used by authored files.
3. Build each generated case from validated templates drawn from the existing tile, powerup, obstacle, background, and prop configs. Change board silhouette, blocked cells, obstacle placement, tile weighting, objective, and visual theme as separate choices.
4. Validate the generated data against the Level API schema, then validate that its board has legal moves and a feasible objective before passing it to BoardManager.
5. Make the map generate virtual chapter sections on demand, using the same chapter metadata and props as authored chapters. Keep the current and next sections loaded; do not create an unbounded number of controls.
6. Store the seed, generated definition version, completion, and reward claim in save data. Retrying a case must recreate the same board. Updating generation rules must not change an already-started case.
7. Keep story chapters finite and authored. Endless cases continue the search as optional play; they must not falsely claim that the main story has ended or been completed.

The generator owns composition only. LevelManager loads and validates definitions, BoardManager creates boards, Board resolves matches and blockers, RewardManager grants configured rewards, and EconomyManager owns persistent resources. Constants.gd contains structural enums and paths only.

## Rewards and sustainable spending

Coins have practical uses: lives, boosters, and future cosmetic or convenience offers. Prices and quantities belong in configs/economy.json. Rewards belong in configs/rewards.json; level definitions may reference reward identifiers as that schema evolves.

Current reward hooks:

- First-clear level coins and stars are granted through RewardManager.
- Creating a special match awards the configured coin amount.
- Every configured number of special creations awards one matching field booster.
- Chapter finales award a configured booster.
- Matching Ethan or the detective earns an Ethan rescue assist; matching Victor earns coins.
- Rocket, bomb, thunder, and Ethan assist purchases use the configured coin shop.
- Lives are lost on a failed case, so moves and lives have visible stakes.

These values are tuning data, not permanent promises. Adjust them by testing progression pace and expected player spend. Reward amounts should make ordinary play useful while leaving a real choice about when to spend. No level may require a paid item: every case needs a fair free solution, and retrying must remain possible through earned lives or regeneration.

Real-money purchases and rewarded ads are not connected in the current project. When added, implement them behind platform billing and ad-service adapters. An ad reward must be opt-in, granted only after the provider confirms completion, and unavailable offers must be hidden. Never display a purchase or ad as successful before the platform confirms it. Keep prices, reward amounts, offer frequency, and availability in configuration; do not put store logic in Board or tile code.

## Board and map variety

Use the existing assets before requesting more art. assets/sprites/props/ already contains tree and bush cutouts, fences, bridges, a police car, rocks, a bicycle, a bench, a mailbox, industrial props, hazard markers, and evidence cases. CampaignMap should place a small theme-matched pair of props at the edges of each chapter section, behind the trail and level buttons. Rotate the pairs by chapter and keep the path and buttons readable.

For boards, vary:

- rows, columns, blocked cells, and spawn points within the mobile-safe board area;
- tile-pool weights and objective symbols;
- obstacle types, positions, and health;
- chapter background and board treatment;
- special-piece opportunities and tutorial prompts.

Each authored case should have a short design note naming the rule it teaches or tests, its intended difficulty, its primary objective, any secondary blocker objective, the main decision the player faces, and why the move budget is fair. Endless templates should carry the same note as structured template metadata so generated cases can be inspected and tuned.

## API ownership and current gaps

| Concern | Owner / data source | Rule |
|---|---|---|
| Structural enums and paths | scripts/utilities/Constants.gd | No prices, difficulty tuning, or level-specific values |
| Tile identity, texture, special flag | configs/tiles.json via TileDatabase | Character tiles are configured as special; Board does not infer filenames |
| Powerup definitions | configs/powerups.json | Match-created specials and shop boosters use the same configured behavior |
| Obstacle health and behavior | configs/obstacles.json | Board reports damage and completed destruction; it does not decide the mission reward |
| Authored levels | levels/levelNNN.json | Every level uses the frozen Levels API schema |
| Reward tables | configs/rewards.json via RewardManager | Gameplay submits reward events; EconomyManager applies resource changes |
| Prices and inventory | configs/economy.json via EconomyManager | UI offers purchases; UI does not alter inventory directly |
| Campaign map art | level chapter metadata plus assets/sprites/props/ | Map presentation reads data and does not own progression |

The current runtime still has these known extension points:

- _get_primary_objective() and the gameplay HUD primarily model one evidence objective; the added blocker requirement is a secondary counter. Full objectives[] support needs a generalized objective tracker rather than more conditionals in Game.gd.
- The campaign is file-backed through level 1050, with paged map sections and seeded board generation. Automated checks cover every added JSON file and runtime board opening; full solution search and difficulty calibration remain open. Runtime endless generation is not enabled.
- Store purchases and ads are not integrated with real platform services.
- Difficulty definitions and progression cadence need a playable tuning pass across device sizes.

Implement those gaps through the named APIs. Do not solve them by embedding level numbers, prices, reward amounts, or asset filename guesses in gameplay code.


## Daily activities implemented

`configs/daily_activities.json` configures a seven-stamp coin cycle, one missed-day protection per seven days, a five-stamp weekly bonus, and daily goals for special creation and blocker clearing. A completed campaign case (including a replay) or restored portrait earns a stamp once per UTC calendar day. Goal rewards do not themselves earn a stamp.

The campaign footer opens the portrait game and the daily rewards/portrait album screen. Portraits are nine-piece tap-to-swap puzzles with a 120-second timer and no lives, moves, or campaign progress cost. Slots reset at 00:00 and 12:00 UTC (01:00 and 13:00 in Lagos). Starting consumes the current slot; exiting preserves the arrangement and deadline so a player can resume until expiry. Attempts stop at the next slot boundary. A slot can pay only once, and restored portraits accumulate in the album.

Daily claims and economy changes are written together through CampaignProgressStore. Clock rollback is rejected against the last recorded activity time; the live countdown also checks monotonic time. This is an offline device-clock design, not server-authoritative scheduling or cross-device anti-cheat. The existing account snapshot includes the new save sections.

Run `tools/run_checks.ps1 -Suite progression_daily_checks` to check the 1,000 added level files and runtime board openings, calendar/claim rules, map pagination, portrait completion, and persistent rewards. This checks valid starting boards and integration, not a proof that every case has a winning sequence within its move budget. The generated cadence and economy still need a human playtesting pass before release.
