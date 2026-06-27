scripts/board/
Board System API Map (Version 1.0 Freeze)
Purpose

The Board System owns every board mechanic.

It performs board operations only.

It never coordinates gameplay progression.

Gameplay coordination belongs to BoardManager.

Animation scheduling belongs to AnimationManager.

The reusable animation framework belongs to scripts/animation/.

Tile-specific animations belong to TileAnimator.

Board-wide animations belong to BoardAnimator.

Configuration comes from ConfigLoader.

Resources come from ResourceManager.

Communication occurs through SignalBus.

The Board System therefore acts as the gameplay engine underneath BoardManager.

Folder Structure
scripts/
└── board/
    ├── Board.gd
    ├── BoardGenerator.gd
    ├── MoveValidator.gd
    ├── MatchFinder.gd
    ├── Match.gd
    ├── GravitySolver.gd
    ├── RefillSystem.gd
    ├── CascadeProcessor.gd
    ├── BoardShuffler.gd
    └── BoardAnimator.gd
1. Board.gd
Purpose

Represents one match-3 board.

Owns the tile grid.

Coordinates the specialized board classes.

Contains board mechanics only.

Requests board animations through AnimationManager.

Never performs animation implementation.

Never performs level progression.

Never performs rewards.

Never performs story progression.

Never performs economy.

Never performs saves.

Public API
Initialization
initialize(level_data)

reset()

clear()
Board Information
get_width() -> int

get_height() -> int

get_size() -> Vector2i

is_inside(position) -> bool
Tiles
set_tile(position, tile)

get_tile(position)

remove_tile(position)

has_tile(position)

swap_tiles(position_a, position_b)
Grid
get_all_tiles()

get_row(index)

get_column(index)

get_neighbors(position)
Gameplay
lock()

unlock()

is_locked()

is_stable()

update()
Internal
_grid

_locked

_level_data

_board_generator

_move_validator

_match_finder

_gravity_solver

_refill_system

_cascade_processor

_board_shuffler
2. BoardGenerator.gd
Purpose

Creates the initial playable board.

Never performs gameplay after creation.

Public API
Initialization
initialize()
Generation
generate(level_data)

generate_empty(width,height)

fill_board(board)

generate_tile(position)
Validation
remove_initial_matches(board)

ensure_valid_moves(board)

has_initial_matches(board)

has_valid_moves(board)
Internal
_create_tile()

_fill_position()

_validate_board()
3. MoveValidator.gd
Purpose

Determines whether a swipe is legal.

Never swaps tiles.

Never modifies the board.

Public API
initialize()

is_valid_swipe(tile_a,tile_b)

is_adjacent(tile_a,tile_b)

would_create_match(board,tile_a,tile_b)

can_swap(tile_a,tile_b)
Internal
_check_direction()

_simulate_swap()
4. MatchFinder.gd
Purpose

Detects matches.

Never destroys tiles.

Never awards score.

Never updates objectives.

Public API
initialize()

find_matches(board)

find_match_from_tile(board,tile)

find_horizontal_matches(board)

find_vertical_matches(board)

find_all_matches(board)

has_matches(board)
Internal
_scan_rows()

_scan_columns()

_collect_match()
5. Match.gd
Purpose

Represents one detected match.

Contains data only.

Public API
initialize()

add_tile(tile)

remove_tile(tile)

get_tiles()

size()

contains(tile)

get_center_tile()

get_pattern()

is_valid()
Internal
_tiles

_pattern
6. GravitySolver.gd
Purpose

Calculates tile movement after removals.

Never creates tiles.

Never animates movement.

Public API
initialize()

apply_gravity(board)

calculate_fall(board)

get_fall_path(tile)

has_floating_tiles(board)
Internal
_find_empty_spaces()

_move_tiles()
7. RefillSystem.gd
Purpose

Creates replacement tiles after gravity.

Uses TileFactory.

Never decides gameplay flow.

Public API
initialize()

refill(board)

spawn_tile(position)

spawn_column(column)

needs_refill(board)
Internal
_create_tile()

_place_tile()
8. CascadeProcessor.gd
Purpose

Processes cascades until the board becomes stable.

Never updates score.

Never updates objectives.

Never grants rewards.

Public API
initialize()

process(board)

has_cascade(board)

is_processing()

stop()
Internal
_process_cycle()
9. BoardShuffler.gd
Purpose

Restores a playable board when no legal moves remain.

Preserves board dimensions.

Public API
initialize()

shuffle(board)

needs_shuffle(board)

validate_shuffle(board)
Internal
_randomize()

_validate()
10. BoardAnimator.gd
Purpose

Owns every animation affecting the board as a whole.

Never animates individual tiles.

Tile animations belong to TileAnimator.

AnimationManager decides when board animations run.

BoardAnimator implements how board animations are performed.

Uses the reusable animation framework from scripts/animation/.

Contains no gameplay logic.

Contains no board mechanics.

Public API
Initialization
initialize()
Lifecycle
play_enter(board)

play_exit(board)

play_transition(board)

play_ready(board)
Gameplay
play_shuffle(board)

play_invalid_move(board)

play_hint(board)

play_complete(board)

play_fail(board)
Camera / Board Motion
play_shake(board)

play_bounce(board)

play_zoom_in(board)

play_zoom_out(board)

play_focus(board)

play_pan(board)
Visibility
play_show(board)

play_hide(board)

play_fade_in(board)

play_fade_out(board)
State
play_lock(board)

play_unlock(board)
Utility
stop(board)

stop_all()

pause(board)

resume(board)

is_playing(board) -> bool

wait_until_finished(board)
Internal
_execute(request)

_complete(request)
Frozen Board System Dependencies
                    BoardManager
                         │
                         ▼
                       Board
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 BoardGenerator  MoveValidator  MatchFinder
        │              │              │
        ▼              ▼              ▼
 GravitySolver   RefillSystem      Match
        │
        ▼
 CascadeProcessor
        │
        ▼
 BoardShuffler

AnimationManager
        │
        ▼
 BoardAnimator

TileFactory
        │
        ▼
 Tile → TileState → TileAnimator

ConfigLoader
ResourceManager
SignalBus
Version 1 Rules
The Board System owns board mechanics only.
BoardManager coordinates gameplay and invokes the Board System.
Board.gd coordinates board components but does not manage gameplay progression.
BoardGenerator creates only the initial playable board.
MoveValidator validates moves without modifying the board.
MatchFinder detects matches only.
Match is a data object only.
GravitySolver applies gravity but never creates new tiles.
RefillSystem creates replacement tiles using TileFactory.
CascadeProcessor repeats board mechanics until the board is stable.
BoardShuffler restores playability when no legal moves remain.
BoardAnimator owns only board-wide animations.
AnimationManager decides when animations execute.
The scripts/animation/ folder provides the reusable animation infrastructure (requests, queues, sequences, tween helpers, animation library).
BoardAnimator uses that infrastructure to implement board animations and never creates its own animation framework.
The Board System may depend on Constants, SignalBus, RandomGenerator, ConfigLoader, ResourceManager, the Tile System, and the reusable animation framework.
The Board System must not depend directly on gameplay managers other than being orchestrated by BoardManager.