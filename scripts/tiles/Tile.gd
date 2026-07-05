extends Node2D
class_name Tile

# =========================================================
# SIGNALS
# =========================================================

signal pressed(tile)
signal released(tile)
signal clicked(tile)
signal hover_entered(tile)
signal hover_exited(tile)

# =========================================================
# INTERNAL STATE
# =========================================================

var _state: TileState
var _input_enabled: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(tile_type, grid_position: Vector2i) -> void:
	if _state == null:
		_state = TileState.new()

	_state.initialize(tile_type, grid_position)


func reset() -> void:
	if _state != null:
		_state.reset()

	reset_tile_modulate()
	set_tile_visible(true)
	_input_enabled = true


# =========================================================
# TILE STATE
# =========================================================

func get_tile_state() -> TileState:
	return _state


func set_tile_state(state: TileState) -> void:
	_state = state


func duplicate_tile_state() -> TileState:
	return _state.duplicate_state() if _state != null else null


# =========================================================
# GRID
# =========================================================

func set_grid_position(position: Vector2i) -> void:
	_state.set_position(position)


func get_grid_position() -> Vector2i:
	return _state.get_position()


func move_to_grid(position: Vector2i) -> void:
	_state.set_position(position)


# =========================================================
# TILE TYPE
# =========================================================

func set_tile_type(type) -> void:
	_state.set_tile_type(type)


func get_tile_type():
	return _state.get_tile_type()


# =========================================================
# STATE
# =========================================================

func set_state(state) -> void:
	_state.set_state(state)


func get_state():
	return _state.get_state()


func is_idle() -> bool:
	return _state.is_state(Constants.TileState.IDLE)


# =========================================================
# SELECTION
# =========================================================

func select() -> void:
	_state.set_selected(true)


func deselect() -> void:
	_state.set_selected(false)


func is_selected() -> bool:
	return _state.is_selected()


# =========================================================
# MATCH
# =========================================================

func mark_matched() -> void:
	_state.set_matched(true)


func clear_match() -> void:
	_state.set_matched(false)


func is_matched() -> bool:
	return _state.is_matched()


# =========================================================
# FALLING
# =========================================================

func begin_fall() -> void:
	_state.set_falling(true)


func end_fall() -> void:
	_state.set_falling(false)


func is_falling() -> bool:
	return _state.is_falling()


# =========================================================
# LOCK
# =========================================================

func lock() -> void:
	_state.set_locked(true)


func unlock() -> void:
	_state.set_locked(false)


func is_locked() -> bool:
	return _state.is_locked()


# =========================================================
# POWERUPS
# =========================================================

func set_powerup(type) -> void:
	_state.set_powerup(type)


func get_powerup():
	return _state.get_powerup()


func has_powerup() -> bool:
	return _state.has_powerup()


func clear_powerup() -> void:
	_state.clear_powerup()


# =========================================================
# OBSTACLES
# =========================================================

func set_obstacle(type) -> void:
	_state.set_obstacle(type)


func get_obstacle():
	return _state.get_obstacle()


func has_obstacle() -> bool:
	return _state.has_obstacle()


func clear_obstacle() -> void:
	_state.clear_obstacle()


# =========================================================
# HEALTH
# =========================================================

func damage(amount: int) -> void:
	_state.damage(amount)


func heal(amount: int) -> void:
	_state.heal(amount)


func is_destroyed() -> bool:
	return _state.is_destroyed()


# =========================================================
# VISUAL (SAFE WRAPPERS)
# =========================================================

func set_texture(texture: Texture2D) -> void:
	if _sprite:
		_sprite.texture = texture


func get_texture() -> Texture2D:
	return _sprite.texture if _sprite else null


func set_tile_modulate(color: Color) -> void:
	modulate = color


func reset_tile_modulate() -> void:
	modulate = Color.WHITE


# IMPORTANT: renamed to avoid Godot override conflict
func set_tile_visible(value: bool) -> void:
	visible = value


func is_tile_visible() -> bool:
	return visible


# =========================================================
# ANIMATION REQUEST
# =========================================================

func request_animation(name: String) -> void:
	SignalBus.animation_manager.play(name, self)


func is_animation_playing() -> bool:
	return _animation_player != null and _animation_player.is_playing()


# =========================================================
# INPUT
# =========================================================

func enable_input() -> void:
	_input_enabled = true


func disable_input() -> void:
	_input_enabled = false


func is_input_enabled() -> bool:
	return _input_enabled


# =========================================================
# GODOT INPUT
# =========================================================

func _input_event(viewport, event, shape_idx) -> void:
	if not _input_enabled:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed.emit(self)
			else:
				released.emit(self)
				clicked.emit(self)


func _mouse_enter() -> void:
	if _input_enabled:
		hover_entered.emit(self)


func _mouse_exit() -> void:
	if _input_enabled:
		hover_exited.emit(self)
