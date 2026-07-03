SAVE THE BABY — CORRECT CONNECTED FILE TREE (V1.0 STRICT)

1. BOOT LAYER (ONLY REAL ENTRY POINT)
   Boot.gd
   │
   ├── initializes utilities:
   │ ├── DebugLogger
   │ ├── RandomGenerator
   │ ├── ConfigLoader
   │ ├── ResourceManager
   │ └── JsonLoader
   │
   ├── reloads configuration:
   │ └── ConfigLoader.reload()
   │
   ├── loads game scene:
   │ └── ResourceManager.load_scene(Constants.ScenePaths.GAME)
   │
   └── instantiates:
   └── Game.tscn (root runtime scene)

✔ Boot DOES NOT talk to managers
✔ Boot DOES NOT control gameplay
✔ Boot ends immediately after scene load

2. GAME SCENE ROOT (RUNTIME ORCHESTRATION BOUNDARY)
   Game.tscn
   │
   └── contains managers:
   ├── GameManager
   ├── LevelManager
   ├── BoardManager
   ├── RewardManager
   ├── EconomyManager
   ├── StoryManager
   ├── SaveManager
   ├── AudioManager
   ├── UIManager
   └── AnimationManager

✔ This is where runtime coordination begins
✔ Managers initialize themselves (per API contract)
✔ No Boot involvement beyond this point

3. MANAGER LAYER (ONLY COORDINATION)
   Core dependency rule from your API:
   Managers communicate via SignalBus
   Managers use Utilities
   Managers DO NOT own subsystem implementation
   Relationship structure (explicit only)
   GameManager
   │
   ├── triggers:
   │ ├── LevelManager
   │ ├── BoardManager
   │ └── StoryManager
   │
   └── receives signals via SignalBus
   LevelManager
   │
   ├── loads:
   │   └── levels/levelXXX.json (via JsonLoader)
   │
   ├── validates:
   │   └── Frozen Level JSON schema
   │
   ├── exposes:
   │   └── Current level data
   │
   └── triggers:
      └── BoardManager.create_board(level_data)
   BoardManager
   │
   ├── uses:
   │ ├── Board.gd
   │ ├── TileFactory
   │ └── TileDatabase
   │
   ├── controls:
   │ └── Board System
   │
   └── emits via SignalBus:
   ├── board_created
   ├── board_ready
   └── board_cleared
   StoryManager
   │
   ├── loads:
   │ ├── configs/story.json
   │ └── stories/*
   │
   └── emits:
   ├── story*started
   └── dialogue events
   EconomyManager
   │
   ├── loads:
   │ └── configs/economy.json
   │
   └── updates:
   ├── coins
   ├── lives
   ├── boosters
   └── stars
   RewardManager
   │
   ├── loads:
   │   └── configs/rewards.json
   │
   ├── coordinates:
   │   └── Reward System
   │
   ├── uses:
   │   ├── RewardCalculator
   │   ├── RewardTable
   │   ├── RewardValidator
   │   ├── RewardDistributor
   │   ├── RewardQueue
   │   ├── RewardFactory
   │   ├── RewardPreview
   │   └── RewardData
   │
   └── triggered by:
    └── LevelManager result
   SaveManager
   │
   ├── uses:
   │ ├── FileHelper
   │ └── TimeHelper
   │
   └── interacts with:
   └── save/ folder
   AudioManager
   │
   ├── loads:
   │ └── configs/audio.json
   │
   └── plays:
   ├── music
   └── sfx
   UIManager
   │
   ├── loads:
   │ └── configs/ui.json
   │
   └── controls:
   ├── HUD
   ├── popups
   └── screens/
   AnimationManager
   │
   ├── uses:
   │ └── scripts/animation/*
   │
   └── dispatches to:
   ├── TileAnimator
   ├── BoardAnimator
   ├── UIAnimator
   └── StoryAnimator
4. BOARD SYSTEM (PURE GAMEPLAY ENGINE)
   BoardManager
   │
   └── owns:
   Board.gd
   │
   ├── BoardGenerator
   ├── MoveValidator
   ├── MatchFinder
   ├── GravitySolver
   ├── RefillSystem
   ├── CascadeProcessor
   ├── BoardShuffler
   └── BoardAnimator

✔ ONLY BoardManager coordinates gameplay
✔ Board.gd is internal coordinator only

5. TILE SYSTEM (ATOMIC GAME OBJECT LAYER)
   BoardManager
   │
   └── uses:
   TileFactory
   │
   └── creates:
   Tile.gd
   │
   ├── TileState
   ├── TileAnimator
   └── TileDatabase
   External dependencies:
   TileDatabase
   └── loads:
   configs/tiles.json
   TileFactory
   └── uses:
   ResourceManager (textures, assets)
6. CONFIG SYSTEM (DATA SOURCE ONLY)

   ConfigLoader
   │
   └── loads:
    configs/*.json
    ├── game.json
    ├── tiles.json
    ├── powerups.json
    ├── obstacles.json
    ├── objectives.json
    ├── rewards.json
    ├── economy.json
    ├── story.json
    ├── audio.json
    ├── ui.json
    ├── animation.json
    ├── board.json
    ├── effects.json
    ├── localization.json
    ├── debug.json
    └── ...

LevelManager
│
└── loads:
    levels/
    ├── level001.json
    ├── level002.json
    ├── ...
    └── level050.json

✔ ConfigLoader loads configuration files only.
✔ LevelManager loads playable level files.
✔ Level files are not part of the configs/ folder.
✔ No gameplay logic
✔ No runtime state

7. RESOURCE SYSTEM (ASSET SOURCE ONLY)
   ResourceManager
   │
   └── loads:
   resources/
   ├── tiles/
   ├── powerups/
   └── obstacles/

Used by:

TileFactory
UIManager
Animation systems 8. ANIMATION FRAMEWORK (GENERIC LAYER)
AnimationManager
│
└── uses:
scripts/animation/
├── AnimationQueue
├── AnimationSequence
├── AnimationRequest
├── TweenHelper
└── AnimationLibrary

Then dispatches to:

Subsystem Animators:
├── TileAnimator
├── BoardAnimator
├── UIAnimator
└── StoryAnimator
🔥 FINAL CORRECT LIFECYCLE (ABSOLUTE TRUTH)
Boot.gd
↓
Utilities initialize
↓
ConfigLoader.reload()
↓
Load Game.tscn
↓
GameManager initializes system state
↓
LevelManager loads and validates levelXXX.json
↓
BoardManager creates board
↓
TileFactory spawns tiles
↓
Board system runs gameplay loop
↓
AnimationManager handles visuals
↓
UI / Audio / Story react via signals
🧠 IMPORTANT FIX SUMMARY

What was corrected:

❌ Boot does NOT coordinate managers
❌ Boot does NOT participate in gameplay flow
❌ Managers are NOT initialized by Boot
✔ Boot ONLY loads scene + utilities
✔ Game scene is the real runtime root
✔ Managers self-initialize inside Game scene
✔ BoardManager is the ONLY gameplay coordinator for board system

---

The correct execution flow (NO ambiguity version)

This is the real chain:

Boot.gd
↓
Initialize utilities (services)
↓
ResourceManager loads Game.tscn
↓
Instantiate Game.tscn
↓
Add Game.tscn to scene tree
↓
GameManager becomes active (via \_ready)
↓
GameManager initializes gameplay systems
↓
Game loop begins

---

Who initializes what?

This is the most important clarity point.

Step-by-step:

1. Boot runs

It initializes services:

ConfigLoader
ResourceManager
etc.

No gameplay exists yet.

2. Boot loads Game.tscn via ResourceManager
   var packed_scene = ResourceManager.load_scene(...)

So ResourceManager is just a tool here.

3. Game.tscn is added to scene tree

Now everything inside Game.tscn wakes up.

Godot automatically calls:

\_ready() on all nodes 4. GameManager activates

Now GameManager runs:

initializes itself
then starts LevelManager, BoardManager, etc.

THIS is the real “game start moment”
