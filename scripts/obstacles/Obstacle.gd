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
var _overlay_size := 0.0
var _health_label: Label

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
	_update_health_label()
	if _animation_player != null:
		_animation_player.stop()


# =========================================================
# STATE
# =========================================================

func get_obstacle_state() -> ObstacleState:
	return _state


func set_obstacle_state(state: ObstacleState) -> void:
	_state = state
	_update_health_label()


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
	_update_health_label()


func heal(amount: int) -> void:
	if _state == null:
		return
	_state.heal(amount)
	_update_health_label()


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


func reset_modulate() -> void:
	if _sprite:
		_sprite.modulate = Color(1, 1, 1, 0.24 if _overlay_size > 0 else 1.0)


func configure_board_overlay(cell_size: float, reinforced := false) -> void:
	# Fade only the covering artwork. Keep the small identity/health badges solid
	# so the tile underneath is readable without hiding the obstacle itself.
	_overlay_size = cell_size - 8.0
	var texture := get_texture()
	if texture != null:
		_sprite.scale = Vector2.ONE * (_overlay_size / maxf(texture.get_width(), texture.get_height()))
	reset_modulate()
	var badge := Sprite2D.new()
	badge.name = "BlockerBadge"
	badge.texture = texture
	if texture != null:
		badge.scale = Vector2.ONE * (cell_size * 0.30 / maxf(texture.get_width(), texture.get_height()))
	badge.position = Vector2(-cell_size * 0.29, cell_size * 0.29)
	add_child(badge)
	_health_label = Label.new()
	_health_label.name = "BlockerHealth"
	_health_label.position = Vector2(cell_size * 0.14, -cell_size * 0.47)
	_health_label.size = Vector2(cell_size * 0.30, cell_size * 0.26)
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_health_label.add_theme_font_size_override("font_size", maxi(12, roundi(cell_size * 0.22)))
	_health_label.add_theme_color_override("font_color", Color("#fff4ad"))
	_health_label.add_theme_color_override("font_outline_color", Color("#281b30"))
	_health_label.add_theme_constant_override("outline_size", 3)
	add_child(_health_label)
	_update_health_label()
	if reinforced:
		var seal := Label.new()
		seal.text = "SEAL"
		seal.position = Vector2(-cell_size * 0.14, cell_size * 0.22)
		seal.add_theme_font_size_override("font_size", maxi(9, roundi(cell_size * 0.16)))
		seal.add_theme_color_override("font_color", Color("#fff4ad"))
		seal.add_theme_color_override("font_outline_color", Color("#281b30"))
		seal.add_theme_constant_override("outline_size", 2)
		add_child(seal)
	queue_redraw()


func _update_health_label() -> void:
	if is_instance_valid(_health_label) and _state != null:
		_health_label.text = str(_state.get_health())


func _draw() -> void:
	if _overlay_size > 0:
		draw_rect(Rect2(Vector2.ONE * -_overlay_size * 0.5, Vector2.ONE * _overlay_size), Color(0.94, 0.72, 0.30, 0.9), false, 2.0)


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
