# Obstacle configuration schema

`configs/obstacles.json` defines static obstacle metadata. The root object contains an `obstacles` dictionary keyed by stable lowercase IDs. Each entry requires `id`, `enum`, `name`, `texture`, `animation_set`, `health`, `destroy_score`, `blocks_gravity`, `blocks_matching`, `removable`, `hidden`, and `description`.

- `enum` is the numeric `Constants.ObstacleType` value and must be unique.
- `texture` is a `res://` path to a `Texture2D` resource under `resources/obstacles/`.
- `animation_set` contains metadata only; the animation subsystem owns playback.
- `health` and `destroy_score` are non-negative integers.
- The blocking, removable, and hidden flags are booleans.

The current config uses only the six obstacle types declared by `Constants.ObstacleType`: chain, lock, tape, bomb, missile, and electric trap. Pliers and pinchers remain source art only because they are not currently declared obstacle enum types.
