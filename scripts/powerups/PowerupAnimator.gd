extends Node
class_name PowerupAnimator


# =========================================================
# PURPOSE
# Owns visual animations affecting powerups.
#
# Responsibilities:
# - Perform powerup-specific animations
# - Create tweens for powerup visuals
# - Control powerup animation playback
#
# Contains:
# - No gameplay logic
# - No board coordination
# - No animation scheduling
#
# AnimationManager decides WHEN.
# PowerupAnimator decides HOW.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _active_animations: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_active_animations.clear()


# =========================================================
# BASIC ANIMATIONS
# =========================================================

func play_create(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	powerup.set_modulate(Color(1, 1, 1, 0))
	powerup.scale = Vector2(0.5, 0.5)

	_active_animations[powerup] = tween

	tween.parallel().tween_property(
		powerup,
		"modulate",
		Color.WHITE,
		0.25
	)

	tween.parallel().tween_property(
		powerup,
		"scale",
		Vector2.ONE,
		0.25
	)

	tween.finished.connect(
		_finish_animation.bind(powerup),
		CONNECT_ONE_SHOT
	)


func play_activate(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	_active_animations[powerup] = tween

	tween.tween_property(
		powerup,
		"scale",
		Vector2(1.25, 1.25),
		0.15
	)

	tween.tween_property(
		powerup,
		"scale",
		Vector2.ONE,
		0.15
	)

	tween.finished.connect(
		_finish_animation.bind(powerup),
		CONNECT_ONE_SHOT
	)


func play_combine(first: Powerup, second: Powerup) -> void:
	if first == null or second == null:
		return

	play_activate(first)
	play_activate(second)


func play_destroy(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	_active_animations[powerup] = tween

	tween.tween_property(
		powerup,
		"scale",
		Vector2.ZERO,
		0.25
	)

	tween.parallel().tween_property(
		powerup,
		"modulate",
		Color(1, 1, 1, 0),
		0.25
	)

	tween.finished.connect(
		_finish_animation.bind(powerup),
		CONNECT_ONE_SHOT
	)


func play_charge(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	_active_animations[powerup] = tween

	tween.tween_property(
		powerup,
		"scale",
		Vector2(1.1, 1.1),
		0.2
	)

	tween.tween_property(
		powerup,
		"scale",
		Vector2.ONE,
		0.2
	)

	tween.finished.connect(
		_destroy_animation_reference.bind(powerup),
		CONNECT_ONE_SHOT
	)


func play_highlight(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	_active_animations[powerup] = tween

	tween.tween_property(
		powerup,
		"modulate",
		Color(1.3, 1.3, 1.3, 1),
		0.15
	)

	tween.tween_property(
		powerup,
		"modulate",
		Color.WHITE,
		0.15
	)

	tween.finished.connect(
		_destroy_animation_reference.bind(powerup),
		CONNECT_ONE_SHOT
	)


func play_shake(powerup: Powerup) -> void:
	if powerup == null:
		return

	var tween := _create_tween(powerup)

	if tween == null:
		return

	_active_animations[powerup] = tween

	var original_position := powerup.position

	tween.tween_property(
		powerup,
		"position",
		original_position + Vector2(8, 0),
		0.05
	)

	tween.tween_property(
		powerup,
		"position",
		original_position - Vector2(8, 0),
		0.05
	)

	tween.tween_property(
		powerup,
		"position",
		original_position,
		0.05
	)

	tween.finished.connect(
		_destroy_animation_reference.bind(powerup),
		CONNECT_ONE_SHOT
	)


# =========================================================
# UTILITY
# =========================================================

func stop(powerup: Powerup) -> void:
	if powerup == null:
		return

	if not _active_animations.has(powerup):
		return

	var tween: Tween = _active_animations[powerup]

	if tween != null:
		tween.kill()

	_active_animations.erase(powerup)


func stop_all() -> void:
	for powerup in _active_animations.keys():
		stop(powerup)


func pause(powerup: Powerup) -> void:
	if powerup == null:
		return

	if not _active_animations.has(powerup):
		return

	var tween: Tween = _active_animations[powerup]

	if tween != null:
		tween.pause()


func resume(powerup: Powerup) -> void:
	if powerup == null:
		return

	if not _active_animations.has(powerup):
		return

	var tween: Tween = _active_animations[powerup]

	if tween != null:
		tween.play()


func is_playing(powerup: Powerup) -> bool:
	return _active_animations.has(powerup)


func wait_until_finished(powerup: Powerup) -> void:
	if powerup == null:
		return

	while _active_animations.has(powerup):
		await get_tree().process_frame


# =========================================================
# INTERNAL
# =========================================================

func _create_tween(powerup: Powerup) -> Tween:
	if powerup == null:
		return null

	stop(powerup)

	return powerup.create_tween()


func _finish_animation(powerup: Powerup) -> void:
	if powerup == null:
		return

	_active_animations.erase(powerup)


func _destroy_animation_reference(powerup: Powerup) -> void:
	if powerup == null:
		return

	_active_animations.erase(powerup)