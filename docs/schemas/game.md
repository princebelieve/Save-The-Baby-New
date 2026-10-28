# Game configuration schema

`configs/game.json` contains global project metadata, runtime limits, and feature switches used by managers. It must remain data only.

`max_levels` is `0` for an open-ended campaign. A positive value is a known end-of-campaign limit. This allows Version 1's opening 50 levels to grow without setting 50 as a permanent ceiling.

`max_lives`, `max_moves`, and `minimum_match` are positive gameplay limits. `target_fps`, `target_physics_fps`, `save_version`, and `build_number` are non-negative integers. Feature switches are booleans.
