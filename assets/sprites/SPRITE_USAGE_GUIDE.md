# Sprite inventory and usage guide

This guide records the visual audit of the files under `assets/sprites/`. The contact sheets were inspected folder by folder on 2026-10-31. The inventory below lists every source image and SVG; `.import` cache files are not source art.

## Reference images and runtime assets

Reference art describes the intended look or composition. Do not display these entire sheets as a live HUD or menu. Build the screen from the individual runtime assets and real text/count controls.

| Reference | Use |
|---|---|
| `ui/gameplay_hud_atlas.jpeg` | Reference for move, score, star, coin, life, and booster proportions. It contains baked labels and numbers. |
| `ui/alternate_hud_panels_atlas.jpeg` | Reference for the alternate HUD palette and panel composition. |
| `ui/menu_states_atlas.jpeg` | Reference for pause, win, failure, and reward screen composition. |
| `ui/ui_button_states_atlas.jpeg`, `ui/navigation_button_states_atlas.jpeg`, `ui/candy_menu_buttons_atlas.jpeg` | Button-state references; use the extracted state PNGs in `ui/buttons/` and `ui/story_buttons/` for actual controls. |
| `ui/campaign_map_ui_reference.jpeg`, `ui/match3_board_mockup.jpeg`, `backgrounds/topdown_board_scene.jpeg` | Layout/style references, not finished live screens. |
| `ui/references/gameplay_hud_*_reference_atlas.png` | Moved out of `ui/icons/`: these are composite sheets, not single icons. |

Runtime artwork is in `backgrounds/`, `characters/`, `obstacles/`, `powerups/`, `props/`, `tiles/`, and the extracted UI folders. Transparent `*_cutout.png` files are intended for layering. White-matte JPEGs are source artwork and should not be layered directly over a scene when a matching cutout exists.

## Corrections made during the audit

- Moved the coin, life, and booster circles from `ui/panels/` into `ui/icons/` and named them `coins_icon.png`, `life_icon.png`, and `booster_icon.png`. They are individual icons, not panels.
- Moved the three composite PNG sheets previously named as icons into `ui/references/` and gave them `*_reference_atlas.png` names. They include sample panels/labels, so cropping them into live counters caused inconsistent sizing and text artifacts.
- The live coin display now uses the individual coin icon at a fixed 17 px and a separate numeric label. The live HUD uses the provided wooden dialogue frame at the top; it does not render an entire HUD atlas.
- The `Victor` tile was using `victor_portrait_frame_cutout.png`, whose artwork is an older police officer. It now uses `victor_portrait_badge_cutout.png`, which depicts Victor. The older officer portrait remains available as Detective/authority story art; the filename needs a future rename if it is retained for that role.
- `wooden_bridge.jpeg` and its cutout are a matching bridge asset. `wooden_fence.jpeg` and its cutout are a matching fence asset.

## Current feature gaps found in the project

- The pause, victory, failure, and rewards PNGs exist under `ui/screens/`, but the reusable `PauseMenu.gd`, `VictoryScreen.gd`, and `GameOverScreen.gd` are mostly stubs. Gameplay currently constructs pause/result screens inline in `Game.gd`; the supplied screen art is not wired into those screens.
- There is no dedicated shop screen. Purchases currently use confirmation dialogs and configured coin prices.
- There is no real-money store adapter and no rewarded-ad SDK/adapter. To add them, create platform product IDs in the store console, integrate Android/iOS billing behind a purchase service, and integrate an ad provider with opt-in rewarded placements. Hide ad offers when no ad is available; grant only after provider confirmation.
- The authored campaign currently ends at level 050. The endless progression document defines the generator contract, but there is no deterministic endless-level generator or virtual map-page loader yet.
- The obstacle API/config defines chain, lock, tape, bomb, missile, and electric trap behavior. Several files in `obstacles/` are icons or environmental illustrations rather than board-ready obstacle artwork; there is no clearly named tape artwork. Either draw board-ready art for the missing obstacle states or explicitly map an existing illustration to each configured obstacle before shipping those levels.
- The HUD currently tracks one primary evidence objective plus a blocker counter. The Levels API supports an objectives array; a generalized objective tracker is still needed for levels that require more than those two tracked goals.

These are implementation/service gaps, not requests for decorative assets. Existing references and extracted assets are sufficient for the current gameplay HUD, map props, and basic menus. New art is only needed for the missing board obstacle states or missing character poses after the screen wiring is complete.

## Full source inventory

### `backgrounds/`

- `backgrounds/dirt_board_background.jpeg`
- `backgrounds/dirt_terrain_texture.jpeg`
- `backgrounds/factory_cage_art.jpeg`
- `backgrounds/factory_map_section.jpeg`
- `backgrounds/factory_map_section_cutout.png`
- `backgrounds/garden_map_tile.jpeg`
- `backgrounds/garden_map_tile_cutout.png`
- `backgrounds/grass_board_background.jpeg`
- `backgrounds/grass_terrain_texture.jpeg`
- `backgrounds/iron_gate_map_tile.jpeg`
- `backgrounds/level_map_landscape.jpeg`
- `backgrounds/level_map_landscape_cutout.png`
- `backgrounds/river_map_section.jpeg`
- `backgrounds/river_map_section_cutout.png`
- `backgrounds/river_waterfall_map_tile.jpeg`
- `backgrounds/river_waterfall_map_tile_cutout.png`
- `backgrounds/riverbank_map_section.jpeg`
- `backgrounds/riverbank_map_section_cutout.png`
- `backgrounds/riverside_landscape.jpeg`
- `backgrounds/title_woodgrain_texture.jpeg`
- `backgrounds/topdown_board_scene.jpeg`

### `characters/`

- `characters/amara_and_ethan_portrait.jpeg`
- `characters/amara_and_ethan_portrait_cutout.png`
- `characters/amara_police_portrait.jpeg`
- `characters/amara_police_portrait_cutout.png`
- `characters/david_portrait.jpeg`
- `characters/david_portrait_cutout.png`
- `characters/detective_portrait.jpeg`
- `characters/detective_portrait_cutout.png`
- `characters/ethan_portrait.jpeg`
- `characters/ethan_portrait_cutout.png`
- `characters/victor_portrait_badge.jpeg`
- `characters/victor_portrait_badge_cutout.png`
- `characters/victor_portrait_dark.jpeg`
- `characters/victor_portrait_dark_cutout.png`
- `characters/victor_portrait_frame.jpeg`
- `characters/victor_portrait_frame_cutout.png`

### `obstacles/`

- `obstacles/barricaded_door.jpeg`
- `obstacles/chain_obstacle_icon.jpeg`
- `obstacles/electric_trap_obstacle_icon.jpeg`
- `obstacles/locked_padlock_obstacle_icon.jpeg`
- `obstacles/missile_obstacle_icon.jpeg`
- `obstacles/pincers_obstacle_icon.jpeg`
- `obstacles/pliers_obstacle_icon.jpeg`
- `obstacles/unlocked_padlock_icon.jpeg`
- `obstacles/wooden_gate_board_tile.jpeg`

### `powerups/`

- `powerups/bomb_powerup_icon.jpeg`
- `powerups/rocket_powerup_icon.jpeg`
- `powerups/thunder_powerup_icon.jpeg`

### `props/`

- `props/bicycle_prop.jpeg`
- `props/boulder_cluster.jpeg`
- `props/boulder_prop.jpeg`
- `props/bush_topdown_variant.jpeg`
- `props/bush_topdown_variant_cutout.png`
- `props/computer_terminal.jpeg`
- `props/evidence_briefcase.jpeg`
- `props/foliage_boulder_map_prop.jpeg`
- `props/hazard_warning_plate.jpeg`
- `props/industrial_pipe_prop.jpeg`
- `props/mailbox_prop.jpeg`
- `props/park_bench.jpeg`
- `props/police_car_topdown.jpeg`
- `props/police_car_topdown_cutout.png`
- `props/small_rock_prop.jpeg`
- `props/striped_road_barrier.jpeg`
- `props/target_marker.jpeg`
- `props/tree_bush_topdown.jpeg`
- `props/tree_bush_topdown_cutout.png`
- `props/wooden_bridge.jpeg`
- `props/wooden_bridge_cutout.png`
- `props/wooden_fence.jpeg`
- `props/wooden_fence_cutout.png`
- `props/wooden_signpost.jpeg`
- `props/wooden_signpost_cutout.png`

### `tiles/`

- `tiles/evidence_document_icon.jpeg`
- `tiles/fingerprint_evidence_icon.jpeg`
- `tiles/key_objective_icon.jpeg`
- `tiles/phone_evidence_icon.svg`
- `tiles/recorder_evidence_icon.jpeg`
- `tiles/timer_objective_icon.jpeg`

### `ui/`

- `ui/achievement_badge_frame.jpeg`
- `ui/alternate_hud_panels_atlas.jpeg`
- `ui/campaign_map_ui_reference.jpeg`
- `ui/candy_menu_buttons_atlas.jpeg`
- `ui/game_logo.jpeg`
- `ui/game_logo_cutout.png`
- `ui/gameplay_hud_atlas.jpeg`
- `ui/level_badge.jpeg`
- `ui/level_node_empty.jpeg`
- `ui/level_node_empty_cutout.png`
- `ui/level_node_star_frame.jpeg`
- `ui/level_node_stars.jpeg`
- `ui/level_select_art.jpeg`
- `ui/locked_level_badge.jpeg`
- `ui/locked_level_badge_cutout.png`
- `ui/match3_board_mockup.jpeg`
- `ui/menu_states_atlas.jpeg`
- `ui/navigation_button_states_atlas.jpeg`
- `ui/title_art_family.jpeg`
- `ui/ui_button_states_atlas.jpeg`
- `ui/wooden_dialogue_panel.jpeg`
- `ui/wooden_dialogue_panel_cutout.png`

### `ui/android/`

- `ui/android/app_icon_background_432.png`
- `ui/android/app_icon_foreground_432.png`
- `ui/android/app_icon_main_192.png`

### `ui/buttons/`

- `ui/buttons/back_disabled.png`
- `ui/buttons/back_hover.png`
- `ui/buttons/back_normal.png`
- `ui/buttons/back_pressed.png`
- `ui/buttons/pause_disabled.png`
- `ui/buttons/pause_hover.png`
- `ui/buttons/pause_normal.png`
- `ui/buttons/pause_pressed.png`
- `ui/buttons/play_disabled.png`
- `ui/buttons/play_hover.png`
- `ui/buttons/play_normal.png`
- `ui/buttons/play_pressed.png`
- `ui/buttons/settings_disabled.png`
- `ui/buttons/settings_hover.png`
- `ui/buttons/settings_normal.png`
- `ui/buttons/settings_pressed.png`

### `ui/icons/`

- `ui/icons/booster_icon.png`
- `ui/icons/coins_icon.png`
- `ui/icons/gear_icon.svg`
- `ui/icons/life_icon.png`

### `ui/panels/`

- `ui/panels/moves_panel.png`
- `ui/panels/score_panel.png`
- `ui/panels/star_goal_panel.png`

### `ui/panels/printed/`

- `ui/panels/printed/moves_labeled_panel.png`
- `ui/panels/printed/score_labeled_panel.png`
- `ui/panels/printed/star_goal_labeled_panel.png`

### `ui/references/`

- `ui/references/gameplay_hud_booster_reference_atlas.png`
- `ui/references/gameplay_hud_coin_reference_atlas.png`
- `ui/references/gameplay_hud_life_reference_atlas.png`

### `ui/screens/`

- `ui/screens/failure_screen.png`
- `ui/screens/pause_screen.png`
- `ui/screens/rewards_screen.png`
- `ui/screens/victory_screen.png`

### `ui/story_buttons/`

- `ui/story_buttons/continue_disabled.png`
- `ui/story_buttons/continue_hover.png`
- `ui/story_buttons/continue_normal.png`
- `ui/story_buttons/continue_pressed.png`
- `ui/story_buttons/next_hover.png`
- `ui/story_buttons/next_normal.png`
- `ui/story_buttons/next_pressed.png`
- `ui/story_buttons/play_hover.png`
- `ui/story_buttons/play_normal.png`
- `ui/story_buttons/play_pressed.png`
- `ui/story_buttons/previous_disabled.png`
- `ui/story_buttons/previous_hover.png`
- `ui/story_buttons/previous_normal.png`
- `ui/story_buttons/previous_pressed.png`
- `ui/story_buttons/save_hover.png`
- `ui/story_buttons/save_normal.png`
- `ui/story_buttons/save_pressed.png`
- `ui/story_buttons/skip_disabled.png`
- `ui/story_buttons/skip_hover.png`
- `ui/story_buttons/skip_normal.png`
- `ui/story_buttons/skip_pressed.png`

### `ui/story_choices/`

- `ui/story_choices/call_police.png`
- `ui/story_choices/go_alone.png`
- `ui/story_choices/trace_signal.png`

