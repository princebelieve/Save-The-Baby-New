extends RefCounted
class_name PowerupState

# =========================================================
# PURPOSE
# Stores the gameplay state for a single powerup.
#
# Responsibilities:
# - Powerup identity
# - Grid position
# - Runtime state
# - Runtime flags
#
# Contains:
# - No visual logic
# - No animation logic
# - No board logic
# - No gameplay coordination
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _powerup_type
var _grid_position: Vector2i = Vector2i.ZERO
var _state = null

var _active: bool = false
var _armed: bool = false
var _consumed: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(powerup_type, grid_position: Vector2i) -> void:
	_powerup_type = powerup_type
	_grid_position = grid_position
	_state = null

	reset_flags()


func reset() -> void:
	_powerup_type = null
	_grid_position = Vector2i.ZERO
	_state = null

	reset_flags()


func duplicate_state() -> PowerupState:
	var duplicate := PowerupState.new()

	duplicate._powerup_type = _powerup_type
	duplicate._grid_position = _grid_position
	duplicate._state = _state

	duplicate._active = _active
	duplicate._armed = _armed
	duplicate._consumed = _consumed

	return duplicate


# =========================================================
# IDENTITY
# =========================================================

func set_powerup_type(type) -> void:
	_powerup_type = type


func get_powerup_type():
	return _powerup_type


# =========================================================
# GRID
# =========================================================

func set_position(position: Vector2i) -> void:
	_grid_position = position


func get_position() -> Vector2i:
	return _grid_position


# =========================================================
# STATE
# =========================================================

func set_state(state) -> void:
	_state = state


func get_state():
	return _state


func is_state(state) -> bool:
	return _state == state


# =========================================================
# FLAGS
# =========================================================

func set_active(value: bool) -> void:
	_active = value


func is_active() -> bool:
	return _active


func set_armed(value: bool) -> void:
	_armed = value


func is_armed() -> bool:
	return _armed


func set_consumed(value: bool) -> void:
	_consumed = value


func is_consumed() -> bool:
	return _consumed


func reset_flags() -> void:
	_active = false
	_armed = false
	_consumed = false