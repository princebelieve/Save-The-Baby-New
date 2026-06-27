resources/
Resources System API Map (Version 1.0 Freeze)

The resources/ folder contains reusable Godot Resource (.tres) assets used throughout the project.

Resources are data assets only.

Resources contain no executable code.

Resources contain no gameplay logic.

Resources contain no runtime state.

Resources are loaded only through ResourceManager.gd.

Configuration files may reference resource paths but never load resources directly.

Folder Structure
resources/

├── tiles/
│   ├── key.tres
│   ├── phone.tres
│   ├── fingerprint.tres
│   ├── recorder.tres
│   ├── clock.tres
│   ├── opened_door.tres
│   └── ...
│
├── powerups/
│   ├── rocket.tres
│   ├── bomb.tres
│   └── thunder.tres
│
└── obstacles/
    ├── chain.tres
    ├── lock.tres
    ├── tape.tres
    ├── missile.tres
    ├── bomb.tres
    └── electric_trap.tres
resources/tiles/
Purpose

Stores reusable tile resources.

Each tile resource may contain asset references such as:

Texture
Icon
Material
Shader
Particle Resources
Animation Resources

Tile resources contain no gameplay values.

Gameplay configuration belongs in configs/tiles.json.

resources/powerups/
Purpose

Stores reusable powerup resources.

Each powerup resource may contain:

Texture
Icon
Material
Shader
Particle Resources
Animation Resources

Powerup behavior is defined by the Powerup System and configuration files.

resources/obstacles/
Purpose

Stores reusable obstacle resources.

Each obstacle resource may contain:

Texture
Icon
Material
Shader
Particle Resources
Animation Resources

Obstacle gameplay is defined by the Obstacle System and configuration files.

ResourceManager Integration

All resources are loaded through ResourceManager.gd.

Public API

initialize()

load_resource(path)

reload_resource(path)

unload_resource(path)

has(path)

get(path)

clear()

clear_unused()
Frozen Dependency Graph
configs/*.json
       │
       ▼
 ConfigLoader
       │
       ▼
 Gameplay Subsystems
       │
       ▼
 ResourceManager
       │
       ▼
 resources/
 ├── tiles/
 ├── powerups/
 └── obstacles/
Responsibilities
Folder	Responsibility
resources/tiles	Stores reusable tile assets
resources/powerups	Stores reusable powerup assets
resources/obstacles	Stores reusable obstacle assets
ResourceManager	Loads, caches, reloads and unloads resources
Version 1 Rules
Resources contain reusable Godot assets only.
Resources contain no executable code.
Resources contain no gameplay logic.
Resources contain no runtime state.
Resources are loaded exclusively through ResourceManager.
Configuration files may reference resource paths but never load resources directly.
Gameplay configuration belongs in the configs/ folder.
Runtime state belongs to gameplay objects (Tile, Powerup, Obstacle).
Managers and gameplay systems never load resources directly; they access them through ResourceManager.

This API freezes the resources/ folder for Version 1.