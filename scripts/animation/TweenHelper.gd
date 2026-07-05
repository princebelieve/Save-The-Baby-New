extends Node
class_name TweenHelper

# =========================================================
# PURPOSE
# =========================================================
# Provides reusable, generic tween utilities.
# NO gameplay knowledge.
# NO understanding of tiles, UI, board, or game rules.
# Only operates on Nodes and properties.

# =========================================================
# CORE INTERNAL
# =========================================================

static func _create_tween(target: Node) -> Tween:
	if target == null:
		return null

	var tween: Tween = target.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween


# =========================================================
# MOVE
# =========================================================

static func move(target: Node, to_position: Vector2, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	tween.tween_property(target, "position", to_position, duration)
	return tween


# =========================================================
# FADE
# =========================================================

static func fade(target: CanvasItem, to_alpha: float, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	tween.tween_property(target, "modulate:a", to_alpha, duration)
	return tween


# =========================================================
# SCALE
# =========================================================

static func scale(target: Node2D, to_scale: Vector2, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	tween.tween_property(target, "scale", to_scale, duration)
	return tween


# =========================================================
# ROTATE
# =========================================================

static func rotate(target: Node2D, to_rotation: float, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	tween.tween_property(target, "rotation", to_rotation, duration)
	return tween


# =========================================================
# SHAKE
# =========================================================

static func shake(target: Node2D, intensity: float, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	var original_position = target.position

	tween.tween_method(
		func(t):
			target.position = original_position + Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			),
		0.0,
		1.0,
		duration
	)

	tween.tween_callback(func():
		target.position = original_position
	)

	return tween


# =========================================================
# BOUNCE
# =========================================================

static func bounce(target: Node2D, height: float, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	var original_position = target.position
	var peak_position = original_position + Vector2(0, -height)

	tween.tween_property(target, "position", peak_position, duration * 0.5)
	tween.tween_property(target, "position", original_position, duration * 0.5)

	return tween


# =========================================================
# FLASH
# =========================================================

static func flash(target: CanvasItem, flash_color: Color, duration: float) -> Tween:
	var tween = _create_tween(target)
	if tween == null:
		return null

	var original_color = target.modulate

	tween.tween_property(target, "modulate", flash_color, duration * 0.5)
	tween.tween_property(target, "modulate", original_color, duration * 0.5)

	return tween