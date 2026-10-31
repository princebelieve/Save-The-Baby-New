# Asset catalog

See [Sprite Inventory and Usage Guide](sprites/SPRITE_USAGE_GUIDE.md) for the folder-by-folder source inventory, reference-vs-runtime classification, corrected icon placement, and known art/integration gaps.

All gameplay data must refer to assets by explicit path through the relevant Config, Tile, Obstacle, Powerup, Story, or UI contract. Do not infer an asset path from its display name. Atlas/reference images are not runtime widgets; use extracted individual assets with live text and counters.

## Gameplay HUD assets

The generated PNGs in the `assets/` root are source artwork. Their filenames are not always reliable descriptions of the visible art, so the runtime uses tightly cropped, resized copies under `sprites/ui/hud/`:

| Runtime asset | Source art | Use |
|---|---|---|
| `sprites/ui/hud/moves_counter.png` | `moves_no29.png` | Moves pill with a live count over its blank slot. |
| `sprites/ui/hud/coin_counter.png` | `lives_template.png` | Gold COINS pill with a live balance. |
| `sprites/ui/hud/lives_counter.png` | `objective_template.png` | Pink LIVES pill with a live count. |
| `sprites/ui/hud/objective_title.png` | `objective_pill.png` | Objective title above the live target and progress. |
| `sprites/ui/hud/pause_button.png` | `pause_btn.png` | Gameplay pause control. |

Keep the source images intact. Runtime copies are cropped to their visible alpha bounds and sized for their HUD controls; do not place the uncropped source canvases directly in the gameplay scene.
