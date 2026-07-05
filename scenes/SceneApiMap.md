# Save The Baby — Scene API Map (Version 1.0 Freeze)

---

# 1. CORE PRINCIPLE

The Scene Layer defines:

- What exists in the Godot scene tree at runtime

- Who owns which nodes

- Where objects are instantiated

- Lifetime of visual/runtime containers

- Structural hierarchy only

It does NOT define:

- gameplay logic

- manager behavior

- animation logic

- data schema

All logic remains in:

- scripts/managers/

- scripts/board/

- scripts/tiles/

- scripts/animation/

- scripts/utilities/

---

# 2. SCENE LAYER STRUCTURE OVERVIEW

## Root Runtime Flow

```text

Boot.gd

   ↓

Game.tscn (instantiated)

   ↓

Managers initialize

   ↓

Board + UI + gameplay containers activated



3. scenes/boot/ (STARTUP LAYER)

Boot.tscn

Boot (Node)

[Boot.gd]

Responsibilities

Initialize utilities only

Load ConfigLoader

Load ResourceManager

Instantiate Game.tscn

Exit immediately after handover

Rule



✔ No managers

✔ No gameplay nodes

✔ No scene persistence



4. scenes/game/ (RUNTIME ROOT)

Game.tscn

Game (Node2D)

│

├── Managers (Node)

├── BoardRoot (Node2D)

├── UIRoot (CanvasLayer)

└── MainCamera (Camera2D)

4.1 Managers Node

Managers (Node)

│

├── GameManager

├── BoardManager

├── LevelManager

├── RewardManager

├── StoryManager

├── AudioManager

├── SaveManager

├── UIManager

├── AnimationManager

└── EconomyManager

Rules

Managers are long-lived for the session

Managers are NOT parents of gameplay nodes

Managers communicate via SignalBus only

Managers do NOT instantiate scene containers directly (they request via factories/systems)

4.2 BoardRoot (GAMEPLAY CONTAINER)

BoardRoot (Node2D)

│

├── Board (Node2D)

├── TileContainer (Node2D)

├── ObstacleContainer (Node2D)

└── PowerupContainer (Node2D)

Ownership Rules

BoardRoot = pure container (no logic)

BoardManager controls lifecycle of Board system

TileFactory spawns into TileContainer

ObstacleFactory (future) spawns into ObstacleContainer

PowerupFactory (future) spawns into PowerupContainer

4.3 Board Node

Board (Node2D)

[Board.gd]

Responsibilities

Internal board coordination only

Holds board runtime state

Delegates:

generation → BoardManager

tile creation → TileFactory

matching → MatchFinder (internal system)

gravity → GravitySolver (internal system)

4.4 UIRoot (UI LAYER)

UIRoot (CanvasLayer)

│

(no fixed children at startup)

Rules

UIManager owns all UI instantiation

Screens/popups are dynamically added here

Never contains gameplay logic

4.5 Camera

MainCamera (Camera2D)

Rules

Owned by scene only

Can be controlled by Camera system or UIManager (if needed)

Never owns gameplay logic

5. SCENE OWNERSHIP MATRIX

System	Owns	Instantiates Into

Boot	nothing (startup only)	Game.tscn

Game.tscn	runtime structure	all root nodes

GameManager	state coordination	none

BoardManager	board lifecycle	Board (via scene)

TileFactory	tiles	TileContainer

UIManager	UI screens	UIRoot

AnimationManager	animation routing	none

AudioManager	audio only	none

6. TILE SYSTEM SCENE RULES

Tile Scene (runtime instance)

Tile (Node2D)

├── Sprite2D

├── AnimationPlayer

└── (input handling via Tile.gd)

Ownership Rules

Created ONLY by TileFactory

Parent = TileContainer

Controlled by Board system

Never directly created by BoardManager

7. LIFETIME RULES

Boot.tscn

Exists briefly

Destroyed after Game loads

Game.tscn

Exists for entire gameplay session

Managers

Exist for full session lifetime

Never recreated per level

BoardRoot

Persistent across levels

Reset/cleared by BoardManager

Tiles

Created/destroyed frequently

Owned by TileFactory lifecycle

UI

Dynamically created and destroyed

Controlled by UIManager

8. KEY RULES (STRICT)

✔ Scene owns structure only



No logic in scene nodes beyond forwarding



✔ Managers own coordination only



No direct gameplay execution



✔ Factories own creation



No manual instantiation outside factories



✔ BoardRoot is passive



It never decides anything



✔ Tiles are atomic runtime objects



They do not know board rules



9. FINAL HIERARCHY (TRUTH MODEL)

Boot

  ↓

Game.tscn

  ├── Managers (logic coordination)

  ├── BoardRoot (runtime containers)

  │     ├── Board

  │     ├── TileContainer

  │     ├── ObstacleContainer

  │     └── PowerupContainer

  ├── UIRoot (UI runtime layer)

  └── MainCamera

10. SUMMARY

Scene Layer = structure only

Managers = coordination

Factories = creation

Board system = gameplay execution

Tiles = atomic objects

UI = separate runtime layer

Animation system = cross-layer routing
```
