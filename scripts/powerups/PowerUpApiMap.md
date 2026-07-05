scripts/powerups/
Powerup System API Map (Version 1.0 Freeze)
Purpose

The Powerup System defines everything about an individual powerup.

It is responsible only for powerup data, powerup visuals, powerup creation, powerup animation, powerup metadata, and powerup-specific behaviour.

It never coordinates gameplay flow.

Gameplay coordination belongs to BoardManager.

Animation scheduling belongs to AnimationManager.

Powerup creation requests come from BoardManager.

Configuration comes from ConfigLoader.

Resources come from ResourceManager.

Communication occurs through SignalBus.

This folder is therefore fully aligned with the frozen Utilities API, Managers API, Config API, Resources API, Tile API, Economy API, Obstacle API, and Animation API.

Folder Structure
scripts/
└── powerups/
    ├── PowerupState.gd
    ├── Powerup.gd
    ├── PowerupDatabase.gd
    ├── PowerupFactory.gd
    ├── PowerupAnimator.gd
    └── behaviors/
            ├── PowerupBehavior.gd
            ├── RocketBehavior.gd
            ├── BombBehavior.gd
            ├── ThunderBehavior.gd
            ├── ColorBombBehavior.gd
            ├── LineBlastBehavior.gd
            └── ...

Additional powerup behavior classes may be added without changing this API.
Every behavior inherits from PowerupBehavior.gd.
1. PowerupState.gd
Purpose

Stores every piece of gameplay state belonging to one powerup.

Contains no visual logic.

Contains no animation logic.

Contains no board logic.

Contains no gameplay coordination.

Public API
Initialization
initialize(powerup_type, grid_position)

reset()

duplicate_state() -> PowerupState
Identity
set_powerup_type(type)

get_powerup_type() -> Constants.PowerupType
Grid
set_position(position)

get_position() -> Vector2i
State
set_state(state)

get_state()

is_state(state)
Flags
set_active(value)

is_active()

set_armed(value)

is_armed()

set_consumed(value)

is_consumed()

reset_flags()
Internal
_powerup_type

_grid_position

_state

_active

_armed

_consumed
2. Powerup.gd
Purpose

Represents one powerup node inside the scene tree.

Responsible only for

visual representation
holding a PowerupState
requesting animation playback through PowerupAnimator
exposing powerup information

Never performs gameplay coordination.

Never performs board updates.

Never performs scoring.

Never performs rewards.

Signals
pressed(powerup)

released(powerup)

clicked(powerup)
Public API
Initialization
initialize(type, grid_position)

reset()
State
get_powerup_state()

set_powerup_state(state)

duplicate_powerup_state()
Grid
set_grid_position(position)

get_grid_position()
Identity
set_powerup_type(type)

get_powerup_type()
Activation
activate()

deactivate()

is_active()
Visibility
show()

hide()

set_visible(value)
Visual
set_texture(texture)

get_texture()

set_modulate(color)

reset_modulate()
Animation

request_animation(name)

is_animation_playing()
Internal
_state

_sprite

_animation_player
3. PowerupDatabase.gd
Purpose

Loads every powerup definition from

configs/powerups.json

Provides lookup services only.

Contains no gameplay logic.

Public API
Initialization
initialize()

reload()

clear()
Lookup
get_powerup(id)

has_powerup(id)

get_powerup_by_enum(type)

get_name(type)

get_texture_path(type)

get_icon_path(type)

get_animation_set(type)

get_activation_type(type)

get_combination_rules(type)

get_description(type)
Collections
get_all()

get_match_created()

get_booster_created()

get_combinable()
Internal
_powerup_cache
4. PowerupFactory.gd
Purpose

Creates and destroys powerup nodes.

Never decides gameplay.

Never decides placement.

BoardManager owns powerup placement.

Public API
Initialization
initialize()
Creation
create_powerup(type)

create_powerup_at(type, position)
Copy
duplicate_powerup(powerup)
Lifecycle
destroy_powerup(powerup)

recycle_powerup(powerup)

reset_powerup(powerup)
Internal
_apply_database_data()

_assign_texture()

_assign_animation_set()

_assign_metadata()

_assign_behavior()
5. PowerupBehavior.gd
Purpose

Base behaviour class for every powerup.

BoardManager decides when powerup behaviour should execute.

PowerupBehavior defines how one powerup behaves.

Contains no board coordination.

Public API
Initialization
initialize(powerup)
Lifecycle
activate()

deactivate()

reset()
Gameplay
on_activate()

on_combine(other_powerup)

can_activate()

can_combine()
Internal
_powerup
Specialized Behaviors

Each powerup type provides its own behavior implementation by inheriting from PowerupBehavior.gd.

Examples include

RocketBehavior.gd
BombBehavior.gd
ThunderBehavior.gd
ColorBombBehavior.gd
LineBlastBehavior.gd

Additional behavior classes may be added without modifying this API.

6. PowerupAnimator.gd
Purpose

Owns every animation affecting a powerup.

AnimationManager decides when animations occur.

PowerupAnimator performs how powerup animations are played.

Uses the reusable framework from

scripts/animation/

Contains no gameplay logic.

Public API
Initialization
initialize()
Basic
play_create(powerup)

play_activate(powerup)

play_combine(first, second)

play_destroy(powerup)

play_charge(powerup)

play_highlight(powerup)

play_shake(powerup)
Utility
stop(powerup)

stop_all()

pause(powerup)

resume(powerup)

is_playing(powerup)

wait_until_finished(powerup)
Internal
_create_tween()

_finish_animation()
Frozen Powerup System Dependency
                 BoardManager
                      │
                      ▼
              PowerupFactory
                      │
                      ▼
                 Powerup
          ┌──────────┼──────────┐
          ▼          ▼          ▼
 PowerupState  PowerupAnimator  PowerupDatabase
          │
          ▼
     behaviors/
          │
          ▼
   PowerupBehavior
      ├── RocketBehavior
      ├── BombBehavior
      ├── ThunderBehavior
      ├── ColorBombBehavior
      ├── LineBlastBehavior
      └── ...

ConfigLoader
ResourceManager
SignalBus
Version 1 Rules

The Powerup System represents individual powerups only.

BoardManager is the only manager that coordinates powerup gameplay.

AnimationManager decides when powerup animations should run.

PowerupAnimator only performs powerup animations.

PowerupFactory only creates, duplicates, resets, recycles, and destroys powerup nodes.

PowerupDatabase is the only source of powerup metadata loaded from configs/powerups.json.

PowerupState stores gameplay data for one powerup only.

Powerup.gd is responsible only for the visual node, forwarding powerup events, and requesting animation playback through PowerupAnimator.

PowerupBehavior.gd is the abstract base class for powerup-specific behavior. Every powerup behavior inherits from it and implements only the mechanics unique to that powerup. New powerup behaviors may be added without modifying the Powerup System API.

The Powerup System never performs board generation, matching, gravity, cascades, objectives, scoring, rewards, economy, story progression, save operations, or gameplay coordination.

The Powerup System may depend on Constants, SignalBus, ConfigLoader, ResourceManager, RandomGenerator, and the reusable animation framework.

The Powerup System must not depend on gameplay managers except through requests coordinated by BoardManager or notifications through SignalBus.

This API matches the same architectural pattern used by your frozen Utilities, Managers, Configs, Resources, Tiles, Obstacles, Economy, and Animation APIs, so it fits into the Version 1 architecture without requiring changes to the existing frozen APIs.