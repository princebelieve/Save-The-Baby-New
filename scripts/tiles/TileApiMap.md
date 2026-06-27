scripts/tiles/
Tile System API Map (Version 1.0 Freeze)

The Tile System defines everything about an individual tile.

It is responsible only for tile data, tile visuals, tile creation, tile animation, and tile metadata.

It never performs gameplay coordination.

Gameplay flow belongs to BoardManager.

Animation scheduling belongs to AnimationManager.

Tile creation requests come from BoardManager.

Configuration comes from ConfigLoader.

Resources come from ResourceManager.

Communication occurs through SignalBus.

This folder is therefore fully aligned with the Manager API and Utilities API.

1. TileState.gd
Purpose

Stores every piece of gameplay state belonging to one tile.

Contains no visual logic.

Contains no animation logic.

Contains no board logic.

Public API
Initialization

initialize(tile_type, grid_position)

reset()

duplicate_state() -> TileState

Identity

set_tile_type(type)

get_tile_type() -> Constants.TileType

Grid

set_position(position)

get_position() -> Vector2i

State

set_state(state)

get_state() -> Constants.TileState

is_state(state) -> bool

Powerup

set_powerup(type)

get_powerup() -> Constants.PowerupType

has_powerup() -> bool

clear_powerup()

Obstacle

set_obstacle(type)

get_obstacle() -> Constants.ObstacleType

has_obstacle() -> bool

clear_obstacle()

Health

set_health(value)

get_health() -> int

damage(amount)

heal(amount)

is_destroyed() -> bool

Flags

set_selected(value)

is_selected() -> bool

set_matched(value)

is_matched() -> bool

set_falling(value)

is_falling() -> bool

set_locked(value)

is_locked() -> bool

set_hidden(value)

is_hidden() -> bool

reset_flags()

Internal

_tile_type

_grid_position

_state

_powerup

_obstacle

_health

_selected

_matched

_falling

_locked

_hidden

2. Tile.gd
Purpose

Represents one tile node inside the scene tree.

Responsible only for:

visual representation
input forwarding
holding a TileState
requesting animations
exposing tile information

Never performs gameplay decisions.

Never performs matching.

Never performs gravity.

Never performs objectives.

Never performs scoring.

Signals

pressed(tile)

released(tile)

clicked(tile)

hover_entered(tile)

hover_exited(tile)

Public API
Initialization

initialize(tile_type, grid_position)

reset()

Tile State

get_tile_state() -> TileState

set_tile_state(state)

duplicate_tile_state() -> TileState

Grid

set_grid_position(position)

get_grid_position() -> Vector2i

move_to_grid(position)

Tile Type

set_tile_type(type)

get_tile_type() -> Constants.TileType

State

set_state(state)

get_state()

is_idle()

Selection

select()

deselect()

is_selected()

Match

mark_matched()

clear_match()

is_matched()

Falling

begin_fall()

end_fall()

is_falling()

Lock

lock()

unlock()

is_locked()

Powerups

set_powerup(type)

get_powerup()

has_powerup()

clear_powerup()

Obstacles

set_obstacle(type)

get_obstacle()

has_obstacle()

clear_obstacle()

Health

damage(amount)

heal(amount)

is_destroyed()

Visual

set_texture(texture)

get_texture()

set_modulate(color)

reset_modulate()

show()

hide()

set_visible(value)

Animation

request_animation(name)

is_animation_playing() -> bool

Input

enable_input()

disable_input()

is_input_enabled() -> bool

Internal

_state

_sprite

_animation_player

_input_enabled

3. TileDatabase.gd
Purpose

Loads every tile definition from

configs/tiles.json

Provides lookup services only.

Contains no gameplay logic.

Public API
Initialization

initialize()

reload()

clear()

Lookup

get_tile(id)

has_tile(id)

get_tile_by_enum(type)

get_tile_name(type)

get_tile_texture_path(type)

get_tile_icon_path(type)

get_tile_animation_set(type)

get_tile_score(type)

Collections

get_all_tiles()

get_matchable_tiles()

get_spawnable_tiles()

get_special_tiles()

get_hidden_tiles()

Random

get_random_spawnable_tile()

Validation

is_matchable(type)

is_spawnable(type)

is_special(type)

is_hidden(type)

Internal

_tile_cache

4. TileFactory.gd
Purpose

Creates and destroys Tile nodes.

Never decides gameplay.

Never decides tile placement.

Never performs spawning logic.

Those belong to BoardManager.

Public API
Initialization

initialize()

Creation

create_tile(tile_type)

create_tile_at(tile_type, grid_position)

create_random_tile()

create_random_tile_at(position)

Copy

duplicate_tile(tile)

Lifecycle

destroy_tile(tile)

recycle_tile(tile)

reset_tile(tile)

Internal

_apply_database_data(tile)

_assign_texture(tile)

_assign_animation_set(tile)

_assign_metadata(tile)

5. TileAnimator.gd
Purpose

Owns every animation that affects an individual tile.

AnimationManager decides when animations occur.

TileAnimator performs how tile animations are played.

Public API
Initialization

initialize()

Basic

play_idle(tile)

play_spawn(tile)

play_destroy(tile)

play_fall(tile)

play_swap(tile_a, tile_b)

play_move(tile, position)

play_bounce(tile)

play_shake(tile)

play_highlight(tile)

Selection

play_select(tile)

play_deselect(tile)

Powerups

play_powerup_create(tile)

play_powerup_activate(tile)

play_powerup_combo(tile)

Obstacles

play_obstacle_damage(tile)

play_obstacle_break(tile)

Utility

stop(tile)

stop_all()

pause(tile)

resume(tile)

is_playing(tile) -> bool

wait_until_finished(tile)

Internal

_create_tween()

_finish_animation()

Frozen Tile System Dependency
                BoardManager
                      │
                      ▼
                TileFactory
                      │
                      ▼
                    Tile
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
       TileState          TileAnimator
            │
            ▼
       TileDatabase
            │
            ▼
 ConfigLoader / ResourceManager
Version 1 Rules
The Tile System represents individual tiles only.
BoardManager is the only manager that coordinates tile gameplay.
AnimationManager decides when tile animations should run.
TileAnimator only performs tile animations.
TileFactory only creates, duplicates, resets, recycles, and destroys tile nodes.
TileDatabase is the only source of tile metadata loaded from configs/tiles.json.
TileState stores gameplay data for one tile only.
Tile.gd is responsible only for the visual node, forwarding input/events, and requesting animation playback through TileAnimator.
The Tile System never performs board generation, matching, gravity, cascades, objectives, scoring, rewards, or economy.
The Tile System may depend on Constants, SignalBus, ConfigLoader, ResourceManager, and RandomGenerator from scripts/utilities/.
The Tile System must not depend on any gameplay manager except through requests made by BoardManager or notifications through SignalBus.

This API is aligned with the frozen scripts/utilities/ API and the frozen scripts/managers/ API, so subsequent folders (board, powerups, obstacles, animation, UI, economy, story, save, etc.) can be built without requiring changes to the Tile System.