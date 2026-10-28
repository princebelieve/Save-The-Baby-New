# Powerup configuration schema

`configs/powerups.json` defines static metadata for each powerup. Powerup behavior remains in the powerup subsystem; this file does not contain executable behavior.

The root object contains a `powerups` dictionary keyed by stable lowercase IDs. Each entry requires `id`, `enum`, `name`, `texture`, `icon`, `animation_set`, `activation_type`, `combination_rules`, `description`, `created_by_match`, `created_by_booster`, and `combinable`.

- `enum` is the numeric `Constants.PowerupType` value and must be unique.
- `texture` is a `res://` path to a `Texture2D` resource under `resources/powerups/`.
- `icon` is a `res://` path to its raw UI icon.
- `animation_set` is metadata only; the animation subsystem owns playback.
- `activation_type` and `combination_rules` are identifiers/data consumed by future board-level powerup resolution.
- Creation flags and `combinable` are booleans.

The current data registers only Rocket, Bomb, and Thunder because those are the powerup types in `Constants.PowerupType` and the implemented behavior registry. New types require an enum entry, behavior, asset resource, and config entry together.
