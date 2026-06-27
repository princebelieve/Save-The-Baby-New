extends Node

# --------------------------------------------------
# Constants.gd (Version 1.0 Freeze)
#
# Global constants + enumerations only.
#
# Rules:
# - No functions
# - No gameplay logic
# - No state mutation
# - Pure data definitions only
# --------------------------------------------------


# =========================
# Project Constants
# =========================
const GAME_NAME: String = "Save The Baby"
const VERSION: String = "1.0"
const TARGET_FPS: int = 60

const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 8

const MAX_LEVEL: int = 1000
const MAX_LIVES: int = 5
const LIFE_REGEN_SECONDS: int = 1800


# =========================
# Paths
# =========================
class ScenePaths:
	const GAME: String = "res://scenes/game/Game.tscn"
	const BOOT: String = "res://scenes/boot/Boot.tscn"
	const LOADING: String = "res://scenes/boot/Loading.tscn"


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
	const LOCALIZATION: String = "res://configs/localization.json"
	const DEBUG: String = "res://configs/debug.json"


class SavePaths:
	const SAVE_FILE: String = "user://save.dat"
	const BACKUP_FILE: String = "user://save_backup.dat"


class ResourcePaths:
	const TEXTURES: String = "res://assets/textures/"
	const AUDIO: String = "res://assets/audio/"
	const FONTS: String = "res://assets/fonts/"
	const ANIMATIONS: String = "res://assets/animations/"
	const SCENES: String = "res://scenes/"


# =========================
# Node Groups
# =========================
class NodeGroups:
	const TILE: String = "tile"
	const BOARD: String = "board"
	const UI: String = "ui"
	const MANAGER: String = "manager"


# =========================
# Physics Layers
# =========================
class PhysicsLayers:
	const TILE: int = 1
	const OBSTACLE: int = 2
	const BOARD: int = 4


# =========================
# Enums
# =========================

enum GameState {
	BOOT,
	INITIALIZING,
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}


enum BoardState {
	IDLE,
	CREATING,
	READY,
	LOCKED,
	RESOLVING,
	CLEARED
}


enum TileState {
	IDLE,
	MOVING,
	FALLING,
	LANDED,
	DESTROYED
}


enum TileType {
	RED,
	BLUE,
	GREEN,
	YELLOW,
	PURPLE,
	SPECIAL
}


enum PowerupType {
	NONE,
	BOMB,
	ROCKET,
	RAINBOW
}


enum PowerupCombo {
	NONE,
	BOMB_BOMB,
	BOMB_ROCKET,
	ROCKET_ROCKET
}


enum ObstacleType {
	WOOD,
	ICE,
	STONE,
	CHAIN
}


enum ObjectiveType {
	COLLECT_TILES,
	SCORE_POINTS,
	DESTROY_OBSTACLES,
	CLEAR_BOARD
}


enum RewardType {
	COINS,
	STARS,
	BOOSTERS,
	LIVES
}


enum BoosterType {
	HAMMER,
	SWAP,
	BOMB
}


enum StoryTrack {
	INTRO,
	CHAPTER_1,
	CHAPTER_2,
	ENDING
}


enum Character {
	BABY,
	MOTHER,
	FATHER,
	NARRATOR
}


enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	HARDCORE
}


enum MatchPattern {
	THREE,
	FOUR,
	FIVE,
	L_SHAPE,
	T_SHAPE
}


enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}


enum AudioBus {
	MASTER,
	MUSIC,
	SFX,
	UI
}