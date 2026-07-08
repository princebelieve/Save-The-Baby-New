extends Node2D
class_name Powerup

# =========================================================
# SIGNALS
# =========================================================

signal pressed(powerup)
signal released(powerup)
signal clicked(powerup)


# =========================================================
# INTERNAL STATE
# =========================================================

var _state: PowerupState
var _behavior: PowerupBehavior = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


# =========================================================
# INITIALIZATION
# =========================================================

func _ready() -> void:
	if _state == null:
		_state = PowerupState.new()


func initialize(type, grid_position: Vector2i) -> void:
	if _state == null:
		_state = PowerupState.new()

	_state.initialize(type, grid_position)


func reset() -> void:
	if _state != null:
	    _state.reset()

    if _behavior != null:
	    _behavior.reset()

    reset_modulate()

    if _animation_player != null:
	    _animation_player.stop()


# =========================================================
# STATE
# =========================================================

func get_powerup_state() -> PowerupState:
	return _state


func set_powerup_state(state: PowerupState) -> void:
	_state = state


func duplicate_powerup_state() -> PowerupState:
	if _state == null:
		return null

	return _state.duplicate_state()

# =========================================================
# BEHAVIOR
# =========================================================

func set_behavior(behavior: PowerupBehavior) -> void:
	_behavior = behavior

	if _behavior != null:
		_behavior.initialize(self)


func get_behavior() -> PowerupBehavior:
	return _behavior


func has_behavior() -> bool:
	return _behavior != null


# =========================================================
# GRID
# =========================================================

func set_grid_position(position: Vector2i) -> void:
	if _state != null:
		_state.set_position(position)


func get_grid_position() -> Vector2i:
	if _state == null:
		return Vector2i.ZERO

	return _state.get_position()


# =========================================================
# IDENTITY
# =========================================================

func set_powerup_type(type) -> void:
	if _state != null:
		_state.set_powerup_type(type)


func get_powerup_type():
	if _state == null:
		return null

	return _state.get_powerup_type()


# =========================================================
# ACTIVATION
# =========================================================

func activate() -> void:
	if _state != null:
		_state.set_active(true)


func deactivate() -> void:
	if _state != null:
		_state.set_active(false)


func is_active() -> bool:
	if _state == null:
		return false

	return _state.is_active()


# =========================================================
# VISIBILITY
# =========================================================

func show() -> void:
	visible = true


func hide() -> void:
	visible = false


func set_visible(value: bool) -> void:
	visible = value


# =========================================================
# VISUAL
# =========================================================

func set_texture(texture: Texture2D) -> void:
	if _sprite != null:
		_sprite.texture = texture


func get_texture() -> Texture2D:
	if _sprite == null:
		return null

	return _sprite.texture


func set_modulate(color: Color) -> void:
	modulate = color


func reset_modulate() -> void:
	modulate = Color.WHITE


# =========================================================
# ANIMATION
# =========================================================

func request_animation(name: String) -> void:
	if _animation_player == null:
		return

	if _animation_player.has_animation(name):
		_animation_player.play(name)


func is_animation_playing() -> bool:
	if _animation_player == null:
		return false

	return _animation_player.is_playing()