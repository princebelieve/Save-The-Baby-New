extends RefCounted

class_name TileAnimator


const DEFAULT_SWAP_DURATION := 0.15
const DEFAULT_FALL_DURATION := 0.20
const DEFAULT_SPAWN_DURATION := 0.18
const DEFAULT_DESTROY_DURATION := 0.18
const DEFAULT_BOUNCE_DURATION := 0.08


static func animate_swap(
	tile_a: Tile,
	tile_b: Tile,
	duration: float = DEFAULT_SWAP_DURATION
) -> Tween:

	if tile_a == null or tile_b == null:
		return null

	var tree := tile_a.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()
	tween.set_parallel(true)

	var position_a := tile_a.position
	var position_b := tile_b.position

	tween.tween_property(
		tile_a,
		"position",
		position_b,
		duration
	)

	tween.tween_property(
		tile_b,
		"position",
		position_a,
		duration
	)

	return tween


static func animate_move(
	tile: Tile,
	target_position: Vector2,
	duration: float = DEFAULT_SWAP_DURATION
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"position",
		target_position,
		duration
	)

	return tween


static func animate_fall(
	tile: Tile,
	target_position: Vector2,
	duration: float = DEFAULT_FALL_DURATION
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"position",
		target_position,
		duration
	)

	tween.tween_callback(
		func():
			tile.land()
	)

	return tween


static func animate_spawn(
	tile: Tile,
	start_position: Vector2,
	target_position: Vector2,
	duration: float = DEFAULT_SPAWN_DURATION
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	tile.position = start_position
	tile.scale = Vector2(0.0, 0.0)
	tile.modulate.a = 0.0

	var tween := tree.create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		tile,
		"position",
		target_position,
		duration
	)

	tween.tween_property(
		tile,
		"scale",
		Vector2.ONE,
		duration
	)

	tween.tween_property(
		tile,
		"modulate:a",
		1.0,
		duration
	)

	tween.tween_callback(
		func():
			tile.finish_spawn()
	)

	return tween


static func animate_destroy(
	tile: Tile,
	duration: float = DEFAULT_DESTROY_DURATION
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		tile,
		"scale",
		Vector2.ZERO,
		duration
	)

	tween.tween_property(
		tile,
		"modulate:a",
		0.0,
		duration
	)

	tween.tween_callback(
		func():
			if is_instance_valid(tile):
				tile.queue_free()
	)

	return tween


static func animate_selection(tile: Tile) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"scale",
		Vector2(1.10, 1.10),
		DEFAULT_BOUNCE_DURATION
	)

	return tween


static func animate_deselection(tile: Tile) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"scale",
		Vector2.ONE,
		DEFAULT_BOUNCE_DURATION
	)

	return tween


static func animate_bounce(tile: Tile) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"scale",
		Vector2(1.12, 1.12),
		DEFAULT_BOUNCE_DURATION
	)

	tween.tween_property(
		tile,
		"scale",
		Vector2.ONE,
		DEFAULT_BOUNCE_DURATION
	)

	return tween


static func animate_shake(
	tile: Tile,
	distance: float = 8.0,
	duration: float = 0.05
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var original_position := tile.position

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"position",
		original_position + Vector2(distance, 0),
		duration
	)

	tween.tween_property(
		tile,
		"position",
		original_position - Vector2(distance, 0),
		duration
	)

	tween.tween_property(
		tile,
		"position",
		original_position,
		duration
	)

	return tween


static func animate_highlight(
	tile: Tile,
	color: Color,
	duration: float = 0.25
) -> Tween:

	if tile == null:
		return null

	var tree := tile.get_tree()

	if tree == null:
		return null

	var original := tile.modulate

	var tween := tree.create_tween()

	tween.tween_property(
		tile,
		"modulate",
		color,
		duration
	)

	tween.tween_property(
		tile,
		"modulate",
		original,
		duration
	)

	return tween


static func stop_all(tile: Tile) -> void:

	if tile == null:
		return

	for child in tile.get_children():
		if child is Tween:
			child.kill()