PART 1 — The REAL ROLE OF UI (important correction first)

UI is NOT a system like board or economy.

UI is:

A pure presentation layer + input forwarding layer

It does only 3 things:

Displays state
Sends player input upward
Listens to SignalBus events

❌ UI must NOT:

calculate rewards
decide level flow
run gameplay logic
own state (except temporary UI state like animations)

✔ UI ONLY reflects reality coming from managers

PART 2 — FINAL scripts/ui API MAP (VERSION 1.0 FROZEN)
Folder Structure (LOCKED)
scripts/ui/
│
├── UIManager.gd
├── HUDController.gd
├── ScreenController.gd
├── PopupController.gd
├── UIState.gd
├── UIAnimator.gd
├── UIInputRouter.gd
└── components/
├── LevelNodeUI.gd
├── CoinDisplay.gd
├── LifeDisplay.gd
├── StarDisplay.gd
├── StoryDialogueUI.gd
├── RewardPopupUI.gd
└── TutorialOverlayUI.gd

1. UIManager.gd (ROOT UI COORDINATOR)
   Purpose

Single entry point for all UI systems.

Responsibilities
Controls HUD / Screens / Popups
Subscribes to SignalBus
Routes state updates to UI modules
Never contains UI logic itself
Public API
initialize()
show_screen(screen_id)
hide_screen(screen_id)

show_popup(popup_id, data)
hide_popup(popup_id)

update_hud(state)

set_input_enabled(value)
Listens to SignalBus:
level_started
level_completed
economy_changed
lives_changed
story_started
story_ended
reward_granted
tutorial_started
tutorial_step_changed 2. HUDController.gd
Purpose

Manages always-visible UI (top/bottom bars)

Owns:
coins
lives
stars
boosters (display only)
Public API
initialize()

update_coins(value)
update_lives(value)
update_stars(value)
update_boosters(data)

show()
hide() 3. ScreenController.gd
Purpose

Controls full-screen UI states

Screens:
MENU
LEVEL_MAP
GAME
STORY
LOADING
SETTINGS
Public API
show_screen(screen_id)
hide_screen(screen_id)
get_active_screen()
Rule:

Only ONE screen active at a time (except HUD)

4. PopupController.gd
   Purpose

Manages modal overlays

Popups:
level_complete
level_failed
reward
shop
pause
confirmation
Public API
show_popup(type, data)
close_popup()
close_all()
is_popup_open() 5. UIState.gd
Purpose

Stores transient UI state ONLY

Not save data.

Examples:

active screen
active popup
tutorial highlight index
animation states 6. UIAnimator.gd
Purpose

Handles ONLY UI animations

Uses scripts/animation framework

Public API
play_screen_transition(from, to)
play_popup_open(popup)
play_popup_close(popup)
play_hud_update(element)
play_tutorial_highlight(node) 7. UIInputRouter.gd
Purpose

Routes player input to correct system

Example behavior:
If popup open → block board input
If tutorial active → restrict input
If gameplay → send to BoardManager
Public API
set_input_mode(mode)

MODES:

- DISABLED
- MENU
- GAMEPLAY
- STORY
- TUTORIAL
  PART 3 — scenes/ui STRUCTURE (FULL FREEZE)

Now we connect scripts/ui → scenes/ui

Folder:
scenes/ui/
│
├── UIRoot.tscn
├── HUD.tscn
├── screens/
│ ├── MenuScreen.tscn
│ ├── LevelMapScreen.tscn
│ ├── GameScreen.tscn
│ ├── StoryScreen.tscn
│ ├── LoadingScreen.tscn
│ └── SettingsScreen.tscn
│
├── popups/
│ ├── LevelCompletePopup.tscn
│ ├── LevelFailedPopup.tscn
│ ├── RewardPopup.tscn
│ ├── PausePopup.tscn
│ └── ShopPopup.tscn
│
└── components/
├── CoinDisplay.tscn
├── LifeDisplay.tscn
├── StarDisplay.tscn
├── TutorialOverlay.tscn
└── DialogueBox.tscn
PART 4 — CRITICAL CONNECTION RULE (THIS REMOVES ALL AMBIGUITY)

This is the missing contract you were asking for.

UI ↔ Manager Flow (FINAL TRUTH)

1. Managers NEVER talk to scenes directly

They only do:

SignalBus.emit("level_completed", data) 2. UIManager listens ONLY to SignalBus

Example:

on_level_completed → PopupController.show("level_complete")
on_lives_changed → HUDController.update_lives()
on_story_started → ScreenController.show("story") 3. Scenes NEVER talk to managers

Scenes only:

emit UI signals (button pressed)
call UIInputRouter

Example:

Play Button pressed →
UIInputRouter → GameManager.start_level()
PART 5 — FULL SYSTEM CONNECTION MAP

Now everything connects cleanly:

GAME FLOW INTO UI
BoardManager
↓
SignalBus: level_completed
↓
UIManager
↓
PopupController
↓
LevelCompletePopup.tscn
↓
UIAnimator plays transition
STORY FLOW INTO UI
StoryManager
↓
SignalBus: story_started
↓
UIManager
↓
ScreenController → STORY SCREEN
↓
DialogueBox UI
ECONOMY INTO UI
EconomyManager
↓
SignalBus: coins_changed
↓
HUDController
↓
CoinDisplay.tscn
INPUT FLOW
Player input
↓
UIInputRouter
↓
IF GAMEPLAY → BoardManager
IF MENU → MenuScreen
IF STORY → StoryManager
IF BLOCKED → ignore
PART 6 — ASSETS CONNECTION (your last question)
assets/ is NEVER accessed by UI directly

Instead:

Correct chain:
UI Component (CoinDisplay.tscn)
↓
CoinDisplay.gd
↓
ResourceManager
↓
assets/sprites/ui/coin.png

Same for everything:

fonts → HUD text
sfx → UIAnimator
sprites → UI components
music → AudioManager (not UI)
PART 7 — FINAL SUMMARY (NO AMBIGUITY VERSION)
You now have 3 locked layers:

1. scripts/ui (LOGIC CONTROLLERS)
   UIManager
   HUDController
   ScreenController
   PopupController
   InputRouter
2. scenes/ui (VISUAL LAYER)
   HUD.tscn
   screens/_
   popups/_
   components/\*
3. SignalBus (CONNECTOR)

The ONLY bridge:

Managers → SignalBus → UIManager → Scenes
Scenes → UIInputRouter → Managers
