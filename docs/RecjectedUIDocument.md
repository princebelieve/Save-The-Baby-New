scripts/ui/
UI SYSTEM API MAP (VERSION 1.0 — FROZEN, CONTRACT-BASED)
CORE DEFINITION (NON-NEGOTIABLE)

UI is a passive presentation + input routing layer.

UI never owns gameplay state, never decides flow, and never computes gameplay logic.

UI exists ONLY to:

Render state coming from managers
Route player input to managers
Control UI visibility and transitions
Play UI animations
LAYER CLARIFICATION (CRITICAL — NO CONFUSION ALLOWED)

There are TWO UIManagers in the full architecture, and they are NOT duplicates:

1. scripts/managers/UIManager.gd (GAMEPLAY COORDINATOR)
   Owns UI decisions at gameplay level
   Listens to SignalBus
   Decides WHAT UI should do
   Emits UI commands
2. scripts/ui/UIManager.gd (PRESENTATION ROOT)
   Owns UI scene structure
   Executes UI rendering and transitions
   Does NOT interpret gameplay events
   Only follows commands from UIEventBridge

✔ Relationship:
Managers decide → UI executes

NOT duplication. NOT overlap.

1. FOLDER STRUCTURE (LOCKED)
   scripts/ui/
   │
   ├── UIManager.gd
   ├── UIEventBridge.gd
   ├── HUDController.gd
   ├── ScreenController.gd
   ├── PopupController.gd
   ├── UIState.gd
   ├── UIAnimator.gd
   ├── UIInputRouter.gd
   │
   └── components/
   ├── LevelNodeUI.gd
   ├── CoinDisplay.gd
   ├── LifeDisplay.gd
   ├── StarDisplay.gd
   ├── StoryDialogueUI.gd
   ├── RewardPopupUI.gd
   ├── TutorialOverlayUI.gd
2. CORE DATA FLOW (ABSOLUTE CONTRACT)
   GAME STATE FLOW
   Managers
   ↓
   SignalBus
   ↓
   UIEventBridge
   ↓
   UI Controllers
   ↓
   UI Components
   INPUT FLOW
   Player Input
   ↓
   UIInputRouter
   ↓
   Managers (BoardManager / StoryManager / Menu logic)
3. UIEventBridge.gd (MANDATORY TRANSLATION LAYER)
   PURPOSE

Single interpreter between SignalBus and UI.

UIManager must NEVER interpret signals.

PUBLIC API
initialize()
bind_signals()
unbind_signals()
SIGNAL MAPPING (HARD CONTRACT)
SignalBus Event UI Action
level_started ScreenController.show(GAME)
level_completed PopupController.show(level_complete)
lives_changed HUDController.set_lives
coins_changed HUDController.set_coins
stars_changed HUDController.set_stars
story_started ScreenController.show(STORY)
dialogue_started StoryDialogueUI.show
reward_granted PopupController.show(reward)
tutorial_started ScreenController.lock_input
popup_requested PopupController.show 4. UIManager.gd (PRESENTATION ROOT)
PURPOSE

Top-level coordinator of UI presentation only.

RESPONSIBILITIES
Initialize UI subsystems
Hold references to UI controllers
Provide global UI control hooks
Delegate all behavior
PUBLIC API
initialize()
set_input_enabled(enabled: bool)
get_current_ui_state()
INTERNAL DEPENDENCIES
UIEventBridge
HUDController
ScreenController
PopupController
UIInputRouter
UIAnimator
UIState 5. HUDController.gd
PURPOSE

Manages always-visible UI layer.

OWNS ONLY:
Coins display
Lives display
Stars display
Boosters (visual only)
PUBLIC API
initialize()

set_coins(value)
set_lives(value)
set_stars(value)
set_boosters(data)

show()
hide()
RULES
No gameplay access
No economy access
Only reacts to UIEventBridge 6. ScreenController.gd
PURPOSE

Manages full-screen UI states.

SCREENS (LOCKED)
MENU
LEVEL_MAP
GAME
STORY
LOADING
SETTINGS
PUBLIC API
show(screen_id)
hide(screen_id)
get_active_screen()
RULES
Only one active screen at a time
Switching replaces previous screen completely 7. PopupController.gd
PURPOSE

Manages modal UI overlays.

POPUPS (LOCKED)
level_complete
level_failed
reward
shop
pause
confirmation
tutorial
PUBLIC API
show(type, data)
close_current()
close_all()
is_open()
RULES
Stack allowed
Only top popup receives input
Input blocking is automatic via UIInputRouter 8. UIState.gd
PURPOSE

Temporary UI-only memory.

ALLOWED STATE
active_screen
popup_stack
input_mode
tutorial_step
animation_flags
RULES
No gameplay data
No persistence
Reset on scene reload 9. UIAnimator.gd
PURPOSE

Handles ALL UI transitions.

PUBLIC API
play_screen_transition(from, to)
play_popup_open(type)
play_popup_close(type)
play_hud_update(element)
play_tutorial_highlight(node)
RULES
No logic decisions
No gameplay awareness
Pure animation execution only 10. UIInputRouter.gd
PURPOSE

Single authority for input routing.

INPUT MODES (LOCKED)
DISABLED
MENU
GAMEPLAY
STORY
TUTORIAL
BLOCKED
PUBLIC API
set_mode(mode)
get_mode()
handle_input(event)
ROUTING RULES
Mode Target
MENU ScreenController
GAMEPLAY BoardManager
STORY StoryManager
TUTORIAL Tutorial system
BLOCKED ignored
CRITICAL RULE

Any popup → forces BLOCKED mode.

11. COMPONENTS (PURE VISUAL NODES)
    RULES

Each component:

✔ ONLY renders UI
✔ ONLY receives updates from controllers
✘ NO SignalBus access
✘ NO manager access
✘ NO logic

EXAMPLE
CoinDisplay.gd
set_value(value)
animate_change() 12. FORBIDDEN OPERATIONS (HARD CONTRACT)

UI MUST NEVER:

Call ConfigLoader
Call ResourceManager directly
Compute gameplay values
Decide screen transitions based on logic
Store persistent data
Trigger gameplay systems directly
UI IS ONLY ALLOWED TO:
Display
Animate
Route input
Reflect state
Control visibility 13. FULL SYSTEM RELATIONSHIP MAP
GLOBAL ARCHITECTURE FLOW
Managers (Game Logic)
↓
SignalBus
↓
UIEventBridge
↓
UIManager (Presentation Root)
↓
┌─────────────────────────────┐
│ ScreenController │
│ PopupController │
│ HUDController │
└─────────────────────────────┘
↓
UI Components
↓
UIAnimator (transitions)
↓
UIState (temporary memory)
INPUT FLOW
Player Input
↓
UIInputRouter
↓
Game Managers 14. FINAL DEPENDENCY GRAPH (FROZEN)
SignalBus
↓
UIEventBridge
↓
UIManager (UI Layer Root)
↓
────────────────────────────
HUDController
ScreenController
PopupController
UIInputRouter
UIState
UIAnimator
────────────────────────────
↓
UI Components (pure visual)
FINAL STATEMENT (IMPORTANT)

This UI system is now:

✔ Layer-separated (no duplicate managers)
✔ Fully event-driven
✔ Strictly one-directional in flow
✔ Free of hidden coupling
✔ Compatible with all frozen manager APIs
