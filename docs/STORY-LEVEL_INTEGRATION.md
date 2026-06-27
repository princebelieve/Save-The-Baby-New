Save The Baby
Levels & Story Integration Guide (Version 1.0 Freeze)
Purpose

This document defines the relationship between:

levels/
stories/
LevelManager
StoryManager
RewardManager
SaveManager
UIManager

It freezes the gameplay flow between the Match-3 engine, story system, tutorial system, rewards, and level map.

No manager should contain hardcoded knowledge of specific levels or story events.

Everything is driven by JSON data.

Core Philosophy

Levels contain gameplay.

Stories contain narrative.

Tutorials teach gameplay.

The Level Map represents player progression.

Managers coordinate these systems but never hardcode their content.

Overall Gameplay Flow

Every level follows the same lifecycle.

Level Selected
        │
        ▼
Load Level JSON
        │
        ▼
Request Before-Level Story (Optional)
        │
        ▼
StoryManager
        │
        ▼
Story Finished
        │
        ▼
        │
        ▼
GameManager
        │
        ├── Return to Level Map
        ├── Start Gameplay
        ├── Load Another Story
        └── Show Credits
Request Tutorial (Optional)
        │
        ▼
Tutorial Finished
        │
        ▼
BoardManager Generates Board
        │
        ▼
Gameplay
        │
        ▼
Victory / Failure
Failure Flow
Level Failed
        │
        ▼
Lose Life
        │
        ▼
Show Failure Screen
        │
        ▼
Retry
OR
Return To Map

No story is played after failure unless explicitly configured in future versions.

Victory Flow
Level Completed
        │
        ▼
Finish Remaining Move Bonus
        │
        ▼
Calculate Final Score
        │
        ▼
Calculate Stars
        │
        ▼
Grant Rewards
        │
        ▼
Save Progress
        │
        ▼
Unlock Next Level
        │
        ▼
Play "After Level" Story (Optional)
        │
        ▼
Return To Level Map
Level Map

The level map is the player's navigation screen.

It is not responsible for gameplay.

It only displays information already stored in SaveManager.

Each node displays:

Locked
Unlocked
Completed
Star Rating
First Try Badge (optional)
Perfect Badge (optional)

Selecting a node requests:

LevelManager.load_level(level_id)
Remaining Move Bonus

When objectives are completed before all moves are used:

Remaining Moves
        │
        ▼
RewardManager
        │
        ▼
Bonus Score
        │
        ▼
Celebration Animation

The celebration may include:

Rockets
Bombs
Thunder
Random explosions

These animations are visual only.

RewardManager determines the bonus.

AnimationManager performs the animation.

Stars

Stars are awarded after completion.

Stars depend on configurable score thresholds.

Example:

1 Star

5000

2 Stars

10000

3 Stars

15000

Thresholds should come from configuration.

They must never be hardcoded.

Coins

Coins are calculated by RewardManager.

Example:

Base Reward

100

+

Remaining Move Bonus

20

+

First Try Bonus

50

+

Perfect Bonus

100

=

270 Coins

Future reward types may include:

Boosters
Unlimited Lives
Story Rewards
Treasure Chests
Unlocking Levels

After a successful completion:

Highest Completed Level

↓

Highest Unlocked Level

↓

SaveManager

Only SaveManager stores progression.

The map reads it.

Story Integration

Levels never contain dialogue.

Stories never contain gameplay.

Levels only reference story scenes.

Example:

"story":
{
    "before_level": "intro_scene_01",
    "after_level": "intro_scene_02",
    "first_clear": "intro_scene_03",
    "return_to_map": true
}

Meaning:

before_level

Story plays every time before gameplay.

after_level

Story plays every successful completion.

first_clear

Story plays only once after the player's first victory.

return_to_map

If true:

Story

↓

Map

If false:

Story

↓

Another Story

↓

Credits

↓

Map

Useful for the ending sequence.

Tutorial Integration

Tutorial definitions belong to levels.

LevelManager loads the tutorial data.

UIManager presents the tutorial.

BoardManager receives gameplay input after tutorial completion.

Tutorial behaviour is entirely data-driven.

Example:

"tutorial":
{
    "enabled": true,
    "play_once": true,
    "steps":
    [
        ...
    ]
}

play_once

If true:

SaveManager remembers completion.

Tutorial never plays again unless progress is reset.

Tutorial Step Types

Every tutorial step has a type.

Supported Version 1 types:

MESSAGE

Display tutorial text.

HIGHLIGHT_TILE

Highlight one board tile.

HIGHLIGHT_TILES

Highlight multiple tiles.

HIGHLIGHT_UI

Highlight a HUD element.

POINT_ARROW

Display an animated arrow.

LOCK_INPUT

Disable unrelated player input.

UNLOCK_INPUT

Restore input.

WAIT_FOR_INPUT

Wait for player tap.

WAIT_FOR_SWIPE

Wait for player swipe.

WAIT_FOR_MATCH

Wait until a required match occurs.

WAIT_FOR_POWERUP

Wait until a specified powerup is created.

WAIT_FOR_OBJECTIVE

Wait until an objective progresses.

PLAY_ANIMATION

Play a scripted animation.

COMPLETE

Finish the tutorial.

Example Tutorial
"tutorial":
{
    "enabled": true,
    "play_once": true,
    "steps":
    [
        {
            "type":"MESSAGE",
            "text":"Swipe these tiles to make a match."
        },

        {
            "type":"HIGHLIGHT_TILES",
            "tiles":
            [
                {"x":3,"y":4},
                {"x":4,"y":4}
            ]
        },

        {
            "type":"LOCK_INPUT"
        },

        {
            "type":"WAIT_FOR_MATCH",
            "required_match":3
        },

        {
            "type":"UNLOCK_INPUT"
        },

        {
            "type":"COMPLETE"
        }
    ]
}

No tutorial logic should be hardcoded into the engine.

Story Schedule

Story progression follows gameplay milestones.

Recommended Version 1 schedule:

Opening Story

↓

Level 1

↓

Tutorial Story

↓

Levels 2–5

↓

Story Scene

↓

Levels 6–10

↓

Story Scene

↓

Levels 11–15

↓

Story Scene

↓

Continue every five levels

↓

Level 50

↓

Final Story

↓

Ending

↓

Credits

The engine never assumes "every five levels."

Only the JSON determines whether a story plays.

First-Time Events

Certain events should only happen once.

Examples:

Opening tutorial
First Rocket
First Bomb
First Thunder
First Obstacle
First Story Choice
First Daily Reward

The responsible system emits a SignalBus event.

SaveManager records the completion and saves the updated progress.

Future replays skip them automatically.

Responsibilities
LevelManager
Loads level JSON.
Starts gameplay.
Ends gameplay.
Requests stories.
Never owns dialogue.
StoryManager
Loads story JSON.
Plays scenes.
Processes choices.
Emits story events.
Never owns gameplay.
RewardManager
Calculates score.
Calculates stars.
Calculates coins.
Calculates bonuses.
Never saves progression.
SaveManager

Stores:

Highest unlocked level
Highest completed level
Story progress
Tutorial completion
First-clear events
Stars
Rewards
Player economy
UIManager

Displays:

Level Map
Victory Screen
Failure Screen
Story UI
Tutorial UI
Reward UI
Version 1 Rules

Levels contain gameplay only.

Stories contain narrative only.

Tutorials contain teaching sequences only.

The level map displays progression only.

RewardManager calculates rewards only.

SaveManager stores progression only.

Managers communicate through SignalBus.

No level-specific gameplay, tutorial, reward, or story logic may be hardcoded into scripts.

Every new level should be created by adding a JSON file only.

Every new story chapter should be created by adding a JSON file only.

Every new tutorial should be created by editing level JSON only.

This document freezes the interaction between the Level, Story, Tutorial, Reward, Save, and Map systems for Version 1.