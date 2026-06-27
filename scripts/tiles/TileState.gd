extends RefCounted

class_name TileState


var tile_type: Constants.TileType = Constants.TileType.KEY
var grid_position: Vector2i = Vector2i.ZERO

var state: Constants.TileState = Constants.TileState.IDLE

var health: int = 1

var selected: bool = false
var matched: bool = false
var falling: bool = false
var locked: bool = false
var spawning: bool = false
var destroyed: bool = false

var powerup: Constants.PowerupType = Constants.PowerupType.NONE

var obstacle: Constants.ObstacleType = Constants.ObstacleType.NONE


func initialize(
	type: Constants.TileType,
	position: Vector2i
) -> void:
	tile_type = type
	grid_position = position

	reset_flags()


func reset_flags() -> void:
	state = Constants.TileState.IDLE

	selected = false
	matched = false
	falling = false
	locked = false
	spawning = false
	destroyed = false


func set_state(new_state: Constants.TileState) -> void:
	state = new_state


func get_state() -> Constants.TileState:
	return state


func set_position(position: Vector2i) -> void:
	grid_position = position


func get_position() -> Vector2i:
	return grid_position


func set_tile_type(type: Constants.TileType) -> void:
	tile_type = type


func get_tile_type() -> Constants.TileType:
	return tile_type


func set_powerup(type: Constants.PowerupType) -> void:
	powerup = type


func clear_powerup() -> void:
	powerup = Constants.PowerupType.NONE


func has_powerup() -> bool:
	return powerup != Constants.PowerupType.NONE


func set_obstacle(type: Constants.ObstacleType) -> void:
	obstacle = type


func clear_obstacle() -> void:
	obstacle = Constants.ObstacleType.NONE


func has_obstacle() -> bool:
	return obstacle != Constants.ObstacleType.NONE


func damage(amount: int = 1) -> void:
	health = max(0, health - amount)

	if health == 0:
		destroyed = true
		state = Constants.TileState.DESTROYING


func heal(amount: int = 1) -> void:
	health += amount


func is_destroyed() -> bool:
	return destroyed


func is_available() -> bool:
	return (
		not destroyed
		and not locked
		and state != Constants.TileState.DISABLED
	)


func duplicate_state() -> TileState:
	var copy := TileState.new()

	copy.tile_type = tile_type
	copy.grid_position = grid_position
	copy.state = state
	copy.health = health

	copy.selected = selected
	copy.matched = matched
	copy.falling = falling
	copy.locked = locked
	copy.spawning = spawning
	copy.destroyed = destroyed

	copy.powerup = powerup
	copy.obstacle = obstacle

	return copy