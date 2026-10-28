extends Node
class_name GameAnimationLibrary

# =========================================================
# PURPOSE
# =========================================================
# Central registry of animation identifiers and default metadata.
#
# This file defines:
# - Animation names (single source of truth)
# - Optional default durations
# - Optional categorization helpers
#
# It contains NO animation logic.
# It does NOT perform animations.
# It ONLY defines identifiers used by AnimationManager
# and subsystem animators.

# =========================================================
# TILE ANIMATIONS
# =========================================================

const TILE_SPAWN: String = "tile_spawn"
const TILE_SWAP: String = "tile_swap"
const TILE_DESTROY: String = "tile_destroy"
const TILE_FALL: String = "tile_fall"
const TILE_BOUNCE: String = "tile_bounce"
const TILE_SHAKE: String = "tile_shake"
const TILE_HIGHLIGHT: String = "tile_highlight"


# =========================================================
# UI ANIMATIONS
# =========================================================

const UI_POPUP_OPEN: String = "popup_open"
const UI_POPUP_CLOSE: String = "popup_close"
const UI_BUTTON_PRESS: String = "button_press"
const UI_NOTIFICATION: String = "notification"
const UI_TRANSITION: String = "ui_transition"


# =========================================================
# REWARD ANIMATIONS
# =========================================================

const REWARD_COLLECT: String = "reward_collect"
const REWARD_POPUP: String = "reward_popup"


# =========================================================
# STORY ANIMATIONS
# =========================================================

const STORY_TRANSITION: String = "story_transition"
const STORY_DIALOGUE: String = "story_dialogue"
const STORY_PORTRAIT_ENTER: String = "portrait_enter"


# =========================================================
# OBSTACLE ANIMATIONS
# =========================================================

const OBSTACLE_BREAK: String = "obstacle_break"
const OBSTACLE_DAMAGE: String = "obstacle_damage"
const OBSTACLE_UNLOCK: String = "obstacle_unlock"


# =========================================================
# DEFAULT DURATIONS (OPTIONAL META LAYER)
# =========================================================

const DEFAULT_DURATION: Dictionary = {
	TILE_SPAWN: 0.2,
	TILE_SWAP: 0.15,
	TILE_DESTROY: 0.25,
	TILE_FALL: 0.2,
	TILE_BOUNCE: 0.1,

	UI_POPUP_OPEN: 0.2,
	UI_POPUP_CLOSE: 0.15,

	REWARD_COLLECT: 0.3,
	STORY_TRANSITION: 0.4
}


# =========================================================
# HELPER API
# =========================================================

static func get_default_duration(animation_name: String) -> float:
	if DEFAULT_DURATION.has(animation_name):
		return DEFAULT_DURATION[animation_name]

	return 0.2


static func is_tile_animation(name: String) -> bool:
	return name.begins_with("tile_")


static func is_ui_animation(name: String) -> bool:
	return name.begins_with("popup_") \
		or name.begins_with("ui_")


static func is_story_animation(name: String) -> bool:
	return name.begins_with("story_") \
		or name.begins_with("portrait_")


static func is_reward_animation(name: String) -> bool:
	return name.begins_with("reward_")


static func is_obstacle_animation(name: String) -> bool:
	return name.begins_with("obstacle_")
