extends Node2D
class_name Obstacle

# =========================================================
# SIGNALS
# =========================================================

signal pressed(obstacle)
signal released(obstacle)
signal clicked(obstacle)


# =========================================================
# INTERNAL STATE
# =========================================================

var _state: ObstacleState
var _behavior: ObstacleBehavior = null
var _pending_texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _init() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	add_child(sprite)
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	add_child(animation_player)


func _ready() -> void:
	if _pending_texture != null:
		_sprite.texture = _pending_texture


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(type, grid_position: Vector2i) -> void:
	_state = ObstacleState.new()
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

func get_obstacle_state() -> ObstacleState:
	return _state


func set_obstacle_state(state: ObstacleState) -> void:
	_state = state


func duplicate_obstacle_state() -> ObstacleState:
	if _state == null:
		return null
	return _state.duplicate_state()

# =========================================================
# BEHAVIOR
# =========================================================

func set_behavior(behavior: ObstacleBehavior) -> void:
	_behavior = behavior


func get_behavior() -> ObstacleBehavior:
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

func set_obstacle_type(type) -> void:
	if _state != null:
		_state.set_obstacle_type(type)


func get_obstacle_type():
	if _state == null:
		return null
	return _state.get_obstacle_type()


# =========================================================
# HEALTH
# =========================================================

func damage(amount: int) -> void:
	if _state == null:
		return
	_state.damage(amount)


func heal(amount: int) -> void:
	if _state == null:
		return
	_state.heal(amount)


func is_destroyed() -> bool:
	if _state == null:
		return false
	return _state.is_destroyed()


# =========================================================
# LOCK
# =========================================================

func lock() -> void:
	if _state != null:
		_state.set_locked(true)


func unlock() -> void:
	if _state != null:
		_state.set_locked(false)


func is_locked() -> bool:
	if _state == null:
		return false
	return _state.is_locked()


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
	_pending_texture = texture
	if _sprite:
		_sprite.texture = texture


func get_texture() -> Texture2D:
	if _sprite:
		return _sprite.texture
	return null


func set_modulate(color: Color) -> void:
	if _sprite:
		_sprite.modulate = color


func reset_modulate() -> void:
	if _sprite:
		_sprite.modulate = Color(1, 1, 1, 1)


# =========================================================
# ANIMATION
# =========================================================

func request_animation(name: String) -> void:
	# PURE REQUEST ONLY (no gameplay logic)
	if _animation_player and _animation_player.has_animation(name):
		_animation_player.play(name)


func is_animation_playing() -> bool:
	return _animation_player and _animation_player.is_playing()


# =========================================================
# INPUT HOOKS (VISUAL LAYER ONLY)
# =========================================================

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			pressed.emit(self)
		else:
			released.emit(self)

		if event.double_click:
			clicked.emit(self)
