extends Node
class_name Constants

# =========================================================
# PROJECT METADATA (ENGINE IDENTITY ONLY)
# =========================================================

const GAME_NAME: String = "Save The Baby"
const VERSION: String = "1.0.0"

# NOTE:
# SAVE_VERSION and BUILD_NUMBER are duplicated in Version.gd,
# but Constants keeps runtime-safe read-only mirrors for convenience.

const SAVE_VERSION: int = 1
const BUILD_NUMBER: int = 1


# =========================================================
# PERFORMANCE / ENGINE BEHAVIOR (NOT GAME BALANCE)
# =========================================================

const TARGET_FPS: int = 60


# =========================================================
# SCENE PATHS
# =========================================================

class ScenePaths:
	const BOOT: String = "res://scenes/boot/Boot.tscn"
	const GAME: String = "res://scenes/game/Game.tscn"
	const BOARD: String = "res://scenes/board/Board.tscn"
	const MAIN_MENU: String = "res://scenes/menu/MainMenu.tscn"
	const LEVEL_SELECT: String = "res://scenes/menu/LevelSelect.tscn"
	const STORY: String = "res://scenes/story/StoryScene.tscn"
	const UI_ROOT: String = "res://scenes/ui/UIRoot.tscn"


# =========================================================
# CONFIG PATHS
# =========================================================

class ConfigPaths:
	const GAME: String = "res://configs/game.json"
	const LEVELS: String = "res://configs/levels.json"
	const TILES: String = "res://configs/tiles.json"
	const POWERUPS: String = "res://configs/powerups.json"
	const OBSTACLES: String = "res://configs/obstacles.json"
	const OBJECTIVES: String = "res://configs/objectives.json"
	const REWARDS: String = "res://configs/rewards.json"
	const ECONOMY: String = "res://configs/economy.json"
	const STORY: String = "res://configs/story.json"
	const AUDIO: String = "res://configs/audio.json"
	const UI: String = "res://configs/ui.json"
	const ANIMATION: String = "res://configs/animation.json"
	const BOARD: String = "res://configs/board.json"
	const EFFECTS: String = "res://configs/effects.json"
	const DEBUG: String = "res://configs/debug.json"


# =========================================================
# SAVE PATHS
# =========================================================

class SavePaths:
	const SAVE_DIR: String = "user://save/"
	const MAIN_SAVE_FILE: String = "user://save/save_data.json"


# =========================================================
# RESOURCE PATHS
# =========================================================

class ResourcePaths:
	const TILE_SPRITES: String = "res://assets/sprites/tiles/"
	const UI_SPRITES: String = "res://assets/sprites/ui/"
	const POWERUP_SPRITES: String = "res://assets/sprites/powerups/"
	const OBSTACLE_SPRITES: String = "res://assets/sprites/obstacles/"
	const AUDIO_MUSIC: String = "res://assets/audio/music/"
	const AUDIO_SFX: String = "res://assets/audio/sfx/"


# =========================================================
# NODE GROUPS
# =========================================================

class Groups:
	const TILES: String = "tiles"
	const BOARD: String = "board"
	const MANAGERS: String = "managers"
	const UI: String = "ui"


# =========================================================
# PHYSICS LAYERS (ENGINE STRUCTURE ONLY)
# =========================================================

class Layers:
	const TILE: int = 1
	const OBSTACLE: int = 2
	const UI: int = 3


# =========================================================
# ENUMS (ENGINE CONTRACTS ONLY)
# These MUST NOT contain balancing values.
# Only identity/type definitions.
# =========================================================

enum GameState {
	BOOT,
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	VICTORY,
	GAME_OVER
}

enum BoardState {
	IDLE,
	PROCESSING,
	SWAPPING,
	MATCHING,
	CASCADING,
	SHUFFLING,
	STABLE
}

enum TileType {
	KEY,
	PHONE,
	FINGERPRINT,
	RECORDER,
	TAPE,
	CLOCK,
	CHAIN,
	LOCK,
	BOMB,
	MISSILE,
	PINCHER,
	PLIER,
	ROCKET,
	THUNDER,
	BOMB_POWER
}

enum PowerupType {
	ROCKET,
	BOMB,
	THUNDER
}

enum PowerupCombo {
	ROCKET_ROCKET,
	ROCKET_BOMB,
	BOMB_BOMB,
	THUNDER_BOMB,
	THUNDER_THUNDER
}

enum ObstacleType {
	CHAIN,
	LOCK,
	TAPE,
	BOMB,
	MISSILE,
	ELECTRIC_TRAP
}

enum ObjectiveType {
	COLLECT,
	DESTROY,
	UNLOCK,
	SCORE,
	TIMER,
	RESCUE
}

enum RewardType {
	COINS,
	STARS,
	CHEST,
	BOOSTER,
	LIVES
}

enum BoosterType {
	HAMMER,
	SWAP,
	BOMB,
	ROCKET
}

enum MatchPattern {
	HORIZONTAL,
	VERTICAL,
	L_SHAPE,
	T_SHAPE,
	SQUARE
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum AudioBus {
	MUSIC,
	SFX,
	UI,
	VOICE
}

enum Difficulty {
	EASY,
	MEDIUM,
	HARD,
	BOSS
}