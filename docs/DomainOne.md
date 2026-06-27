🧠 BIG PICTURE (what you are building in Godot)

You are NOT building scripts first.

You are building this runtime hierarchy:

Game.tscn (root scene)
├── Managers (autoload or scene node group)
│ ├── GameManager
│ ├── BoardManager
│ ├── LevelManager
│ ├── UIManager
│ ├── AnimationManager
│ ├── AudioManager
│ ├── EconomyManager
│ ├── SaveManager
│ ├── RewardManager
│ └── StoryManager
│
├── BoardRoot
│ ├── Board (Node2D)
│ ├── TileContainer (Node2D)
│ ├── ObstacleContainer (Node2D)
│ └── PowerupContainer (Node2D)
│
├── UIRoot
└── Camera2D

Everything in your API maps plugs into THIS runtime structure.

🎮 STEP 1 — CREATE MAIN SCENE
In Godot:
Click:
Scene → New Scene
Choose root node:
Node2D
Rename it:
Game
Save it:
scenes/game/Game.tscn
🎮 STEP 2 — ADD CORE CHILD NODES

Inside Game.tscn, add these:

2.1 Add Managers container
Click Game node → Right click → Add Child Node

Add:

Node (rename: Managers)
Inside Managers, add these nodes:

Right click Managers → Add Child Node:

Create each:

GameManager
BoardManager
LevelManager
RewardManager
StoryManager
AudioManager
SaveManager
UIManager
AnimationManager
EconomyManager
🔧 ATTACH SCRIPTS

For EACH manager node:

Click node → Inspector → Script → Attach Script

Then:

Path: scripts/managers/GameManager.gd
Path: scripts/managers/BoardManager.gd
...

Repeat for all 10 managers.

RESULT:

You now have:

Managers/
├── GameManager (GameManager.gd)
├── BoardManager (BoardManager.gd)
├── LevelManager (LevelManager.gd)
├── RewardManager (RewardManager.gd)
├── StoryManager (StoryManager.gd)
├── AudioManager (AudioManager.gd)
├── SaveManager (SaveManager.gd)
├── UIManager (UIManager.gd)
├── AnimationManager (AnimationManager.gd)
└── EconomyManager (EconomyManager.gd)
🎮 STEP 3 — CREATE BOARD ROOT STRUCTURE
Click Game → Add Child Node:
Node2D (rename: BoardRoot)
Inside BoardRoot add:

1. Board node
   Node2D → rename: Board
   Attach script:
   scripts/board/Board.gd
2. Tile container
   Node2D → rename: TileContainer
   (no script)
3. Obstacle container
   Node2D → rename: ObstacleContainer
   (no script)
4. Powerup container
   Node2D → rename: PowerupContainer
   (no script)
   RESULT:
   BoardRoot/
   ├── Board (Board.gd)
   ├── TileContainer
   ├── ObstacleContainer
   └── PowerupContainer
   🎮 STEP 4 — ADD CAMERA

Under Game:

Add:
Camera2D → rename: MainCamera

Enable:

Current = true
🎮 STEP 5 — ADD UI ROOT

Under Game:

Add:
CanvasLayer → rename: UIRoot

Inside it later you will attach UI scenes.

(Do NOT build UI yet — just structure it)

🎮 STEP 6 — WHERE YOUR SYSTEMS ACTUALLY GO (IMPORTANT)

Now map your folders to the scene:

🧠 Managers (runtime brain)

They live in:

Game/Managers/\*

They NEVER visually exist.

They:

talk to Board
call factories
send signals
🧠 Board System

Lives in:

Game/BoardRoot/Board
scripts/board/\*

Board is ONLY a controller node over:

TileFactory (script only)
MoveValidator
MatchFinder
GravitySolver
etc.
🧠 Tiles (important)

Tiles are NOT manually placed in editor.

They are spawned at runtime into:

Game/BoardRoot/TileContainer

Created via:

TileFactory.gd
🧠 Obstacles

Spawn into:

Game/BoardRoot/ObstacleContainer

via:

ObstacleFactory.gd
🧠 Powerups

Spawn into:

Game/BoardRoot/PowerupContainer

via:

PowerupFactory.gd
🎮 STEP 7 — WHAT YOU DO NOT CREATE IN EDITOR

This is important:

You DO NOT manually add:

Tiles
Obstacles
Powerups
Matches
Board grid

Everything is runtime generated.

🎮 STEP 8 — SIGNALBUS SETUP (CRITICAL)

You should add SignalBus as:

Option A (recommended)

Autoload:

Project Settings → Autoload

Add:

scripts/utilities/SignalBus.gd

Name:

SignalBus
🎮 STEP 9 — FINAL GODOT HIERARCHY (WHAT YOU SHOULD SEE)

In Scene dock:

Game (Node2D)
├── Managers
│ ├── GameManager
│ ├── BoardManager
│ ├── LevelManager
│ ├── RewardManager
│ ├── StoryManager
│ ├── AudioManager
│ ├── SaveManager
│ ├── UIManager
│ ├── AnimationManager
│ └── EconomyManager
│
├── BoardRoot
│ ├── Board
│ ├── TileContainer
│ ├── ObstacleContainer
│ └── PowerupContainer
│
├── UIRoot (CanvasLayer)
└── MainCamera
🎮 STEP 10 — HOW YOUR API MAP CONNECTS TO SCENES
API Layer Godot Location
GameManager Game/Managers/GameManager
BoardManager Game/Managers/BoardManager
LevelManager Game/Managers/LevelManager
Board.gd Game/BoardRoot/Board
Tiles runtime → TileContainer
Obstacles runtime → ObstacleContainer
Powerups runtime → PowerupContainer
AnimationManager Game/Managers/AnimationManager
UIManager Game/Managers/UIManager + UIRoot
⚠️ IMPORTANT RULE (matches your architecture)

You MUST remember:

Scene = structure only
Scripts = logic only
Managers = orchestration only
Board system = mechanics only
Factories = creation only

No overlap.

If you want next step
