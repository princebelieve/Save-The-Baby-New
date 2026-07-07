extends Node
class_name ObstacleAnimator

# =========================================================
# INTERNAL STATE
# =========================================================

var _active_tweens: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_active_tweens.clear()


# =========================================================
# BASIC ANIMATIONS
# =========================================================

func play_spawn(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)
	obstacle.scale = Vector2(0.5, 0.5)

	tween.tween_property(obstacle, "scale", Vector2(1, 1), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	_active_tweens[obstacle] = tween


func play_damage(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(obstacle, "modulate", Color(1, 1, 1), 0.1)

	_active_tweens[obstacle] = tween


func play_destroy(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "scale", Vector2(0, 0), 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	tween.tween_callback(Callable(self, "_on_destroy_finished").bind(obstacle))

	_active_tweens[obstacle] = tween


func play_unlock(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "modulate", Color(0.8, 0.8, 1), 0.15)
	tween.tween_property(obstacle, "modulate", Color(1, 1, 1), 0.15)

	_active_tweens[obstacle] = tween


func play_activate(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(obstacle, "scale", Vector2(1, 1), 0.1)

	_active_tweens[obstacle] = tween


func play_deactivate(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "modulate", Color(0.6, 0.6, 0.6), 0.2)

	_active_tweens[obstacle] = tween


func play_shake(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	var original_pos = obstacle.position

	tween.tween_property(obstacle, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(obstacle, "position", original_pos + Vector2(-4, 0), 0.05)
	tween.tween_property(obstacle, "position", original_pos, 0.05)

	_active_tweens[obstacle] = tween


func play_highlight(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	_finish_animation(obstacle)

	var tween = _create_tween(obstacle)

	tween.tween_property(obstacle, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	tween.tween_property(obstacle, "modulate", Color(1, 1, 1), 0.1)

	_active_tweens[obstacle] = tween


# =========================================================
# UTILITY
# =========================================================

func stop(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	if _active_tweens.has(obstacle):
		var tween = _active_tweens[obstacle]
		if tween:
			tween.kill()

		_active_tweens.erase(obstacle)


func stop_all() -> void:
	for obstacle in _active_tweens.keys():
		var tween = _active_tweens[obstacle]
		if tween:
			tween.kill()

	_active_tweens.clear()


func pause(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	if _active_tweens.has(obstacle):
		var tween = _active_tweens[obstacle]
		if tween:
			tween.pause()


func resume(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	if _active_tweens.has(obstacle):
		var tween = _active_tweens[obstacle]
		if tween:
			tween.play()


func is_playing(obstacle: Obstacle) -> bool:
	return obstacle != null and _active_tweens.has(obstacle)


func wait_until_finished(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	while _active_tweens.has(obstacle):
		await get_tree().process_frame


# =========================================================
# INTERNAL
# =========================================================

func _create_tween(obstacle: Obstacle) -> Tween:
	var tween = obstacle.create_tween()
	tween.set_parallel(false)
	tween.finished.connect(func():
		_finish_animation(obstacle)
	)
	return tween


func _finish_animation(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	if _active_tweens.has(obstacle):
		_active_tweens.erase(obstacle)


func _on_destroy_finished(obstacle: Obstacle) -> void:
	if obstacle == null:
		return

	obstacle.queue_free()