extends Node
class_name PortraitManager

##
## PortraitManager.gd
##
## Purpose:
## Controls character portraits shown during dialogue.
##

# =========================================================
# SIGNALS
# =========================================================
signal character_shown(character: String)
signal character_hidden(character: String)
signal expression_changed(character: String, expression: String)
signal position_changed(character: String, position)
signal flip_changed(character: String, enabled: bool)
signal animation_played(character: String, animation_name: String)
signal animation_stopped(character: String)


# =========================================================
# INTERNAL STATE
# =========================================================
var _characters: Dictionary = {}
var _is_initialized: bool = false


# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	if _is_initialized:
		return

	_characters.clear()
	_is_initialized = true


func reset() -> void:
	clear()


# =========================================================
# PORTRAIT CONTROL
# =========================================================
func show_character(character: String) -> void:
	if not _characters.has(character):
		_characters[character] = {}

	_characters[character]["visible"] = true

	character_shown.emit(character)
	SignalBus.portrait_shown.emit(character)


func hide_character(character: String) -> void:
	if _characters.has(character):
		_characters[character]["visible"] = false

	character_hidden.emit(character)
	SignalBus.portrait_hidden.emit(character)


func change_expression(character: String, expression: String) -> void:
	if not _characters.has(character):
		_characters[character] = {}

	_characters[character]["expression"] = expression

	expression_changed.emit(character, expression)
	SignalBus.portrait_expression_changed.emit(character, expression)


func set_position(character: String, position) -> void:
	if not _characters.has(character):
		_characters[character] = {}

	_characters[character]["position"] = position

	position_changed.emit(character, position)
	SignalBus.portrait_position_changed.emit(character, position)


func flip(character: String, enabled: bool) -> void:
	if not _characters.has(character):
		_characters[character] = {}

	_characters[character]["flipped"] = enabled

	flip_changed.emit(character, enabled)
	SignalBus.portrait_flip_changed.emit(character, enabled)


# =========================================================
# ANIMATION
# =========================================================
func play_animation(character: String, animation_name: String) -> void:
	if not _characters.has(character):
		_characters[character] = {}

	_characters[character]["animation"] = animation_name

	animation_played.emit(character, animation_name)
	SignalBus.portrait_animation_played.emit(character, animation_name)


func stop_animation(character: String) -> void:
	if _characters.has(character):
		_characters[character]["animation"] = ""

	animation_stopped.emit(character)
	SignalBus.portrait_animation_stopped.emit(character)


# =========================================================
# UTILITY
# =========================================================
func clear() -> void:
	_characters.clear()


func reset_state() -> void:
	clear()