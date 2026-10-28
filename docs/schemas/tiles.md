# Tile configuration schema

This schema is the first content contract frozen for implementation because `TileDatabase` and `TileFactory` already consume it. It defines tile metadata only; visuals live in `resources/tiles/` and raw icon art lives in `assets/`.

## File and shape

`configs/tiles.json` is a UTF-8 JSON object with one required `tiles` array. Each item is a tile definition:

| Field | Type | Rule |
|---|---|---|
| `id` | string | Stable unique content key, lowercase snake case. |
| `enum` | integer | Value from `Constants.TileType`; must be unique. |
| `name` | string | Player-facing display name. |
| `texture` | string | `res://` path to a `Texture2D` resource, loaded through `ResourceManager`. |
| `icon` | string | `res://` path to a UI `Texture2D`. |
| `animation_set` | string | Animation set identifier; `default` until tile animation data is authored. |
| `score` | integer | Non-negative base score. |
| `spawn_weight` | number | Non-negative relative spawn weight. |
| `matchable` | boolean | Whether the tile may form ordinary matches. |
| `spawnable` | boolean | Whether random generation may create it. |
| `hidden` | boolean | Whether the tile begins hidden. |
| `special` | boolean | Whether the tile is a special tile. |

All fields are required. A tile with `spawnable: true` must also be `matchable: true` for the opening tile set. Obstacles and powerups are defined by their own systems and must not be duplicated as ordinary spawnable tiles.

## Resource rule

Each `texture` points to a Godot texture resource under `resources/tiles/`. These `.tres` files are `AtlasTexture` wrappers around the raw image and expose a `Texture2D` to `TileFactory`. The `icon` points to the source icon image used where a small UI representation is needed. Resource paths are explicit; neither database infers a filename from `id`.

## Current initial tile set

The initial spawn pool contains key, phone, fingerprint, recorder, and clock pieces. Their enum values are taken from `Constants.TileType`. Levels can select a subset and provide objective targets independently of this global metadata.

## Consumer contract

`TileDatabase` reads the array, indexes entries by `id`, and finds entries by `enum`. `TileFactory` gets `texture` from the matching entry and loads that exact path through `ResourceManager`. Do not rename an ID, enum mapping, or resource path without updating this data and its consumers together.
