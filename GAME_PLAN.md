# Save The Baby — Game and Production Plan

## 1. Product vision

Save The Baby is a story-led Match-3 adventure built around David’s continuing effort to rescue Ethan from Victor. The first 50 levels are the opening stretch of the campaign, not the whole game or a fixed endpoint. The campaign is designed to keep growing through new chapters, locations, mechanics, events, and level packs, as in long-running puzzle adventures.
 
The game should feel approachable in a single level and rewarding over a long progression: clear goals, satisfying matches and cascades, expressive powerups, steadily introduced hazards, story scenes with meaningful context, and rewards that make progress visible.

The project also aims to build a reusable Match-3 engine. Save The Baby is its first game. The engine and content pipeline should support extensive future content without requiring an engine rewrite for every new level or chapter.

## 2. Player promise and core loop

The player follows David as he investigates Victor’s kidnapping, gathers evidence, faces Victor’s traps, reaches the factory, and works toward rescuing Ethan. The opening offers three approaches—call the police, trace the signal, or go alone. These choices shape scenes, dialogue, presentation, and the kind of investigation or hazards emphasized. They are not three permanently separate 50-level campaigns. The main campaign can reconverge at shared story milestones, while later chapters can revisit the consequences of earlier choices.

The repeatable level loop is:

1. Enter a level with a story or mission context and a set of objectives.
2. Swipe between adjacent tiles to make a legal swap.
3. Match three or more pieces, trigger special pieces and cascades, and resolve gravity/refills.
4. Make progress toward the level’s objectives within its move or timer limit.
5. Win or fail; award configured results, update progress and save, then offer retry, map progression, or the next story beat.

Level goals can include collecting evidence and mission items, clearing obstacles, opening routes, defusing threats, earning a target score, or completing a rescue-related objective. A level may combine objective types when it remains understandable and fair.

## 3. Campaign and content scale

### Opening campaign (Version 1.0)

Version 1.0 targets approximately 50 carefully authored levels as the first substantial release, plus the opening story, the first chapter’s resolution at Victor’s factory, a rescue sequence, and a boss-style confrontation. Fifty is a launch milestone and a starting content pack. It is not a maximum level count, a limit on future chapters, or a promise that every later update needs an engine change.

The three opening approaches establish distinct story presentation and can change selected scenes, dialogue, evidence framing, and level dressing. The first release should keep the playable campaign achievable by sharing the central progression and introducing controlled variations, rather than multiplying the initial content workload into three complete 50-level tracks.

### Continuing campaign

The long-term game is an ongoing quest. New chapters can add locations, characters, villains, mechanics, obstacles, objectives, level collections, and story decisions. Level identifiers and save data must support growth beyond 50 without renumbering or overwriting existing progress. Chapter and level content belongs in data/resources, not level-specific engine code.

Post-launch content is planned to include additional chapters and level packs, more villains and environments, seasonal events, daily challenges, new obstacles and powerups, localization, and other progression features. Content cadence and exact quantities are production decisions; the architecture must not impose a fixed campaign ceiling.

## 4. Match-3 gameplay

### Board and pieces

Use swipe-to-swap input on adjacent pieces. A normal accepted move must create a valid match unless a configured special rule says otherwise. Resolve all matches, special effects, gravity, refill, and cascades until the board is stable. Board dimensions, spawn pools, move limits, objectives, layout, blockers, and other level rules are data-driven.

The board should support normal matchable pieces as well as mission pieces and special pieces. Mission art such as a key or evidence item should only be matchable when the level configuration allows it. An obstacle can occupy a cell, cover a piece, restrict movement, require hits, count down, or interact with a specific special effect. These behaviors should be explicit in the level and obstacle data.

### Match shapes and powerups

The intended match patterns include straight matches, L/T shapes, and square matches where supported by the rules. Pattern-to-powerup rules should be consistent and taught in play.

- Four in a line creates a Rocket that clears a row or column.
- Five in a line creates a Thunder piece that clears a selected piece type (or follows the configured targeting rule).
- A square match creates a Bomb that clears nearby cells.
- Special-piece combinations have their own effects, feedback, and animations. Planned combinations include Rocket+Rocket, Rocket+Bomb, Bomb+Bomb, Bomb+Thunder, and Thunder+Thunder.

The exact balance, targeting, and compatibility rules are authored and tuned through configuration. Effects must resolve safely when multiple specials trigger together.

### Obstacles and mission objects

The initial content vocabulary includes chains, locks and keys, tape, bombs, missiles, electric traps, doors, pliers, and pinchers. These are introduced gradually. Each obstacle defines its placement, durability or countdown, what actions affect it, and how it communicates state to the player. New obstacle types should plug into the existing obstacle contract and data pipeline.

Evidence and story objects can include phones, fingerprints, recordings, documents, clues, and keys. Match objectives should make their narrative meaning clear: for example, collecting phone records during the police investigation or using signal evidence in the tracing route.

## 5. Progression, rewards, and retention

The progression design includes levels, stars or another clear completion rating, coins, lives, boosters, treasure rewards, streak or completion bonuses, daily rewards, and a shop. Rewards and costs are configured rather than embedded in gameplay scripts. A reward is granted for an explicitly defined achievement (such as completing a level or earning a rating); ordinary matches count toward score and objectives according to level rules.

Lives limit repeated failed attempts and can be replenished by a configured regeneration timer or by approved reward flows. The final regeneration interval, cap, and refill rules are balancing values, not architecture decisions. Tutorial levels and other explicitly configured cases may have special life-loss rules.

Ads are a planned part of the product, including rewarded ads and, if the final product design supports them, interstitial or banner placements. Rewarded ads may offer a clearly described optional benefit such as an extra life or reward. Ad placements must respect gameplay, platform requirements, and player settings. The game must remain operable when an ad is unavailable or the player declines it. Ad integration is scheduled after the core game loop, progression, and save behavior are stable; it is not a first milestone.

## 6. Story and choices

The first story arc begins with Victor kidnapping Ethan and Amara asking David for help. David chooses to call the police, trace Victor’s signal, or go alone. Each approach receives suitable scenes and dialogue and can affect presentation or selected mission framing. The story proceeds through investigation, leads to Victor’s factory, and culminates in a confrontation and rescue. Story scenes recur at campaign milestones, rather than interrupting every few levels without regard to pacing.

Dialogue, portraits, backgrounds, choices, conditions, sound, and transitions should be content-driven. Choice state must be saved and available to story conditions. Branches may diverge and reconverge; the system must support either without hardcoding a single three-track structure. Later chapters can build on prior decisions and introduce new branches.

## 7. Online and live features

Online features are part of the intended product direction and are staged after a reliable offline game and account/save model exist. Planned online capabilities include cloud save synchronization, leaderboards, and event/daily challenge support. Online events and seasonal content should be configurable and time-aware. The architecture should allow authenticated service integration and safe handling of offline, timeout, and conflict cases.

These features are not all prerequisites for the initial playable build. They belong on the release roadmap after core gameplay, local persistence, and platform foundations. The plan is to deliver them deliberately, not to omit them from the product vision.

## 8. Platforms and business goals

Godot 4 and GDScript are the current development foundation. VS Code is used for code and project files; Godot is used to import, edit scenes/resources, run, and export the game. Android is a primary release platform. Windows is also a Version 1.0 target. The project should keep input, resolution, performance, and UI layout adaptable so other platforms, including web where appropriate, remain possible.

The intended quality bar is a polished, releasable game with stable performance, legible responsive UI, touch-friendly controls, accessible settings, coherent audio/visual feedback, complete first-chapter progression, working save/reward systems, and no known release-blocking defects. Commercial quality is the goal; it is not a claim that the current project has already reached that state.

## 9. Architecture and content rules

- Keep systems modular, reusable, testable, and maintainable. Give each manager/component one clear responsibility.
- Use the established project folders and contracts documented in the API maps. API maps and `scripts/animation/AnimationFolderResponsibity.md` remain the detailed subsystem references; this plan defines product direction and production order.
- Prefer data/resources for levels, story, objectives, rewards, economy, tile/obstacle definitions, settings, and progression. Adding a level or ordinary content should not require a bespoke engine code path.
- Keep board resolution separate from story, save, economy, and presentation concerns. Systems communicate through their public APIs/signals.
- Give persistent level and chapter identifiers stable, extensible formats. Migrations must protect player progress as saves evolve.
- Keep a developer tool path for jumping to a level/story scene, inspecting board state, and granting test resources. Developer tools must not leak into release behavior unintentionally.
- New content must be validated for missing data, impossible boards, invalid objective targets, broken story references, and missing assets.

## 10. Production roadmap

Work proceeds in dependency order. A phase is complete when its feature works, is integrated with existing APIs, has appropriate data/configuration support, is reviewed and documented, and has no known critical regressions. Do not start every product feature at once.

### A. Project and engine foundation

Confirm project identity/settings and import pipeline; establish shared constants, signals, JSON/config/resource loading and deterministic/random utilities; document working conventions and developer workflow.

### B. Tile and board foundations

Build tile state/factory/database and board storage/generation/validation. Support configured board sizes and tile pools. Prevent initial matches or repair boards that have no legal move, according to chosen rules.

### C. Match and resolution engine

Implement swipe input, swap validation, match detection, destruction, gravity, spawning/refill, cascade resolution, and stable-board detection. Cover straight and supported special patterns. Add animations through the animation subsystem.

### D. Level playability

Load level definitions, moves/timers, objectives, win/fail states, restart/next-level flow, score and rating. Deliver a simple end-to-end playable level before adding broad content.

### E. Powerups and obstacles

Implement configured powerup creation, activation, combinations, obstacle health/interactions and readable feedback. Add mechanics incrementally and author introductory/tutorial levels alongside them.

### F. Story and campaign progression

Implement story content loading, dialogue, choices, branch conditions, scene transitions, chapter/map progression, and persistent choice state. Build the first campaign through the factory rescue and boss-style encounter.

### G. Product UI, economy, and local save

Deliver boot/menu/map/gameplay/pause/victory/failure/reward/settings/shop screens; coins, lives, boosters, reward rules, daily reward flows, achievements and local save/migration. Polish responsive controls and accessibility settings.

### H. Content and polish

Author and balance the opening ~50 levels and first chapter. Complete tutorials, audio, effects, animation, localization-ready text handling, performance, crash/regression, and device-size work. Expand art/audio coverage as defined by the asset backlog.

### I. Monetization and online services

Integrate and validate ad placements/reward flows behind service interfaces. Then add cloud saves, leaderboards, daily/event services, and operational handling for offline/failure states. Follow platform policies and protect player progress. These are planned systems with staged delivery, not prerequisites to beginning the core engine.

### J. Release and ongoing chapters

Prepare Android and Windows release candidates, store materials, privacy/consent and service configuration as applicable, support/telemetry decisions, and post-release update process. Continue with new chapters, level packs, seasonal events, and service-backed challenges using the same content pipeline.

## 11. Art and audio direction

The current `assets` collection contains character portraits, a logo/title treatment, puzzle/special/obstacle icons, map and terrain pieces, environment illustrations, and UI frames. Its canonical filenames are being assigned by in-game role. Several files are JPEGs with backgrounds flattened into the image, even where the thumbnail resembles transparency; they may need cleanup or PNG replacement before use as sprites. The assets are a useful starting library, not proof that all production art is complete.

The next art needs are a consistent set of ordinary matchable tiles, complete and readable state variants for mission objects/obstacles, story backgrounds for the opening and factory sequence, missing character expressions/poses, gameplay/map/menu screen elements, and matching animation/effect frames. Produce or commission these as their scenes and mechanics are implemented, using the current art style as reference. Do not duplicate an asset unless a distinct visual state or size is needed.

Audio needs include menu/game/story music, match and cascade feedback, powerup/obstacle sounds, dialogue/voice only if produced, and victory/failure/reward cues. Audio and volume settings are configurable and saved.

## 12. Version boundaries

Version 1.0 is the first complete public game: approximately 50 opening levels, the first rescue chapter, core puzzle systems, progression/rewards, local save, polished UI/audio/animation, and Android/Windows release readiness. Ads and online/live services remain planned product capabilities and enter production in their staged roadmap phases; their exact inclusion and service scope for the first store release are release decisions made after implementation and platform review.

After Version 1.0, continue the campaign and service features as ongoing updates. The game has no hardcoded final level count. The architecture should make continued growth practical while allowing each release to have a clear, achievable content scope.
