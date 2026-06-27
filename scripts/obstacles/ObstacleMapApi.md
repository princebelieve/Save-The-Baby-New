scripts/obstacles/
Obstacle System API Map (Version 1.0 Freeze)
Purpose

The Obstacle System defines everything about an individual obstacle.

It is responsible only for obstacle data, obstacle visuals, obstacle creation, obstacle animation, obstacle metadata, and obstacle-specific behaviour.

It never coordinates gameplay flow.

Gameplay coordination belongs to BoardManager.

Animation scheduling belongs to AnimationManager.

Obstacle creation requests come from BoardManager.

Configuration comes from ConfigLoader.

Resources come from ResourceManager.

Communication occurs through SignalBus.

This folder is therefore fully aligned with the frozen Utilities API, Managers API, Config API, Resources API, Tile API, Economy API, and Animation API.

Folder Structure
scripts/
└── obstacles/
    ├── ObstacleState.gd
    ├── Obstacle.gd
    ├── ObstacleDatabase.gd
    ├── ObstacleFactory.gd
    ├── ObstacleAnimator.gd
    └── └── behaviors/
            ├── ObstacleBehavior.gd
            ├── ChainBehavior.gd
            ├── LockBehavior.gd
            ├── ...    
            
 Additional obstacle behavior classes may be added without changing this API. Every behavior inherits from ObstacleBehavior.gd.                                                                                

1. ObstacleState.gd
Purpose

Stores every piece of gameplay state belonging to one obstacle.

Contains no visual logic.

Contains no animation logic.

Contains no board logic.

Contains no gameplay coordination.

Public API
Initialization
initialize(obstacle_type, grid_position)

reset()

duplicate_state() -> ObstacleState
Identity
set_obstacle_type(type)

get_obstacle_type() -> Constants.ObstacleType
Grid
set_position(position)

get_position() -> Vector2i
State
set_state(state)

get_state()

is_state(state)
Health
set_health(value)

get_health()

damage(amount)

heal(amount)

is_destroyed()
Flags
set_locked(value)

is_locked()

set_hidden(value)

is_hidden()

set_active(value)

is_active()

reset_flags()
Internal
_obstacle_type

_grid_position

_state

_health

_locked

_hidden

_active
2. Obstacle.gd
Purpose

Represents one obstacle node inside the scene tree.

Responsible only for

visual representation
holding an ObstacleState
requesting animation playback through ObstacleAnimator
exposing obstacle information

Never performs gameplay coordination.

Never performs board updates.

Never performs scoring.

Never performs rewards.

Signals
pressed(obstacle)

released(obstacle)

clicked(obstacle)
Public API
Initialization
initialize(type, grid_position)

reset()
State
get_obstacle_state()

set_obstacle_state(state)

duplicate_obstacle_state()
Grid
set_grid_position(position)

get_grid_position()
Identity
set_obstacle_type(type)

get_obstacle_type()
Health
damage(amount)

heal(amount)

is_destroyed()
Lock
lock()

unlock()

is_locked()
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
3. ObstacleDatabase.gd
Purpose

Loads every obstacle definition from

configs/obstacles.json

Provides lookup services only.

Contains no gameplay logic.

Public API
Initialization
initialize()

reload()

clear()
Lookup
get_obstacle(id)

has_obstacle(id)

get_obstacle_by_enum(type)

get_name(type)

get_texture_path(type)

get_animation_set(type)

get_health(type)

get_destroy_score(type)
Collections
get_all()

get_removable()

get_blocking()

get_hidden()
Validation
is_removable(type)

blocks_matching(type)

blocks_gravity(type)
Internal
_obstacle_cache
4. ObstacleFactory.gd
Purpose

Creates and destroys obstacle nodes.

Never decides gameplay.

Never decides placement.

BoardManager owns obstacle placement.

Public API
Initialization
initialize()
Creation
create_obstacle(type)

create_obstacle_at(type, position)
Copy
duplicate_obstacle(obstacle)
Lifecycle
destroy_obstacle(obstacle)

recycle_obstacle(obstacle)

reset_obstacle(obstacle)
Internal
_apply_database_data()

_assign_texture()

_assign_animation_set()

_assign_metadata()

_assign_behavior()
5. ObstacleBehavior.gd
Purpose

Base behaviour class for every obstacle.

BoardManager decides when obstacle behaviour should execute.

ObstacleBehavior defines how one obstacle behaves.

Contains no board coordination.

Public API
Initialization
initialize(obstacle)
Lifecycle
activate()

deactivate()

reset()
Gameplay
on_match(match)

on_damage(amount)

on_destroy()

can_be_damaged()

can_be_removed()
Internal
_obstacle
Specialized Behaviors

Each obstacle type provides its own behavior implementation by inheriting from ObstacleBehavior.gd.

Examples include:

• ChainBehavior.gd
• LockBehavior.gd
• TapeBehavior.gd
• BombBehavior.gd
• MissileBehavior.gd
• ElectricTrapBehavior.gd

Additional behavior classes may be added without modifying this API.
activate()

disable()

requires_thunder()

on_thunder_used()
6. ObstacleAnimator.gd
Purpose

Owns every animation affecting an obstacle.

AnimationManager decides when animations occur.

ObstacleAnimator performs how obstacle animations are played.

Uses the reusable framework from

scripts/animation/

Contains no gameplay logic.

Public API
Initialization
initialize()
Basic
play_spawn(obstacle)

play_damage(obstacle)

play_destroy(obstacle)

play_unlock(obstacle)

play_activate(obstacle)

play_deactivate(obstacle)

play_shake(obstacle)

play_highlight(obstacle)
Utility
stop(obstacle)

stop_all()

pause(obstacle)

resume(obstacle)

is_playing(obstacle)

wait_until_finished(obstacle)
Internal
_create_tween()

_finish_animation()
Frozen Obstacle System Dependency
                 BoardManager
                      │
                      ▼
              ObstacleFactory
                      │
                      ▼
                 Obstacle
          ┌──────────┼──────────┐
          ▼          ▼          ▼
 ObstacleState  ObstacleAnimator  ObstacleDatabase
          │
          ▼
     behaviors/
          │
          ▼
  ObstacleBehavior
      ├── ChainBehavior
      ├── LockBehavior
      ├── TapeBehavior
      ├── BombBehavior
      ├── MissileBehavior
      ├── ElectricTrapBehavior
      └── ...

ConfigLoader
ResourceManager
SignalBus

Version 1 Rules
The Obstacle System represents individual obstacles only.
BoardManager is the only manager that coordinates obstacle gameplay.
AnimationManager decides when obstacle animations should run.
ObstacleAnimator only performs obstacle animations.
ObstacleFactory only creates, duplicates, resets, recycles, and destroys obstacle nodes.
ObstacleDatabase is the only source of obstacle metadata loaded from configs/obstacles.json.
ObstacleState stores gameplay data for one obstacle only.
Obstacle.gd is responsible only for the visual node, forwarding obstacle events, and requesting animation playback through ObstacleAnimator.
ObstacleBehavior.gd is the abstract base class for obstacle-specific behavior. Every obstacle behavior inherits from it and implements only the mechanics unique to that obstacle. New obstacle behaviors may be added without modifying the Obstacle System API.
The Obstacle System never performs board generation, matching, gravity, cascades, objectives, scoring, rewards, economy, story progression, save operations, or gameplay coordination.
The Obstacle System may depend on Constants, SignalBus, ConfigLoader, ResourceManager, RandomGenerator, and the reusable animation framework.
The Obstacle System must not depend on gameplay managers except through requests coordinated by BoardManager or notifications through SignalBus.

This API matches the same architectural pattern used by your frozen Utilities, Managers, Configs, Resources, Tiles, Economy, and Animation APIs, so it should fit into the Version 1 architecture without requiring changes to the existing frozen APIs.