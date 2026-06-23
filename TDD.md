# SAVE THE BABY

# Technical Design Document (TDD)

Version 1.0

---

# Project Philosophy

The project must be:

- Modular
- Data-driven
- Scalable
- Maintainable
- Reusable
- Easy to test
- Easy to expand

No feature should depend on hardcoded values unless there is no practical alternative.

---

# Core Architecture

Everything is divided into independent systems.

```
Game
│
├── Managers
├── Board
├── Tiles
├── Obstacles
├── Powerups
├── Story
├── UI
├── Save
├── Economy
├── Audio
├── Animation
└── Utilities
```

Each system must have only one responsibility.

---

# Folder Structure

```
SaveTheBaby/

assets/
    sprites/
        tiles/
        ui/
        characters/
        backgrounds/
        obstacles/
        powerups/
        effects/

    audio/
        music/
        sfx/

    fonts/

animations/

configs/

docs/

levels/

stories/

translations/

scenes/

    boot/

    menu/

    board/

    level/

    ui/

    story/

    game/

    popup/

    reward/

    tutorial/

scripts/

    managers/

    board/

    tiles/

    powerups/

    obstacles/

    ui/

    story/

    save/

    economy/

    animation/

    utilities/

resources/

addons/
```

---

# Scene Architecture

Boot Scene

↓

Splash Scene

↓

Main Menu

↓

Level Select

↓

Story Scene

↓

Gameplay Scene

↓

Victory/Game Over

↓

Reward Scene

↓

Next Story

---

# Managers

Managers are global systems.

GameManager

Controls overall game state.

Responsibilities

- current level
- loading scenes
- game flow

---

BoardManager

Controls the board.

Responsibilities

- create board
- swap tiles
- detect matches
- cascades
- gravity

---

LevelManager

Loads level JSON.

Responsibilities

- moves
- objectives
- difficulty

---

StoryManager

Loads dialogue JSON.

Responsibilities

- characters
- portraits
- dialogue
- branching

---

RewardManager

Handles

- coins
- stars
- treasure
- streak rewards

---

SaveManager

Handles

- save
- load
- autosave

---

AudioManager

Handles

music

effects

voice

volume

---

UIManager

Handles

menus

popups

HUD

buttons

animations

---

AnimationManager

Reusable animations.

---

AdsManager

Future integration.

Reward ads

Interstitial

Banner

---

# Scene Responsibilities

Every scene should have one purpose.

Example

Board scene should NEVER save data.

SaveManager does that.

---

# Tile System

Every tile is the same scene.

```
Tile.tscn
```

One script.

```
Tile.gd
```

Properties

```
tile_id

tile_type

sprite

health

movable

matchable

special

obstacle
```

The tile type determines behaviour.

Never create

KeyTile.gd

PhoneTile.gd

BombTile.gd

unless absolutely necessary.

---

# Tile Types

Collectible

key

phone

fingerprint

recorder

tape

clock

Obstacle

chain

bomb

missile

lock

pincher

plier

Special

rocket

thunder

bomb_power

future specials

---

# Powerup System

Powerups inherit common behaviour.

Powerups should know

activation type

animation

radius

effect

Nothing else.

---

# Board System

Board size loaded from JSON.

Default

```
8 x 8
```

Later

6 x 6

9 x 9

10 x 10

Engine should support all.

---

# Board Responsibilities

Spawn

Swap

Validate

Match

Destroy

Gravity

Refill

Cascade

Notify objectives

Nothing more.

---

# Gravity System

Algorithm

Top

↓

Bottom

↓

Move tiles downward

↓

Spawn missing tiles

↓

Search for cascades

Repeat until stable.

---

# Matching System

Detect

Horizontal

Vertical

L-shape

T-shape

Square

Future custom shapes.

---

# Level System

Every level

```
level001.json
```

contains

```
id

name

moves

difficulty

board_size

spawn_pool

objectives

obstacles

rewards

music

background

tutorial

story_before

story_after
```

No code changes should be needed for a new level.

---

# Story System

Every story

```
chapter01_scene01.json
```

contains

background

character

portrait

dialogue

animation

sound

choice

next_scene

Conditions can later support branching based on player progress.

---

# Save File

Single save file.

Stores

coins

stars

lives

settings

levels

story

boosters

achievements

daily rewards

statistics

Use versioning so future updates can migrate older save files safely.

---

# Reward System

Rewards loaded from JSON.

Example

coins

stars

powerups

lives

boosters

No reward values inside scripts.

---

# Economy

Config file.

Contains

life regeneration

coin rewards

shop prices

reward multipliers

Everything editable.

---

# Configuration Files

Examples

```
game.json

economy.json

powerups.json

tiles.json

obstacles.json

audio.json

ui.json

settings.json
```

Scripts should read from these files rather than embedding constants wherever possible.

---

# Signals

Managers communicate through signals.

Example

Level Completed

↓

RewardManager

↓

SaveManager

↓

StoryManager

No direct dependencies.

This keeps systems loosely coupled.

---

# Naming Convention

Scenes

```
MainMenu.tscn

Board.tscn

Tile.tscn
```

Scripts

```
game_manager.gd

board_manager.gd

reward_manager.gd
```

Variables

```
snake_case
```

Classes

```
PascalCase
```

Constants

```
UPPER_CASE
```

JSON

```
lower_case
```

Assets

```
key.png

phone.png

bomb.png
```

No spaces.

---

# Coding Standards

Functions should do one job.

Maximum practical function size:

Around 30–50 lines.

Avoid duplicate logic.

Comment complex algorithms.

Prefer composition.

Avoid circular dependencies.

Never access another manager's internals directly when a signal or API exists.

---

# Performance

Object pooling where useful.

Reuse animations.

Cache resources.

Avoid unnecessary scene creation.

Profile before optimizing.

---

# Future Features

Online leaderboard

Cloud saves

Localization

Accessibility

Controller support

Events

Season passes

New chapters

Additional game modes

Architecture should not block these features.

---

# Git Workflow

main

Always stable.

develop

Current development.

feature/\*

One feature per branch.

Commit messages

```
feat: add tile swapping

fix: cascade bug

refactor: board manager

docs: update TDD
```

---

# Testing Checklist

Every feature must be tested for:

Correct behaviour

No crashes

Performance

Save compatibility

Reload compatibility

Animation

Sound

UI

Regression (existing features still work)

---

# Milestones

M1

Project setup

M2

Board engine

M3

Matching

M4

Gravity

M5

Objectives

M6

Powerups

M7

Obstacles

M8

Story

M9

Rewards

M10

Save system

M11

UI polish

M12

Audio polish

M13

Optimization

M14

Release candidate

M15

Version 1.0

---

# Definition of Done

A feature is complete only when:

- Code works.
- Code is reusable.
- No unnecessary hardcoding.
- No known critical bugs.
- Integrated with existing systems.
- Tested.
- Documented if needed.
- Committed to Git.

---

# Development Rules

1. Build systems before content.
2. Never rush features.
3. Test every milestone.
4. Refactor when necessary.
5. Prefer configuration over hardcoding.
6. Keep managers focused.
7. Keep scripts small and readable.
8. Every new system must be reusable.
9. Preserve backward compatibility where practical.
10. Build for Version 1.0, but design for Version 10.0.
