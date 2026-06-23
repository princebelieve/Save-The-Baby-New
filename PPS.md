Phase 0.5 – Professional Project Setup

This is a one-time setup that should take about 30–60 minutes.

Step 1 — Create the GitHub Repository

Create a new repository.

Repository name:

save-the-baby

Visibility:

I recommend Private while we're developing.

You can make it public later.

Initialize with:

README ✔
.gitignore ❌ (Godot will generate one or we'll add the appropriate one ourselves)
License ❌ (we'll decide later)
Step 2 — Install Software

Please make sure you have:

Latest stable Godot 4.x (preferably 4.4+ if available)
VS Code
Git
GitHub Desktop (optional but beginner-friendly)
Step 3 — Create the Godot Project

Create:

SaveTheBaby

Location:

Documents/Godot/SaveTheBaby

Renderer:

Forward+

Version Control:

We'll connect it after the project is created.

Step 4 — Open in VS Code

From this point onward,

VS Code becomes our programming workspace.

Godot becomes our:

Scene editor
Animation editor
Inspector
Testing environment

That's a workflow many Godot developers use successfully.

Then comes something very important.
Step 5 — Create the Folder Structure

Don't worry about adding files yet.

Just create the folders exactly as below:

SaveTheBaby/

addons/

assets/
│
├── audio/
│ ├── music/
│ └── sfx/
│
├── fonts/
│
├── sprites/
│ ├── backgrounds/
│ ├── characters/
│ ├── effects/
│ ├── obstacles/
│ ├── powerups/
│ ├── tiles/
│ └── ui/

configs/

docs/

exports/

levels/

resources/
│
├── obstacles/
│
├── powerups/
│
└── tiles/

save/

scenes/
│
├── board/
├── boot/
├── game/
├── level/
├── menu/
├── popup/
├── reward/
├── story/
├── tutorial/
└── ui/

scripts/
│
├── animation/
├── board/
├── economy/
├── managers/
├── obstacles/
├── powerups/
├── save/
├── story/
├── tiles/
├── ui/
└── utilities/

stories/

tests/

This is the structure we'll use for the lifetime of the project.

Step 6 — The Managers

We are going to make one architectural improvement.

Instead of having managers scattered around the project...

We'll have one dedicated place:

scripts/managers/

Eventually, this folder will contain:

game_manager.gd

board_manager.gd

level_manager.gd

reward_manager.gd

story_manager.gd

audio_manager.gd

save_manager.gd

ui_manager.gd

animation_manager.gd

economy_manager.gd

Notice something.

Every important system has ONE manager.

That makes debugging much easier.

Step 7 — Git

Now initialize Git.

Make your first commit.

Initial project structure

Then push it to GitHub.

What I Will Do

This is where our partnership really starts.

From the next session onward, I will:

Design every major system.
Write almost all the GDScript.
Review architecture continuously.
Refactor when necessary.
Help debug errors.
Keep everything data-driven.

You'll mainly:

Create the files and folders I specify.
Paste the code I provide.
Run and test the project.
Tell me what happens.
Import assets when we need them.
Something I'd like to add

There is one feature I didn't mention earlier that I think will make this feel much more professional.

We're going to build developer tools into the game from the beginning.

For example:

F1

↓

Developer Menu

Inside it:

Jump to Level

Give Coins

Unlock All Levels

Infinite Moves

Infinite Lives

Spawn Any Powerup

Reload Current Level

Show FPS

Show Grid Coordinates

Clear Save Data

Test Story Scene

Professional studios build tools for themselves because they dramatically speed up testing. We should do the same instead of tapping through dozens of levels every time we want to verify a feature.

Finally...

I want to make one promise about this project.

I don't want to build just another Match-3 game.

I want to build a Match-3 engine that could realistically power several games. Save The Baby will simply be the first game built on top of it.

That mindset influences every architectural decision we'll make.

Our first coding milestone

Once you've completed the setup above, our next milestone will be writing the first lines of code.

We'll start with the Board Engine, because everything else—matching, power-ups, obstacles, scoring, objectives, and story progression—depends on it.

And here's another promise: I won't give you a giant wall of code. We'll build it in small, testable pieces. Every script we write will compile, be tested, and become part of a solid foundation before we move on. By the time we reach the story, we'll have an engine we can trust. I think that's the fastest path to finishing a polished game rather than accumulating technical debt.
