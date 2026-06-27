# SAVE THE BABY





Yes. After reviewing the entire frozen architecture and the dependency relationships between the scripts, I agree the original list was organized by folder, not by implementation order. Those are two different things.

For Version 1, the correct order is dependency-first. Every file should only depend on files that already exist.

Below is the order I recommend we follow from now until Version 1 is complete.

Phase 1 — Core Foundation

These have no dependencies.

1. Constants.gd
2. SignalBus.gd
3. Game.gd
4. JsonLoader.gd
5. RandomGenerator.gd
Phase 2 — Configuration System

Everything else reads configuration through these.

6. ConfigManager.gd
7. ResourceManager.gd
Phase 3 — Tile System

Everything on the board depends on tiles.

8. TileState.gd
9. Tile.gd
10. TileDatabase.gd
11. TileFactory.gd
12. TileAnimator.gd

After these five files exist, every system can create and manipulate tiles.

Phase 4 — Board Data Layer

Pure board storage.

13. BoardState.gd
14. BoardData.gd

No gameplay yet.

Phase 5 — Board Generation

Now we can actually build a board.

15. BoardGenerator.gd
16. BoardValidator.gd
17. BoardShuffle.gd

Reason:

Generator creates.

Validator verifies.

Shuffle repairs impossible boards.

Phase 6 — Match Engine

Core gameplay.

18. MatchFinder.gd
19. SwapValidator.gd
20. BoardGravity.gd
21. TileSpawner.gd
22. BoardRefill.gd
23. CascadeResolver.gd

Notice the order:

Find matches

↓

Validate moves

↓

Drop tiles

↓

Spawn new tiles

↓

Refill

↓

Resolve cascades

Phase 7 — Board Controller

Only now should the manager exist.

24. BoardManager.gd

At this point every dependency already exists.

BoardManager simply coordinates them.

Phase 8 — Level Management
25. LevelManager.gd

Uses BoardManager.

Loads JSON.

Starts gameplay.

Phase 9 — Input
26. InputManager.gd

Receives swipe.

Calls BoardManager.

Phase 10 — Game Management
27. GameManager.gd

Controls overall flow.

Boot

↓

Menu

↓

Story

↓

Gameplay

↓

Victory

↓

Game Over

Phase 11 — Powerups

Base first.

28. Powerup.gd
29. Rocket.gd
30. Bomb.gd
31. Thunder.gd
32. PowerupFactory.gd
33. CombinationResolver.gd
34. PowerupResolver.gd
Phase 12 — Obstacles

Base first.

35. Obstacle.gd
36. ObstacleFactory.gd
37. Chain.gd
38. Tape.gd
39. Lock.gd
40. Bomb.gd
41. Missile.gd
42. ElectricTrap.gd
Phase 13 — Economy / Rewards / Save
43. RewardManager.gd
44. SaveData.gd
45. Statistics.gd
46. Profile.gd
47. SaveManager.gd
Phase 14 — Audio
48. AudioManager.gd
Phase 15 — Story
49. DialoguePlayer.gd
50. PortraitManager.gd
51. ChoiceManager.gd
52. StoryManager.gd
Phase 16 — UI
53. HUD.gd
54. PauseMenu.gd
55. VictoryScreen.gd
56. GameOverScreen.gd
57. LoadingScreen.gd
58. UIManager.gd
Phase 17 — JSON Configuration Files
59. game.json
60. settings.json
61. audio.json
62. ui.json
63. economy.json
64. tiles.json
65. powerups.json
66. obstacles.json
67. animations.json
Phase 18 — Resources
68. TileData.tres
69. PowerupData.tres
70. ObstacleData.tres
Phase 19 — Story Files
71. intro.json
72. chapter01.json
73. chapter02.json
74. ending.json
Phase 20 — Levels
75. level001.json
76. level002.json
...
124. level050.json







# Architecture Freeze (Version 1.0)

Status: **LOCKED**

This document defines the frozen architecture for Version 1.0 of Save The Baby.

Once approved, this architecture will remain unchanged throughout Version 1 development unless:

* A critical bug requires modification.
* Godot itself requires a change.
* The project owner explicitly requests a change.

No architectural improvements or redesigns will be suggested during Version 1 development.

---

# 1. Project Goal

Develop a professional, modular, data-driven Match-3 engine that powers Save The Baby.

The engine must support future expansion without requiring major rewrites.

---

# 2. Folder Structure

The existing project folder structure is final.

No folders will be renamed or reorganized during Version 1.

---

# 3. Naming Convention

## Scenes

PascalCase

Examples:

Boot.tscn

Board.tscn

Tile.tscn

MainMenu.tscn

StoryScene.tscn

---

## Scripts

PascalCase

Examples:

Boot.gd

Tile.gd

BoardManager.gd

GameManager.gd

SaveManager.gd

StoryManager.gd

---

## Variables

snake_case

---

## Constants

UPPER_CASE

---

## Classes

PascalCase

---

# 4. Managers

All managers remain inside:

scripts/managers/

Each manager has one responsibility.

Examples:

GameManager

BoardManager

LevelManager

StoryManager

RewardManager

SaveManager

EconomyManager

AudioManager

AnimationManager

UIManager

AdsManager

Managers communicate through signals or public APIs.

Managers do not directly manipulate each other's internal data.

---

# 5. Scene Responsibilities

Each scene has one responsibility.

Examples:

Board.tscn

Responsible only for gameplay board presentation.

Tile.tscn

Represents one tile instance.

Boot.tscn

Initializes the game before loading the next scene.

Scenes do not perform responsibilities belonging to managers.

---

# 6. Tile Philosophy

Tile represents one game object.

Tile knows only:

* identity
* grid position
* visual state
* flags
* health

Tile does not perform:

* matching
* gravity
* scoring
* objectives
* player input
* cascades

Those responsibilities belong elsewhere.

---

# 7. Board Philosophy

Gameplay uses swipe-to-swap mechanics.

The engine is based on the interaction model used by games such as Candy Crush Saga and Royal Match.

There is no click-to-select gameplay.

Flow:

Player swipes

↓

BoardManager determines direction

↓

Adjacent tile selected automatically

↓

Swap attempted

↓

Move validated

↓

Accepted or reverted

---

# 8. Data-Driven Rule

Whenever practical, data comes from configuration files.

Examples:

levels

stories

tiles

obstacles

economy

settings

powerups

Adding content should require creating data, not modifying engine code.

---

# 9. Developer Tools

Developer tools are part of Version 1.

The Developer Menu will eventually provide functions such as:

* Jump to Level
* Infinite Lives
* Infinite Moves
* Give Coins
* Unlock Levels
* Spawn Tiles
* Spawn Obstacles
* Spawn Powerups
* Reload Current Level
* Story Viewer
* FPS Display
* Grid Coordinates
* Clear Save

These tools exist to speed up development and testing.

---

# 10. Development Workflow

Every milestone follows the same process.

1. Review milestone.
2. Implement code.
3. Test.
4. Fix bugs.
5. Commit.
6. Update development log.
7. Continue.

No new features are introduced before the current milestone is complete.

---

# 11. Version 1 Rule

During Version 1 development:

* No unsolicited architectural improvements.
* No unsolicited feature additions.
* No restructuring of existing systems.

Changes occur only when:

* requested by the project owner,
* required to fix a bug,
* or necessary because the frozen design cannot satisfy existing requirements.

This document remains the reference architecture for the entire Version 1 development cycle.
