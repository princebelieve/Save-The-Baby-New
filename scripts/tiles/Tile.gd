extends Node2D

class_name Tile


signal clicked(tile: Tile)
signal pressed(tile: Tile)
signal released(tile: Tile)


@export var tile_size: int = 96


var state: TileState = TileState.new()

var sprite: Sprite2D
var animation_player: AnimationPlayer
var area: Area2D
var collision: CollisionShape2D


func _ready() -> void:
	_create_nodes()
	_update_visual_position()


# ==========================================================
# INITIALIZATION
# ==========================================================

func initialize(
	tile_type: Constants.TileType,
	grid_position: Vector2i
) -> void:
	state.initialize(tile_type, grid_position)
	_update_visual_position()


# ==========================================================
# NODE CREATION
# ==========================================================

func _create_nodes() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)

	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)

	if area == null:
		area = Area2D.new()
		area.name = "Area2D"
		add_child(area)

	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"

		var shape := RectangleShape2D.new()
		shape.size = Vector2(tile_size, tile_size)

		collision.shape = shape

		area.add_child(collision)

	if not area.input_event.is_connected(_on_input_event):
		area.input_event.connect(_on_input_event)


# ==========================================================
# GRID POSITION
# ==========================================================

func set_grid_position(position: Vector2i) -> void:
	state.set_position(position)
	_update_visual_position()


func get_grid_position() -> Vector2i:
	return state.get_position()


func _update_visual_position() -> void:
	position = Vector2(
		state.grid_position.x * tile_size,
		state.grid_position.y * tile_size
	)


# ==========================================================
# TILE TYPE
# ==========================================================

func set_tile_type(type: Constants.TileType) -> void:
	state.set_tile_type(type)


func get_tile_type() -> Constants.TileType:
	return state.get_tile_type()


# ==========================================================
# STATE
# ==========================================================

func set_state(new_state: Constants.TileState) -> void:
	state.set_state(new_state)


func get_state() -> Constants.TileState:
	return state.get_state()


func is_idle() -> bool:
	return get_state() == Constants.TileState.IDLE


func is_selected() -> bool:
	return state.selected


func select() -> void:
	state.selected = true
	set_state(Constants.TileState.SELECTED)


func deselect() -> void:
	state.selected = false
	set_state(Constants.TileState.IDLE)


# ==========================================================
# MATCH
# ==========================================================

func mark_matched() -> void:
	state.matched = true
	set_state(Constants.TileState.MATCHED)


func clear_match() -> void:
	state.matched = false

	if get_state() == Constants.TileState.MATCHED:
		set_state(Constants.TileState.IDLE)


func is_matched() -> bool:
	return state.matched


# ==========================================================
# FALLING
# ==========================================================

func begin_fall() -> void:
	state.falling = true
	set_state(Constants.TileState.FALLING)


func end_fall() -> void:
	state.falling = false
	set_state(Constants.TileState.IDLE)


func is_falling() -> bool:
	return state.falling


# ==========================================================
# POWERUPS
# ==========================================================

func set_powerup(type: Constants.PowerupType) -> void:
	state.set_powerup(type)


func has_powerup() -> bool:
	return state.has_powerup()


func get_powerup() -> Constants.PowerupType:
	return state.powerup


func clear_powerup() -> void:
	state.clear_powerup()


# ==========================================================
# OBSTACLES
# ==========================================================

func set_obstacle(type: Constants.ObstacleType) -> void:
	state.set_obstacle(type)


func has_obstacle() -> bool:
	return state.has_obstacle()


func get_obstacle() -> Constants.ObstacleType:
	return state.obstacle


func clear_obstacle() -> void:
	state.clear_obstacle()


# ==========================================================
# HEALTH
# ==========================================================

func damage(amount: int = 1) -> void:
	state.damage(amount)


func heal(amount: int = 1) -> void:
	state.heal(amount)


func is_destroyed() -> bool:
	return state.is_destroyed()


# ==========================================================
# SPRITE
# ==========================================================

func set_texture(texture: Texture2D) -> void:
	sprite.texture = texture


func get_texture() -> Texture2D:
	return sprite.texture


# ==========================================================
# INPUT
# ==========================================================

func _on_input_event(
	_viewport,
	event,
	_shape_idx
) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			pressed.emit(self)
		else:
			released.emit(self)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed.emit(self)
			else:
				released.emit(self)

	elif event is InputEventScreenDrag:
		clicked.emit(self)


# ==========================================================
# RESET
# ==========================================================

func reset() -> void:
	state.reset_flags()


func duplicate_tile_state() -> TileState:
	return state.duplicate_state()
