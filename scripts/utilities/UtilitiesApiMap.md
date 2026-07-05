scripts/utilities/
Utilities System API Map (Version 1.0 Freeze)

The Utilities folder provides reusable services for the entire project.

No utility may initialize another utility internally.

Utilities contain no gameplay logic.

Utilities never coordinate gameplay.

Utilities never replace managers.

Every subsystem may depend on utilities.

Utilities depend on no gameplay subsystem.

1. SignalBus.gd
Purpose

Central event hub.

Managers communicate through SignalBus instead of directly referencing one another whenever practical.

Public Signals
Game

game_started

game_paused

game_resumed

game_restarted

game_quit

game_state_changed(previous,current)

Level

level_loading(level_id)

level_loaded(level_data)

level_started(level_id)

level_completed(level_id)

level_failed(level_id)

next_level_requested

Board

board_creating(level_data)

board_created

board_ready

board_locked

board_unlocked

board_shuffled

board_stable

board_cleared

Input

swipe_started(tile)

swipe_completed(from_tile,to_tile)

swipe_cancelled(tile)

Tile

tile_swapped(tile_a,tile_b)

tile_swap_rejected(tile_a,tile_b)

tile_spawned(tile)

tile_falling(tile)

tile_landed(tile)

tile_destroyed(tile)

Match

match_found(match)

matches_found(matches)

cascade_started

cascade_finished

gravity_started

gravity_finished

refill_started

refill_finished

Powerups

powerup_created(powerup)

powerup_activated(powerup)

powerup_combined(first,second)

powerup_finished(powerup)

Obstacles

obstacle_damaged(obstacle)

obstacle_destroyed(obstacle)

Objectives

objective_progress(type,amount)

objective_completed(type)

objective_failed(type)

all_objectives_completed

Score

score_added(points)

score_changed(score)

Moves

move_used(moves)

moves_changed(moves)

Economy

coins_changed(coins)

stars_changed(stars)

lives_changed(lives)

boosters_changed(boosters)

life_restored

unlimited_lives_started

unlimited_lives_finished

Story

story_started(id)

story_choice_presented(choices)

choice_selected(choice)

dialogue_started(id)

dialogue_finished(id)

story_finished(id)

Rewards

reward_granted(data)

reward_collected(data)

daily_reward_claimed

chest_opened(id)

Save

save_requested

save_completed

save_failed

load_requested

load_completed(data)

load_failed

Audio

play_music(track)

stop_music

music_changed(track)

music_finished

play_sfx(sound)

Animation

animation_started(name)

animation_finished(name)

UI

hud_updated

popup_requested(name,data)

popup_closed(name)

Debug

debug_message(message)

error_occurred(message)

2. Constants.gd
Purpose

Stores all global constants and enumerations.

Contains no executable gameplay logic.

Public API

No methods.

Project Constants

GAME_NAME

VERSION

TARGET_FPS

GRID_WIDTH

GRID_HEIGHT

MAX_LEVEL

MAX_LIVES

LIFE_REGEN_SECONDS

Paths

Scene Paths

Config Paths

Save Paths

Resource Paths

Node Groups
Physics Layers
Enums

GameState

BoardState

TileState

TileType

PowerupType

PowerupCombo

ObstacleType

ObjectiveType

RewardType

BoosterType

StoryTrack

Character

Difficulty

MatchPattern

Direction

AudioBus

3. JsonLoader.gd
Purpose

Generic JSON serialization.

No gameplay logic.

Public API
Initialization

initialize()

Loading

load_file(path)->Dictionary

load_array(path)->Array

Saving

save_file(path,data)->bool

Validation

file_exists(path)

validate_json(path)

4. ConfigLoader.gd
Purpose

Loads and caches configuration files.

Used by managers.

Never owns gameplay.

Public API

initialize()

reload()

clear_cache()

load(path)

reload_file(path)

has(path)

get(path)

get_value(path,key,default)

get_section(path,section)

Internal

_cache

_validate()

5. ResourceManager.gd
Purpose

Caches Godot resources.

No gameplay decisions.

Public API

initialize()

clear()

clear_unused()

load_resource(path)

reload_resource(path)

unload_resource(path)

has(path)

get(path)

load_scene(path)

load_texture(path)

load_audio(path)

load_font(path)

load_animation(path)

Internal

_resource_cache

6. RandomGenerator.gd
Purpose

Single source of randomness.

Every manager requiring randomness uses this class.

Public API

initialize(seed=-1)

random_int(min,max)

random_float(min,max)

random_bool()

chance(percent)

random_index(array)

random_item(array)

shuffle(array)

pick_multiple(array,count)

weighted_choice(items,weights)

random_direction()

random_tile_type(include_ethan=false)

Internal

_rng

7. FileHelper.gd
Purpose

Low-level filesystem helper.

No gameplay logic.

Public API
Files

file_exists(path)

copy_file(source,destination)

move_file(source,destination)

delete_file(path)

rename_file(path,new_name)

get_file_size(path)

Directories

directory_exists(path)

create_directory(path)

delete_directory(path)

list_files(path)

list_directories(path)

8. TimeHelper.gd
Purpose

Common date and time calculations.

Used by SaveManager, EconomyManager and RewardManager.

Public API

current_unix_time()

current_datetime()

seconds_between(a,b)

minutes_between(a,b)

hours_between(a,b)

days_between(a,b)

format_duration(seconds)

9. DebugLogger.gd
Purpose

Central logging utility.

Can be disabled in release builds.

Public API

initialize()

info(message)

warning(message)

error(message)

debug(message)

clear_log()

enable()

disable()

10. Version.gd
Purpose

Stores project version information.

Public API

GAME_NAME

VERSION

SAVE_VERSION

BUILD_NUMBER

version_string()

save_version()

build_number()

Frozen Utilities Dependency
                   Constants
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   SignalBus     RandomGenerator   TimeHelper
        │               │
        ▼               ▼
  ConfigLoader    ResourceManager
        │
        ▼
   JsonLoader
        │
        ▼
    FileHelper

DebugLogger

Version
Version 1 Rules
Utilities contain no gameplay logic.
Utilities never coordinate gameplay; that is the responsibility of managers.
Managers may depend on any utility.
Utilities must never depend on managers or any gameplay subsystem.
SignalBus is the only global event bus.
Constants is the only source of global constants and enums.
RandomGenerator is the only source of random values.
ConfigLoader is the only configuration cache.
ResourceManager is the only resource cache.
JsonLoader performs generic JSON serialization only.
FileHelper performs only low-level filesystem operations.
TimeHelper performs only date/time calculations.
DebugLogger is the project's central logging service.
Version stores only version metadata.