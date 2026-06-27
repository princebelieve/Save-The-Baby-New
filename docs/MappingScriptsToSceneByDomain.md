🔷 DOMAIN 1 — CORE GAMEPLAY (REAL-TIME BOARD SYSTEM)
Includes scripts:
scripts/managers/
scripts/board/
scripts/tiles/
scripts/powerups/
scripts/obstacles/
Maps to scenes:
scenes/game/GameplayRoot.tscn
scenes/board/\* (runtime instancing under GameplayRoot)
PURPOSE

Defines everything that exists on the interactive board during gameplay.

This is the simulation layer of the game.

SCENE OWNERSHIP
GameplayRoot.tscn
│
├── Board (Node)
│ ├── Tiles (runtime)
│ ├── Powerups (runtime)
│ └── Obstacles (runtime)
RESPONSIBILITY BOUNDARY
Board System owns:
board grid creation
tile placement
swap resolution
refill logic
Tiles own:
tile visuals
tile metadata
tile animations (visual only)
Powerups own:
explosion visuals
activation animations
effect presentation
Obstacles own:
visual state changes
obstacle animations
obstacle reactions
MANAGER CONNECTIONS
BoardManager → owns all runtime board scenes
AnimationManager → triggers visual animations only
GameManager → state control only
LevelManager → provides level layout data
RULE

No UI, no rewards, no story logic exists in this domain.

🔷 DOMAIN 2 — PROGRESSION SYSTEM
Includes scripts:
scripts/economy/
scripts/reward/
scripts/save/
scripts/level/
Maps to scenes:
scenes/reward/
scenes/popup/
scenes/level/
PURPOSE

Handles player progression state changes, not gameplay simulation.

SCENE OWNERSHIP
GameplayRoot
│
├── RewardLayer (CanvasLayer)
├── LevelFlow (Scene transitions)
└── PopupLayer (Reward/UI injection)
RESPONSIBILITY BOUNDARY
LevelManager
loads level data
triggers level lifecycle
EconomyManager
updates coins/lives/stars
validates purchases
RewardManager
calculates rewards
triggers reward scenes
SaveManager
persists all progression state
no UI responsibility
RULE

This domain never touches board objects directly. It only reacts to outcomes.

🔷 DOMAIN 3 — PRESENTATION SYSTEM
Includes scripts:
scripts/ui/
scripts/animation/
scripts/audio/
Maps to scenes:
scenes/ui/
scenes/popup/
scenes/tutorial/
PURPOSE

Controls what the player sees and hears, not what the game simulates.

SCENE OWNERSHIP
GameplayRoot
├── HUD (CanvasLayer)
├── PopupLayer (CanvasLayer)
├── TransitionLayer (CanvasLayer)
RESPONSIBILITY BOUNDARY
UIManager
screen switching
popup lifecycle
HUD updates
AnimationManager
plays reusable animations
no gameplay logic
AudioManager
music + SFX only
no game state awareness
RULE

Presentation layer can observe everything, but must not change gameplay state directly.

🔷 DOMAIN 4 — NARRATIVE SYSTEM
Includes scripts:
scripts/story/
Maps to scenes:
scenes/story/
PURPOSE

Controls dialogue, story progression, and narrative flow.

SCENE OWNERSHIP
GameplayRoot
├── StoryLayer (CanvasLayer)
RESPONSIBILITY BOUNDARY
StoryManager
dialogue sequencing
choices
story progression state
Story Scenes
portraits
text boxes
dialogue UI
RULE

Story system can pause gameplay, but never manipulates board state directly.

🔷 DOMAIN 5 — BOOTSTRAP / APPLICATION SHELL
Includes scripts:
scripts/managers/
scripts/utilities/
Maps to scenes:
scenes/boot/
scenes/game/
PURPOSE

Defines application lifecycle and permanent runtime structure.

SCENE OWNERSHIP
Boot.tscn
↓
Game.tscn
├── Managers.tscn (persistent)
└── GameplayRoot.tscn (runtime container)
RESPONSIBILITY BOUNDARY
Boot Scene
initialization only
loads configs
loads save
transitions into Game.tscn
Game Scene
holds persistent managers
never contains gameplay logic itself
RULE

This domain defines existence, not behavior.

✔️ HOW YOU USE THIS FORMAT

Instead of:

scripts/managers → scripts/board → scripts/tiles → scripts/powerups...

You now do:

Paste 1:

CORE GAMEPLAY DOMAIN (complete)

Paste 2:

PROGRESSION DOMAIN (complete)

Paste 3:

PRESENTATION DOMAIN (complete)

Paste 4:

NARRATIVE DOMAIN (complete)

Paste 5:

BOOTSTRAP DOMAIN (complete)

✔️ WHY THIS FIXES YOUR PROBLEM

Your original system was:

dependency ordered
but cognitively fragmented
required cross-referencing while reading

This new system is:

self-contained per domain
no cross guessing
matches manager ownership
mirrors runtime scene hierarchy
lets you freeze modules cleanly
