# SAVE THE BABY

# Project Roadmap & Milestone Guide

Version 1.0

---

# Project Goal

Build a commercial-quality, story-driven Match-3 puzzle game using Godot with a modular, scalable, data-driven architecture.

This roadmap defines the exact order in which the project will be developed.

No milestone should begin until the previous milestone is stable.

---

# PHASE 0 – Project Foundation

Objective:
Create a professional project structure before writing gameplay code.

Deliverables

✓ Create Godot project

✓ Configure Git repository

✓ Configure VS Code

✓ Create folder structure

✓ Configure project settings

✓ Create README

✓ Add .gitignore

✓ Add coding standards

✓ Create placeholder assets

✓ Verify project builds successfully

Files

project.godot

README.md

.gitignore

docs/

assets/

scripts/

scenes/

configs/

levels/

stories/

No gameplay yet.

---

# PHASE 1 – Core Engine

Objective

Build the Match-3 engine.

Deliverables

Grid generation

Board generation

Tile spawning

Tile movement

Tile swapping

Swap validation

Prevent illegal moves

Basic animations

Files

Board.tscn

Tile.tscn

board_manager.gd

tile.gd

board_config.gd

Status

Engine only.

No objectives.

No scoring.

No rewards.

---

# PHASE 2 – Match Detection

Objective

Detect every valid match.

Deliverables

Horizontal matches

Vertical matches

L shapes

T shapes

Square matches

Multiple simultaneous matches

Files

match_detector.gd

match_result.gd

Tests

Every possible pattern.

---

# PHASE 3 – Board Resolution

Objective

Resolve matches.

Deliverables

Destroy tiles

Gravity

Refill

Cascade

Repeat until stable

Animations

Particle effects

Files

gravity_system.gd

spawn_system.gd

cascade_system.gd

No objectives yet.

---

# PHASE 4 – Level System

Objective

Load levels from JSON.

Deliverables

Level loader

Move counter

Win conditions

Lose conditions

Restart

Next level

Files

level_manager.gd

level_loader.gd

level001.json

level002.json

Goal

Every level should load entirely from data.

---

# PHASE 5 – Objectives

Objective

Support multiple objective types.

Examples

Collect Keys

Collect Phones

Collect Fingerprints

Destroy Bombs

Break Chains

Unlock Doors

Score Target

Timer

Deliverables

Objective engine

HUD

Progress updates

Completion detection

Files

objective_manager.gd

objective.gd

---

# PHASE 6 – Scoring

Objective

Create rewarding gameplay.

Deliverables

Points

Combo multiplier

Cascade bonus

Remaining moves bonus

Star calculation

Three-star rating

Files

score_manager.gd

star_system.gd

---

# PHASE 7 – Powerups

Objective

Professional Match-3 mechanics.

Powerups

Rocket

Bomb

Thunder

Rocket + Rocket

Bomb + Rocket

Bomb + Bomb

Thunder + Bomb

Thunder + Thunder

Files

powerup_manager.gd

rocket.gd

bomb_power.gd

thunder.gd

---

# PHASE 8 – Obstacles

Objective

Introduce challenge gradually.

Order

Chains

Locks

Tape

Bombs

Missiles

Pinchers

Pliers

Electric traps

Deliverables

Obstacle framework

Obstacle animations

Obstacle health

Obstacle interactions

Files

obstacle_manager.gd

---

# PHASE 9 – Story System

Objective

Connect gameplay with narrative.

Deliverables

Dialogue system

Portraits

Backgrounds

Choices

Story progression

JSON dialogue loader

Files

story_manager.gd

dialogue_box.tscn

story_loader.gd

chapter01.json

---

# PHASE 10 – User Interface

Objective

Professional menus.

Screens

Splash

Loading

Main Menu

Settings

Level Select

Pause

Victory

Game Over

Reward

Shop

Files

ui_manager.gd

menu_manager.gd

---

# PHASE 11 – Economy

Objective

Player progression.

Systems

Coins

Lives

Boosters

Shops

Treasure chests

Lucky wheel

Daily rewards

Files

economy_manager.gd

reward_manager.gd

shop_manager.gd

---

# PHASE 12 – Save System

Objective

Persistent progress.

Save

Coins

Lives

Boosters

Story

Levels

Achievements

Statistics

Settings

Deliverables

Autosave

Manual save

Load

Version migration support

Files

save_manager.gd

save_game.gd

---

# PHASE 13 – Audio

Objective

Complete sound design.

Music

Sound effects

Button sounds

Voice effects (future)

Volume settings

Files

audio_manager.gd

---

# PHASE 14 – Animation

Objective

Professional polish.

Tile animations

Particles

Victory effects

Powerups

Story transitions

UI transitions

Files

animation_manager.gd

---

# PHASE 15 – Tutorials

Objective

Teach without overwhelming.

Deliverables

First level tutorial

Powerup tutorials

Obstacle tutorials

Story hints

Hint system

Files

tutorial_manager.gd

---

# PHASE 16 – Polish

Objective

Improve quality.

Tasks

Performance

Memory

Accessibility

Balancing

Bug fixing

Optimization

Touch controls

Responsive UI

---

# PHASE 17 – Android

Objective

Mobile release.

Tasks

Export presets

Icons

Splash screen

Permissions

Performance testing

Different screen sizes

Play Store assets

---

# PHASE 18 – Release Candidate

Objective

Feature complete.

Checklist

No crashes

No blockers

All levels playable

Story complete

Save works

Rewards work

Ads (if included) work

Stable performance

---

# PHASE 19 – Version 1.0

Deliverables

50 handcrafted levels

Story Chapter 1

Boss battle

Factory rescue

Achievements (basic)

Coins

Lives

Powerups

Professional UI

Android release

Windows release

---

# Version 1.1+

Possible updates

50 more levels

New villain

Seasonal events

Cloud saves

Localization

Leaderboards

Daily challenges

Additional obstacles

Additional powerups

New environments

---

# Development Rules

Never skip milestones.

Never build features out of order.

Always test before continuing.

Always refactor when necessary.

Document major systems.

Keep code modular.

Prefer configuration over hardcoding.

Commit frequently to Git.

---

# Milestone Completion Checklist

Every milestone is complete only when:

✓ Feature works

✓ Code reviewed

✓ No critical bugs

✓ No unnecessary hardcoding

✓ JSON/config support added where appropriate

✓ Project builds

✓ Existing features still work

✓ Git commit completed

✓ Development log updated

Only then should development proceed to the next milestone.

---

# Conversation Workflow with ChatGPT

At the start of a new chat:

1. State the current milestone (for example, "We are on Phase 4 – Level System").
2. Mention any architectural changes since the roadmap (if any).
3. Share only the files relevant to the task, if needed.
4. Describe the goal for this session.

ChatGPT will then:

* Review the milestone.
* Explain the implementation approach.
* Write or update the required code.
* Help test and debug it.
* Keep the implementation aligned with the architecture and previous decisions.

This workflow minimizes repeated context, keeps conversations focused, and allows the project to progress in small, stable increments.
