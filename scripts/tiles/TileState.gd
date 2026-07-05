extends RefCounted
class_name TileState

# =========================================================
# INTERNAL STATE
# =========================================================

var _tile_type: Constants.TileType
var _grid_position: Vector2i = Vector2i.ZERO
var _state: Constants.TileState = Constants.TileState.IDLE

var _powerup = null
var _obstacle = null

var _health: int = 1

var _selected: bool = false
var _matched: bool = false
var _falling: bool = false
var _locked: bool = false
var _hidden: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(tile_type: Constants.TileType, grid_position: Vector2i) -> void:
	_tile_type = tile_type
	_grid_position = grid_position
	_state = Constants.TileState.IDLE

	_powerup = null
	_obstacle = null

	_health = 1

	reset_flags()


func reset() -> void:
	_tile_type = Constants.TileType.KEY
	_grid_position = Vector2i.ZERO
	_state = Constants.TileState.IDLE

	_powerup = null
	_obstacle = null

	_health = 1

	reset_flags()


func duplicate_state() -> TileState:
	var copy := TileState.new()

	copy._tile_type = _tile_type
	copy._grid_position = _grid_position
	copy._state = _state

	copy._powerup = _powerup
	copy._obstacle = _obstacle

	copy._health = _health

	copy._selected = _selected
	copy._matched = _matched
	copy._falling = _falling
	copy._locked = _locked
	copy._hidden = _hidden

	return copy


# =========================================================
# IDENTITY
# =========================================================

func set_tile_type(type: Constants.TileType) -> void:
	_tile_type = type


func get_tile_type() -> Constants.TileType:
	return _tile_type


# =========================================================
# GRID
# =========================================================

func set_position(position: Vector2i) -> void:
	_grid_position = position


func get_position() -> Vector2i:
	return _grid_position


# =========================================================
# TILE STATE
# =========================================================

func set_state(state: Constants.TileState) -> void:
	_state = state


func get_state() -> Constants.TileState:
	return _state


func is_state(state: Constants.TileState) -> bool:
	return _state == state


# =========================================================
# POWERUP
# =========================================================

func set_powerup(type: Constants.PowerupType) -> void:
	_powerup = type


func get_powerup():
	return _powerup


func has_powerup() -> bool:
	return _powerup != null


func clear_powerup() -> void:
	_powerup = null


# =========================================================
# OBSTACLE
# =========================================================

func set_obstacle(type: Constants.ObstacleType) -> void:
	_obstacle = type


func get_obstacle():
	return _obstacle


func has_obstacle() -> bool:
	return _obstacle != null


func clear_obstacle() -> void:
	_obstacle = null


# =========================================================
# HEALTH
# =========================================================

func set_health(value: int) -> void:
	_health = max(0, value)


func get_health() -> int:
	return _health


func damage(amount: int) -> void:
	set_health(_health - amount)


func heal(amount: int) -> void:
	set_health(_health + amount)


func is_destroyed() -> bool:
	return _health <= 0


# =========================================================
# FLAGS
# =========================================================

func set_selected(value: bool) -> void:
	_selected = value


func is_selected() -> bool:
	return _selected


func set_matched(value: bool) -> void:
	_matched = value


func is_matched() -> bool:
	return _matched


func set_falling(value: bool) -> void:
	_falling = value


func is_falling() -> bool:
	return _falling


func set_locked(value: bool) -> void:
	_locked = value


func is_locked() -> bool:
	return _locked


func set_hidden(value: bool) -> void:
	_hidden = value


func is_hidden() -> bool:
	return _hidden


func reset_flags() -> void:
	_selected = false
	_matched = false
	_falling = false
	_locked = false
	_hidden = false