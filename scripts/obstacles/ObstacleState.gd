extends RefCounted
class_name ObstacleState

# =========================================================
# INTERNAL STATE (FROZEN DATA ONLY)
# =========================================================

var _obstacle_type
var _grid_position: Vector2i
var _state
var _health: int = 0

var _locked: bool = false
var _hidden: bool = false
var _active: bool = true


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(obstacle_type, grid_position: Vector2i) -> void:
	_obstacle_type = obstacle_type
	_grid_position = grid_position
	_state = null
	_health = 0

	_locked = false
	_hidden = false
	_active = true


func reset() -> void:
	_state = null
	_health = 0

	_locked = false
	_hidden = false
	_active = true


func duplicate_state() -> ObstacleState:
	var copy := ObstacleState.new()
	copy._obstacle_type = _obstacle_type
	copy._grid_position = _grid_position
	copy._state = _state
	copy._health = _health

	copy._locked = _locked
	copy._hidden = _hidden
	copy._active = _active

	return copy


# =========================================================
# IDENTITY
# =========================================================

func set_obstacle_type(type) -> void:
	_obstacle_type = type


func get_obstacle_type():
	return _obstacle_type


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
# HEALTH
# =========================================================

func set_health(value: int) -> void:
	_health = max(0, value)


func get_health() -> int:
	return _health


func damage(amount: int) -> void:
	_health = max(0, _health - amount)


func heal(amount: int) -> void:
	if amount < 0:
		return
	_health += amount


func is_destroyed() -> bool:
	return _health <= 0


# =========================================================
# FLAGS
# =========================================================

func set_locked(value: bool) -> void:
	_locked = value


func is_locked() -> bool:
	return _locked


func set_hidden(value: bool) -> void:
	_hidden = value


func is_hidden() -> bool:
	return _hidden


func set_active(value: bool) -> void:
	_active = value


func is_active() -> bool:
	return _active


func reset_flags() -> void:
	_locked = false
	_hidden = false
	_active = true