extends Node
class_name TileAnimator

# =========================================================
# INTERNAL STATE
# =========================================================

var _active_tweens: Dictionary = {}
var _paused: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_active_tweens.clear()
	_paused = false


# =========================================================
# BASIC ANIMATIONS
# =========================================================

func play_idle(tile: Tile) -> void:
	if tile == null:
		return


func play_spawn(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tile.scale = Vector2.ZERO
	tween.tween_property(tile, "scale", Vector2.ONE, 0.25)

	_finish_animation(tile, tween)


func play_destroy(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)

	tween.tween_property(tile, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func():
		tile.hide()
	)

	_finish_animation(tile, tween)


func play_fall(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "position", tile.position, 0.15)

	_finish_animation(tile, tween)


func play_swap(tile_a: Tile, tile_b: Tile) -> void:
	if tile_a == null or tile_b == null:
		return

	var tween_a = _create_tween(tile_a)
	var tween_b = _create_tween(tile_b)

	var pos_a = tile_a.position
	var pos_b = tile_b.position

	tween_a.tween_property(tile_a, "position", pos_b, 0.2)
	tween_b.tween_property(tile_b, "position", pos_a, 0.2)

	_finish_animation(tile_a, tween_a)
	_finish_animation(tile_b, tween_b)


func play_move(tile: Tile, position: Vector2) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "position", position, 0.2)

	_finish_animation(tile, tween)


func play_bounce(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)

	tween.tween_property(tile, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.1)

	_finish_animation(tile, tween)


func play_shake(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)

	var original_pos = tile.position

	tween.tween_property(tile, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(tile, "position", original_pos + Vector2(-4, 0), 0.05)
	tween.tween_property(tile, "position", original_pos, 0.05)

	_finish_animation(tile, tween)


func play_highlight(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)

	tween.tween_property(tile, "modulate", Color(1, 1, 0.8), 0.1)
	tween.tween_property(tile, "modulate", Color.WHITE, 0.1)

	_finish_animation(tile, tween)


# =========================================================
# SELECTION
# =========================================================

func play_select(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "scale", Vector2(1.15, 1.15), 0.1)

	_finish_animation(tile, tween)


func play_deselect(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.1)

	_finish_animation(tile, tween)


# =========================================================
# POWERUPS
# =========================================================

func play_powerup_create(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "modulate", Color(0.5, 1, 0.5), 0.15)

	_finish_animation(tile, tween)


func play_powerup_activate(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)

	tween.tween_property(tile, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(tile, "scale", Vector2.ZERO, 0.2)

	_finish_animation(tile, tween)


func play_powerup_combo(tile_a: Tile, tile_b: Tile) -> void:
	play_destroy(tile_a)
	play_destroy(tile_b)


# =========================================================
# OBSTACLES
# =========================================================

func play_obstacle_damage(tile: Tile) -> void:
	if tile == null:
		return

	var tween = _create_tween(tile)
	tween.tween_property(tile, "modulate", Color(1, 0.5, 0.5), 0.1)

	_finish_animation(tile, tween)


func play_obstacle_break(tile: Tile) -> void:
	play_destroy(tile)


# =========================================================
# UTILITY
# =========================================================

func stop(tile: Tile) -> void:
	if tile == null:
		return

	if _active_tweens.has(tile):
		_active_tweens[tile].kill()
		_active_tweens.erase(tile)


func stop_all() -> void:
	for tween in _active_tweens.values():
		tween.kill()

	_active_tweens.clear()


func pause(tile: Tile) -> void:
	if tile == null:
		return

	if _active_tweens.has(tile):
		_active_tweens[tile].set_pause_mode(true)


func resume(tile: Tile) -> void:
	if tile == null:
		return

	if _active_tweens.has(tile):
		_active_tweens[tile].set_pause_mode(false)


func is_playing(tile: Tile) -> bool:
	return _active_tweens.has(tile)


func wait_until_finished(tile: Tile) -> void:
	while _active_tweens.has(tile):
		await get_tree().process_frame


# =========================================================
# INTERNAL
# =========================================================

func _create_tween(tile: Tile) -> Tween:
	var tween = create_tween()
	_active_tweens[tile] = tween
	return tween


func _finish_animation(tile: Tile, tween: Tween) -> void:
	if tween == null:
		return

	tween.finished.connect(func():
		if _active_tweens.get(tile) == tween:
			_active_tweens.erase(tile)
	)