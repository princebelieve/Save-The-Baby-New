# scenes/game/

# Scene API Map (Version 1.0 Freeze)

## Purpose

The Game Scene is the root gameplay scene.

It owns every gameplay subsystem during an active gameplay session.

It creates the permanent manager hierarchy.

It never contains gameplay logic.

Gameplay is coordinated entirely by the Manager System.

---

# Folder Structure

```text
scenes/
│
├── game/
│   ├── Game.tscn
│   ├── Managers.tscn
│   └── GameplayRoot.tscn
│
└── boot/
    ├── Boot.tscn
    └── Loading.tscn
```

---

# Legend

```text
()
= Godot node type

[]
= Attached script

◆
= Instanced scene

│ ├ └
= Parent / child hierarchy
```

---

# scenes/boot/

## Purpose

Responsible only for application startup.

### Responsibilities

* Initialize engine
* Initialize managers
* Load configuration
* Load save data
* Load the first scene

Never owns gameplay.

Never creates gameplay objects.

Never loads levels directly.

---

## Boot.tscn

```text
Boot (Node)
[Boot.gd]
│
└── ◆ Loading.tscn
```

---

## Loading.tscn

```text
LoadingScreen (Control)
│
├── Background (TextureRect)
├── LoadingBar (ProgressBar)
└── LoadingText (Label)
```

---

# scenes/game/

## Game.tscn

```text
Game (Node)
│
├── ◆ Managers.tscn
└── ◆ GameplayRoot.tscn
```

---

## Managers.tscn

```text
Managers (Node)
│
├── GameManager (Node)          [GameManager.gd]
├── BoardManager (Node)         [BoardManager.gd]
├── LevelManager (Node)         [LevelManager.gd]
├── RewardManager (Node)        [RewardManager.gd]
├── StoryManager (Node)         [StoryManager.gd]
├── AudioManager (Node)         [AudioManager.gd]
├── SaveManager (Node)          [SaveManager.gd]
├── UIManager (Node)            [UIManager.gd]
├── AnimationManager (Node)     [AnimationManager.gd]
└── EconomyManager (Node)       [EconomyManager.gd]
```

Managers communicate through SignalBus.

Managers never own gameplay scenes.

Managers persist for the lifetime of the gameplay session.

---

## GameplayRoot.tscn

```text
GameplayRoot (Node)
│
├── Board (Node)
├── HUD (CanvasLayer)
├── StoryLayer (CanvasLayer)
├── PopupLayer (CanvasLayer)
├── RewardLayer (CanvasLayer)
└── TransitionLayer (CanvasLayer)
```

These are scene containers.

Their respective managers instantiate and remove gameplay scenes as needed.

---

# Scene Ownership

```text
Boot.tscn
    │
    ▼
Game.tscn
    │
    ├── ◆ Managers.tscn
    │
    └── ◆ GameplayRoot.tscn
            │
            ├── Board
            ├── HUD
            ├── StoryLayer
            ├── PopupLayer
            ├── RewardLayer
            └── TransitionLayer
```

---

# Lifetime

### Boot

* Exists only during startup.
* Destroyed after `Game.tscn` loads.

### Managers

* Exist for the entire gameplay session.
* Never recreated during level transitions.

### GameplayRoot

* Exists for the entire gameplay session.
* Managers populate and clear its child containers as needed.

---

# Ownership Rules

* `Boot.tscn` initializes the game and loads `Game.tscn`.
* `Game.tscn` is the root scene for an active gameplay session.
* `Managers.tscn` contains only permanent manager nodes.
* `GameplayRoot.tscn` owns all gameplay scene containers.
* Managers coordinate scene creation but never become children of gameplay objects.
* Gameplay scenes never own managers.
* Managers persist across level transitions unless the game restarts completely.
* Visual gameplay content is created under `GameplayRoot`, never under `Managers`.

---

This Scene API Map defines only scene hierarchy, ownership, lifetime, and implementation blueprint.

Manager behavior remains defined exclusively by the frozen `scripts/managers/` API Map.