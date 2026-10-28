# Asset catalog

Canonical names for the image files currently in `assets/`. Names describe their intended game role. Many of the files are JPEGs, so apparent transparency/checkerboard backgrounds are flattened and may need cleanup before sprite use. The existing collection is a starter library; required additions are listed in `GAME_PLAN.md`.

## API compatibility

The utilities API does not prescribe image basenames. `Constants.ResourcePaths` defines these resource directories, and the current folders match them:

- `sprites/tiles/`
- `sprites/ui/`
- `sprites/powerups/`
- `sprites/obstacles/`
- `audio/music/` and `audio/sfx/` (reserved for audio assets; none are present yet)

Managers and databases obtain asset paths from configuration and pass those paths to `ResourceManager`; `ResourceManager` loads/caches the resource and does not infer filenames. Story art, characters, map backgrounds, and props have no dedicated path constants and should likewise be referenced by their explicit paths in configuration/story data. The current tile, powerup, and obstacle configs reference their textures and icons below through `.tres` texture resources. Story art, audio, UI themes, and fonts still need their own content data as those systems enter implementation.

| File | Intended use |
|---|---|
| `sprites/ui/achievement_badge_frame.jpeg` | Achievement or reward badge artwork |
| `sprites/characters/amara_and_ethan_portrait.jpeg` | Amara and Ethan story portrait |
| `sprites/characters/amara_police_portrait.jpeg` | Amara character portrait in police uniform |
| `sprites/obstacles/barricaded_door.jpeg` | Blocked door/environment prop |
| `sprites/props/bicycle_prop.jpeg` | Map/environment prop |
| `sprites/powerups/bomb_powerup_icon.jpeg` | Bomb special-piece icon |
| `sprites/props/boulder_cluster.jpeg` | Map/environment rock cluster |
| `sprites/props/boulder_prop.jpeg` | Individual rock prop |
| `sprites/props/bush_topdown_variant.jpeg` | Top-down map foliage variant |
| `sprites/ui/campaign_map_ui_reference.jpeg` | Campaign-map layout/reference image |
| `sprites/obstacles/chain_obstacle_icon.jpeg` | Chain obstacle icon |
| `sprites/props/computer_terminal.jpeg` | Investigation/story prop |
| `sprites/characters/david_portrait.jpeg` | David character portrait |
| `sprites/characters/detective_portrait.jpeg` | Detective character portrait |
| `sprites/backgrounds/dirt_board_background.jpeg` | Dirt board/terrain background |
| `sprites/backgrounds/dirt_terrain_texture.jpeg` | Dirt terrain texture |
| `sprites/obstacles/electric_trap_obstacle_icon.jpeg` | Electric trap obstacle icon |
| `sprites/characters/ethan_portrait.jpeg` | Ethan character portrait |
| `sprites/props/evidence_briefcase.jpeg` | Evidence case story/objective prop |
| `sprites/tiles/evidence_document_icon.jpeg` | Evidence document objective icon |
| `sprites/backgrounds/factory_cage_art.jpeg` | Factory cage/rescue story art |
| `sprites/backgrounds/factory_map_section.jpeg` | Factory map/location section |
| `sprites/props/foliage_boulder_map_prop.jpeg` | Foliage-covered boulder map prop |
| `sprites/ui/game_logo.jpeg` | Save The Baby logo |
| `sprites/ui/ui_button_states_atlas.jpeg` | Play, pause, settings, and back button states source atlas |
| `sprites/ui/gameplay_hud_atlas.jpeg` | Moves, score, star goal, coin, life, and booster HUD source atlas |
| `sprites/ui/menu_states_atlas.jpeg` | Pause, win, fail, and reward screen source atlas |
| `sprites/ui/alternate_hud_panels_atlas.jpeg` | Alternate moves, score, and star meter panel source atlas |
| `sprites/ui/navigation_button_states_atlas.jpeg` | Navigation and story button source atlas added 2026-10-28 |
| `sprites/ui/buttons/` | Transparent Play, Pause, Settings, and Back button sprites, each with normal, hover, and pressed states. Play and Pause are used by the launch and gameplay screens. |
| `sprites/ui/story_buttons/` | Transparent Play, Save, Next, Previous, Continue, and Skip states extracted from the added navigation atlas. Continue, Next, Previous, and Skip are used in the opening story flow; Save awaits integration with persistent progress. The combined Settings/Back art was excluded; the separate Settings and Back buttons from `buttons/` are used in the pause menu. |
| `sprites/ui/story_choices/` | Three transparent choice buttons cropped from the supplied story UI reference and used for Call the police, Trace Victor’s signal, and Go after Victor alone. |
| `sprites/ui/panels/` | Transparent moves, score, star goal, coins, life, and booster panels/icons extracted from the HUD sheet. Moves and score panels are used for live gameplay counters. |
| `sprites/ui/screens/` | Transparent pause, victory, failure, and rewards panels extracted from the menu sheet. The pause panel is used by the in-game pause menu. |
| `sprites/backgrounds/garden_map_tile.jpeg` | Garden map/environment tile |
| `sprites/backgrounds/grass_board_background.jpeg` | Grass board/terrain background |
| `sprites/backgrounds/grass_terrain_texture.jpeg` | Grass terrain texture |
| `sprites/props/hazard_warning_plate.jpeg` | Fire/hazard warning environment detail |
| `sprites/props/industrial_pipe_prop.jpeg` | Factory pipe/environment prop |
| `sprites/backgrounds/iron_gate_map_tile.jpeg` | Iron gate map/environment tile |
| `sprites/tiles/key_objective_icon.jpeg` | Key objective icon |
| `sprites/tiles/phone_evidence_icon.svg` | Phone evidence match tile icon |
| `sprites/tiles/fingerprint_evidence_icon.jpeg` | Fingerprint evidence match tile icon (new raster source replacing the temporary SVG) |
| `sprites/ui/level_badge.jpeg` | Level marker/badge |
| `sprites/backgrounds/level_map_landscape.jpeg` | Campaign map landscape background |
| `sprites/ui/level_node_empty.jpeg` | Empty level node |
| `sprites/ui/level_node_star_frame.jpeg` | Level node with star frame |
| `sprites/ui/level_node_stars.jpeg` | Level completion/star node |
| `sprites/ui/level_select_art.jpeg` | Level select/map artwork |
| `sprites/ui/locked_level_badge.jpeg` | Locked level marker |
| `sprites/obstacles/locked_padlock_obstacle_icon.jpeg` | Locked padlock obstacle icon |
| `sprites/props/mailbox_prop.jpeg` | Map/environment prop |
| `sprites/ui/match3_board_mockup.jpeg` | Match-3 board visual reference |
| `sprites/obstacles/missile_obstacle_icon.jpeg` | Missile hazard/objective icon |
| `sprites/props/park_bench.jpeg` | Map/environment prop |
| `sprites/obstacles/pincers_obstacle_icon.jpeg` | Pincers obstacle icon |
| `sprites/obstacles/pliers_obstacle_icon.jpeg` | Pliers obstacle icon |
| `sprites/props/police_car_topdown.jpeg` | Police vehicle map prop |
| `sprites/tiles/recorder_evidence_icon.jpeg` | Recorder evidence icon |
| `sprites/backgrounds/river_map_section.jpeg` | River campaign-map section |
| `sprites/backgrounds/river_waterfall_map_tile.jpeg` | Waterfall map/environment tile |
| `sprites/backgrounds/riverbank_map_section.jpeg` | Riverbank campaign-map section |
| `sprites/backgrounds/riverside_landscape.jpeg` | Riverside environment illustration |
| `sprites/powerups/rocket_powerup_icon.jpeg` | Rocket special-piece icon |
| `sprites/props/small_rock_prop.jpeg` | Small map/environment rock prop |
| `sprites/props/striped_road_barrier.jpeg` | Road/worksite barrier prop |
| `sprites/props/target_marker.jpeg` | Target/mission marker |
| `sprites/powerups/thunder_powerup_icon.jpeg` | Thunder special-piece icon |
| `sprites/tiles/timer_objective_icon.jpeg` | Timer objective icon |
| `sprites/ui/title_art_family.jpeg` | Title/splash illustration with family |
| `sprites/backgrounds/topdown_board_scene.jpeg` | Top-down board/environment scene reference |
| `sprites/props/tree_bush_topdown.jpeg` | Top-down foliage prop |
| `sprites/obstacles/unlocked_padlock_icon.jpeg` | Unlocked padlock state icon |
| `sprites/characters/victor_portrait_badge.jpeg` | Victor portrait badge |
| `sprites/characters/victor_portrait_dark.jpeg` | Dark Victor story portrait |
| `sprites/characters/victor_portrait_frame.jpeg` | Victor portrait in framed UI treatment |
| `sprites/props/wooden_bridge.jpeg` | Map/environment bridge prop |
| `sprites/ui/wooden_dialogue_panel.jpeg` | Dialogue/story panel frame |
| `sprites/props/wooden_fence.jpeg` | Map/environment fence prop |
| `sprites/obstacles/wooden_gate_board_tile.jpeg` | Gate board/environment tile |
| `sprites/props/wooden_signpost.jpeg` | Campaign map signpost |

## Art still needed for the first playable game

- A coordinated set of ordinary matchable tile symbols, in a transparent sprite format and consistent scale.
- Clean production versions of any mission or obstacle icon that currently has a flattened background, plus visual state/damage variants where needed.
- Opening, police-station, signal-tracing, factory, and rescue story backgrounds; character expressions/poses for David, Amara, Ethan, Victor, the detective, and the technical specialist.
- UI art for gameplay HUD, menus, shop/reward panels, buttons, boosters, lives/coins, and responsive campaign map states.
- Animation frames or reusable effects for swaps, matches, cascades, powerups, obstacles, story transitions, victory, and failure.
- Audio assets for music, UI, matches, special effects, story, victory, and failure.

Create these in the corresponding implementation phase, matching the established visual direction. Do not treat the reference/mockup images in this catalog as final production UI without reviewing their quality and licenses.


