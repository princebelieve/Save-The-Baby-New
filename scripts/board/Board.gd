extends Node2D
class_name Board

signal moves_changed(remaining_moves: int)
signal move_rejected
signal match_collected(tile_types: Array)
signal turn_resolved
signal booster_used(kind: String)
signal obstacles_cleared(amount: int)
signal obstacle_damaged(cell: Vector2i, remaining_health: int, destroyed: bool)
signal tiles_matched_with_cells(tile_types: Array, cells: Array)
signal special_created(kind: String)
signal special_activated(kind: String)

var _grid: Dictionary = {}
var _locked: bool = false
var _level_data: Dictionary = {}
var _tile_size: int = 64
var _drag_start: Tile
var _tap_selection: Tile
var _press_screen_position: Vector2 = Vector2.ZERO
var _remaining_moves: int = 0
var _required_swap: Array[Vector2i] = []
var _required_booster_target := Vector2i(-1, -1)
var _booster_mode := ""
var _obstacles: Dictionary = {}
var _obstacle_database: ObstacleDatabase
var _obstacle_factory: ObstacleFactory

var _tile_database: TileDatabase
var _tile_factory: TileFactory
var _board_generator: BoardGenerator
var _move_validator: MoveValidator
var _match_finder: MatchFinder
var _gravity_solver: GravitySolver
var _refill_system: RefillSystem
var _cascade_processor: CascadeProcessor
var _board_shuffler: BoardShuffler


func initialize(level_data: Dictionary) -> bool:
	_level_data = level_data.duplicate(true)
	_locked = false
	_tap_selection = null
	_remaining_moves = int(_level_data.get("moves", {}).get("total", 0))
	_grid.clear()
	_clear_systems()
	_create_systems()
	if _board_generator == null:
		return false

	var generated: Dictionary = _board_generator.generate(_level_data)
	if generated.is_empty():
		push_error("Board: Board generation failed for level %s." % _level_data.get("level_id", "?"))
		return false

	_grid = generated
	var board_data: Dictionary = _level_data.get("board", {})
	var configured_tile_size := int(board_data.get("tile_size", 64))
	var columns := maxi(get_width(), 1)
	# Keep the playable grid prominent on modern portrait screens while honoring
	# larger per-level tile sizes.
	_tile_size = maxi(configured_tile_size, int(floor(viewport_width() * 0.92 / columns)))
	for position in _grid:
		var tile: Tile = _grid[position]
		_attach_tile(tile, position)
		tile.scale = Vector2.ONE * 0.72
		var spawn_tween := create_tween()
		spawn_tween.tween_property(tile, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_load_obstacles()

	var viewport_size := get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - get_width() * _tile_size) * 0.5,
		maxf(120.0, (viewport_size.y - get_height() * _tile_size) * 0.45)
	)
	moves_changed.emit(_remaining_moves)
	queue_redraw()
	return true


func viewport_width() -> float:
	return get_viewport_rect().size.x


func _draw() -> void:
	if _grid.is_empty() or _tile_size <= 0:
		return
	var board_size := Vector2(get_width() * _tile_size, get_height() * _tile_size)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#10283a")
	frame.border_color = Color("#d6b66e")
	frame.set_border_width_all(4)
	frame.set_corner_radius_all(16)
	frame.set_content_margin_all(10)
	draw_style_box(frame, Rect2(Vector2(-10, -10), board_size + Vector2(20, 20)))
	for y in get_height():
		for x in get_width():
			var inset := 2.0
			var cell := Rect2(Vector2(x * _tile_size + inset, y * _tile_size + inset), Vector2(_tile_size - inset * 2.0, _tile_size - inset * 2.0))
			var fill := Color("#18354b") if (x + y) % 2 == 0 else Color("#1c3b50")
			draw_rect(cell, fill, true)
			draw_rect(cell, Color(0.55, 0.75, 0.82, 0.16), false, 1.0)


func reset() -> void:
	for tile in _grid.values():
		if is_instance_valid(tile):
			tile.queue_free()
	_grid.clear()
	initialize(_level_data)


func clear() -> void:
	for tile in _grid.values():
		if is_instance_valid(tile):
			tile.queue_free()
	_grid.clear()
	for obstacle in _obstacles.values():
		if is_instance_valid(obstacle): obstacle.queue_free()
	_obstacles.clear()
	_drag_start = null


func _clear_systems() -> void:
	for system in [
		_tile_database, _tile_factory, _board_generator, _move_validator,
		_match_finder, _gravity_solver, _refill_system,
		_cascade_processor, _board_shuffler, _obstacle_factory, _obstacle_database
	]:
		if system != null and is_instance_valid(system):
			system.queue_free()
	_tile_database = null
	_tile_factory = null
	_board_generator = null
	_move_validator = null
	_match_finder = null
	_gravity_solver = null
	_refill_system = null
	_cascade_processor = null
	_board_shuffler = null
	_obstacle_factory = null
	_obstacle_database = null
	for obstacle in _obstacles.values():
		if is_instance_valid(obstacle): obstacle.queue_free()
	_obstacles.clear()


func _create_systems() -> void:
	_tile_database = TileDatabase.new()
	add_child(_tile_database)
	_tile_database.initialize()

	var tile_scene := ResourceManager.load_scene(Constants.ScenePaths.TILE)
	if tile_scene == null:
		push_error("Board: Tile scene could not be loaded.")
		_tile_database.queue_free()
		_tile_database = null
		return
	_tile_factory = TileFactory.new()
	add_child(_tile_factory)
	_tile_factory.initialize(tile_scene, _tile_database)

	_board_generator = BoardGenerator.new()
	add_child(_board_generator)
	_board_generator.initialize(_tile_factory, _tile_database)

	_move_validator = MoveValidator.new()
	_match_finder = MatchFinder.new()
	_gravity_solver = GravitySolver.new()
	_refill_system = RefillSystem.new()
	_cascade_processor = CascadeProcessor.new()
	_board_shuffler = BoardShuffler.new()
	_obstacle_database = ObstacleDatabase.new()
	add_child(_obstacle_database)
	_obstacle_database.initialize()
	_obstacle_factory = ObstacleFactory.new()
	add_child(_obstacle_factory)
	_obstacle_factory.initialize(_obstacle_database)
	for system in [_move_validator, _match_finder, _gravity_solver, _refill_system, _cascade_processor, _board_shuffler]:
		add_child(system)
	_move_validator.initialize()
	_match_finder.initialize()
	_gravity_solver.initialize()
	_refill_system.initialize(_board_generator)
	_cascade_processor.initialize(_match_finder, _gravity_solver, _refill_system)
	_board_shuffler.initialize()


func get_width() -> int:
	var board_data: Dictionary = _level_data.get("board", {})
	return int(board_data.get("columns", 0))


func get_height() -> int:
	var board_data: Dictionary = _level_data.get("board", {})
	return int(board_data.get("rows", 0))


func get_size() -> Vector2i:
	return Vector2i(get_width(), get_height())


func get_remaining_moves() -> int:
	return _remaining_moves


func is_inside(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < get_width() and position.y < get_height()


func set_tile(position: Vector2i, tile) -> void:
	if not is_inside(position):
		return
	if tile == null:
		_grid.erase(position)
		return
	var is_new_tile: bool = tile.get_parent() == null
	_grid[position] = tile
	tile.set_grid_position(position)
	_attach_tile(tile, position)
	if is_new_tile:
		tile.scale = Vector2.ONE * 0.45
		var spawn_tween := create_tween()
		spawn_tween.tween_property(tile, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_tile(position: Vector2i):
	if not is_inside(position):
		return null
	return _grid.get(position, null)


func remove_tile(position: Vector2i) -> void:
	if not is_inside(position):
		return
	var tile = _grid.get(position, null)
	_grid.erase(position)
	if tile != null and is_instance_valid(tile):
		tile.queue_free()


func has_tile(position: Vector2i) -> bool:
	return _grid.get(position, null) != null


func swap_tiles(position_a: Vector2i, position_b: Vector2i) -> bool:
	if _locked or _move_validator == null or not is_inside(position_a) or not is_inside(position_b):
		return false
	var tile_a: Tile = get_tile(position_a)
	var tile_b: Tile = get_tile(position_b)
	if tile_a == null or tile_b == null:
		return false
	if not _required_swap.is_empty() and not _is_required_swap(position_a, position_b):
		move_rejected.emit()
		return false
	var special_tile: Tile = tile_a if tile_a.has_powerup() else (tile_b if tile_b.has_powerup() else null)
	if special_tile == null and not _move_validator.is_valid_swipe(tile_a, tile_b):
		move_rejected.emit()
		_animate_invalid_move(tile_a, tile_b)
		return false
	_locked = true
	_required_swap.clear()
	_clear_tutorial_highlights()
	_grid[position_a] = tile_b
	_grid[position_b] = tile_a
	tile_a.set_grid_position(position_b)
	tile_b.set_grid_position(position_a)
	_animate_swap_then_resolve(tile_a, tile_b, special_tile)
	return true


func _animate_swap_then_resolve(tile_a: Tile, tile_b: Tile, special_tile: Tile = null) -> void:
	var destination_a := _cell_center(tile_a.get_grid_position())
	var destination_b := _cell_center(tile_b.get_grid_position())
	var tween := create_tween().set_parallel(true)
	tween.tween_property(tile_a, "position", destination_a, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile_b, "position", destination_b, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_remaining_moves = maxi(0, _remaining_moves - 1)
	moves_changed.emit(_remaining_moves)
	SignalBus.moves_changed.emit(_remaining_moves)
	SignalBus.move_used.emit(_remaining_moves)
	if special_tile != null:
		await _resolve_special_powerup(special_tile)
	else:
		await _cascade_processor.process_animated(self)
	_locked = false
	turn_resolved.emit()
	if _board_shuffler != null and _board_shuffler.needs_shuffle(self):
		_board_shuffler.shuffle(self)


func _animate_invalid_move(tile_a: Tile, tile_b: Tile) -> void:
	var original_a := tile_a.position
	var original_b := tile_b.position
	var offset := Vector2(5.0, 0.0) if absf(original_a.x - original_b.x) > absf(original_a.y - original_b.y) else Vector2(0.0, 5.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(tile_a, "position", original_a + offset, 0.045)
	tween.tween_property(tile_b, "position", original_b + offset, 0.045)
	tween.chain().tween_property(tile_a, "position", original_a - offset, 0.045)
	tween.parallel().tween_property(tile_b, "position", original_b - offset, 0.045)
	tween.chain().tween_property(tile_a, "position", original_a, 0.045)
	tween.parallel().tween_property(tile_b, "position", original_b, 0.045)


func _cell_center(grid_position: Vector2i) -> Vector2:
	return Vector2((grid_position.x + 0.5) * _tile_size, (grid_position.y + 0.5) * _tile_size)


func notify_match_tiles(tiles: Array) -> void:
	var tile_types: Array = []
	var cells: Array = []
	for tile in tiles:
		if tile != null:
			tile_types.append(tile.get_tile_type())
			cells.append(tile.get_grid_position())
	match_collected.emit(tile_types)
	tiles_matched_with_cells.emit(tile_types, cells)
	SignalBus.matches_found.emit(tiles)
	_damage_nearby_obstacles(tiles)


func find_valid_swap() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if _move_validator == null:
		return result
	for y in range(get_height()):
		for x in range(get_width()):
			var first := Vector2i(x, y)
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				var second: Vector2i = first + offset
				if is_inside(second) and _move_validator.is_valid_swipe(get_tile(first), get_tile(second)):
					result.append(first)
					result.append(second)
					return result
	return result


func find_valid_swap_for_type(target_type: int, minimum_match_size: int = 3) -> Array[Vector2i]:
	if _move_validator == null or _match_finder == null:
		return []
	for y in range(get_height()):
		for x in range(get_width()):
			var first := Vector2i(x, y)
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				var second: Vector2i = first + offset
				if not is_inside(second):
					continue
				var first_tile: Tile = get_tile(first)
				var second_tile: Tile = get_tile(second)
				if not _move_validator.is_valid_swipe(first_tile, second_tile):
					continue
				_grid[first] = second_tile
				_grid[second] = first_tile
				first_tile.set_grid_position(second)
				second_tile.set_grid_position(first)
				var collects_target := false
				for found_match in _match_finder.find_all_matches(self):
					if found_match.size() < minimum_match_size:
						continue
					if target_type < 0:
						collects_target = true
						break
					for tile in found_match.get_tiles():
						if int(tile.get_tile_type()) == target_type:
							collects_target = true
							break
					if collects_target:
						break
				_grid[first] = first_tile
				_grid[second] = second_tile
				first_tile.set_grid_position(first)
				second_tile.set_grid_position(second)
				if collects_target:
					return [first, second]
	return []


func get_required_swap() -> Array[Vector2i]:
	return _required_swap.duplicate()


func get_cell_screen_rect(cell: Vector2i) -> Rect2:
	if not is_inside(cell):
		return Rect2()
	var transform := get_global_transform_with_canvas()
	var top_left := transform * Vector2(cell.x * _tile_size, cell.y * _tile_size)
	var bottom_right := transform * Vector2((cell.x + 1) * _tile_size, (cell.y + 1) * _tile_size)
	return Rect2(top_left, bottom_right - top_left)


func get_obstacle_screen_rect(cell: Vector2i) -> Rect2:
	return get_cell_screen_rect(cell) if _obstacles.has(cell) else Rect2()


func find_powerup_cell() -> Vector2i:
	for cell in _grid:
		var tile: Tile = _grid[cell]
		if tile != null and tile.has_powerup():
			return cell
	return Vector2i(-1, -1)


func find_valid_swap_near_obstacle() -> Array[Vector2i]:
	for y in range(get_height()):
		for x in range(get_width()):
			var first := Vector2i(x, y)
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				var second: Vector2i = first + offset
				if not is_inside(second) or not _move_validator.is_valid_swipe(get_tile(first), get_tile(second)):
					continue
				var first_tile: Tile = get_tile(first)
				var second_tile: Tile = get_tile(second)
				set_tile(first, second_tile)
				set_tile(second, first_tile)
				var touches_obstacle := false
				for found_match in _match_finder.find_all_matches(self):
					for tile in found_match.get_tiles():
						for obstacle_cell in _obstacles.keys():
							if absi(tile.get_grid_position().x - obstacle_cell.x) + absi(tile.get_grid_position().y - obstacle_cell.y) <= 1:
								touches_obstacle = true
								break
						if touches_obstacle:
							break
					if touches_obstacle:
						break
				set_tile(first, first_tile)
				set_tile(second, second_tile)
				if touches_obstacle:
					return [first, second]
	return []


func set_required_swap(positions: Array[Vector2i]) -> void:
	_required_swap = positions.duplicate()
	_clear_tutorial_highlights()
	for position in _required_swap:
		var tile: Tile = get_tile(position)
		if tile != null:
			tile.set_tile_modulate(Color(1.35, 1.25, 0.68, 1.0))


func clear_required_swap() -> void:
	_required_swap.clear()
	_clear_tutorial_highlights()
	_required_booster_target = Vector2i(-1, -1)


func set_required_booster_target(position: Vector2i) -> void:
	_required_booster_target = position
	_clear_tutorial_highlights()
	var tile: Tile = get_tile(position)
	if tile != null:
		tile.set_tile_modulate(Color(1.35, 1.25, 0.68, 1.0))


func create_powerup_for_match(matches: Array) -> Tile:
	var powerup_config: Dictionary = _level_data.get("powerups", {})
	if not bool(powerup_config.get("enabled", false)):
		return null
	var selected_match: Match = null
	var best_size := 0
	var has_intersection := false
	var match_counts: Dictionary = {}
	for found_match in matches:
		if found_match.size() > best_size:
			best_size = found_match.size()
			selected_match = found_match
		for tile in found_match.get_tiles():
			match_counts[tile] = int(match_counts.get(tile, 0)) + 1
	for count in match_counts.values():
		if int(count) > 1:
			has_intersection = true
			break
	if selected_match == null or (best_size < 4 and not has_intersection):
		return null
	var kind := "rocket"
	var powerup_type := Constants.PowerupType.ROCKET
	var available: Array = powerup_config.get("available", [])
	if has_intersection and available.has("BOMB"):
		kind = "bomb"
		powerup_type = Constants.PowerupType.BOMB
	elif best_size >= 5 and available.has("THUNDER"):
		kind = "thunder"
		powerup_type = Constants.PowerupType.THUNDER
	elif available.has("ROCKET"):
		kind = "rocket"
		powerup_type = Constants.PowerupType.ROCKET
	else:
		return null
	var center := selected_match.get_center_tile() as Tile
	if center == null:
		return null
	center.set_powerup(powerup_type)
	center.set_meta("powerup_kind", kind)
	special_created.emit(kind)
	var icon_path := "res://assets/sprites/powerups/%s_powerup_icon.jpeg" % kind
	var icon := ResourceManager.load_texture(icon_path)
	if icon != null:
		center.set_texture(icon)
	var pulse := create_tween().set_loops(2)
	pulse.tween_property(center, "scale", Vector2.ONE * 1.18, 0.12)
	pulse.tween_property(center, "scale", Vector2.ONE, 0.12)
	return center


func _is_required_swap(first: Vector2i, second: Vector2i) -> bool:
	return _required_swap.size() == 2 and ((first == _required_swap[0] and second == _required_swap[1]) or (first == _required_swap[1] and second == _required_swap[0]))


func _clear_tutorial_highlights() -> void:
	for tile in _grid.values():
		if is_instance_valid(tile):
			tile.reset_tile_modulate()


func set_booster_mode(kind: String) -> void:
	if _locked:
		return
	_booster_mode = kind
	if not kind.is_empty():
		SignalBus.play_sfx.emit("booster_select")


func cancel_booster_mode() -> void:
	_booster_mode = ""


func _load_obstacles() -> void:
	_obstacles.clear()
	var definitions: Array = _level_data.get("obstacles", {}).get("items", [])
	for definition in definitions:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var cell := Vector2i(int(definition.get("x", -1)), int(definition.get("y", -1)))
		var obstacle_id := str(definition.get("type", "")).to_lower()
		var obstacle_type = Constants.ObstacleType.get(obstacle_id.to_upper(), -1)
		if obstacle_type == -1 or not is_inside(cell) or _obstacle_factory == null:
			continue
		var obstacle := _obstacle_factory.create_obstacle_at(obstacle_type, cell)
		if obstacle == null:
			continue
		var obstacle_state := obstacle.get_obstacle_state()
		obstacle_state.set_health(int(definition.get("health", _obstacle_database.get_health(obstacle_type))))
		obstacle.position = _cell_center(cell)
		add_child(obstacle)
		var texture := obstacle.get_texture()
		if texture != null:
			var max_dimension := maxf(texture.get_width(), texture.get_height())
			obstacle.scale = Vector2.ONE * (float(_tile_size - 8) / maxf(max_dimension, 1.0))
		_obstacles[cell] = obstacle


func _damage_nearby_obstacles(tiles: Array) -> void:
	if _obstacles.is_empty():
		return
	var hit_cells: Dictionary = {}
	for tile in tiles:
		var tile_cell: Vector2i = tile.get_grid_position()
		for cell in _obstacles.keys():
			if absi(cell.x - tile_cell.x) + absi(cell.y - tile_cell.y) <= 1:
				hit_cells[cell] = true
	var cleared := 0
	for cell in hit_cells:
		var obstacle: Obstacle = _obstacles.get(cell)
		if not is_instance_valid(obstacle):
			_obstacles.erase(cell)
			continue
		obstacle.damage(1)
		var destroyed := obstacle.is_destroyed()
		obstacle_damaged.emit(cell, obstacle.get_obstacle_state().get_health(), destroyed)
		var shake := create_tween()
		shake.tween_property(obstacle, "rotation", 0.08, 0.05)
		shake.tween_property(obstacle, "rotation", -0.08, 0.05)
		shake.tween_property(obstacle, "rotation", 0.0, 0.05)
		if destroyed:
			_obstacles.erase(cell)
			cleared += 1
			var destroy := create_tween()
			destroy.set_parallel(true)
			destroy.tween_property(obstacle, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			destroy.tween_property(obstacle, "modulate:a", 0.0, 0.16)
			destroy.finished.connect(obstacle.queue_free)
	if cleared > 0:
		obstacles_cleared.emit(cleared)


func use_booster_at(kind: String, position: Vector2i) -> bool:
	if _locked or not is_inside(position) or get_tile(position) == null:
		return false
	if _required_booster_target != Vector2i(-1, -1) and position != _required_booster_target:
		return false
	var target: Tile = get_tile(position)
	var targets: Array = []
	match kind:
		"hammer":
			targets.append(target)
		"rocket":
			for x in range(get_width()):
				var row_tile: Tile = get_tile(Vector2i(x, position.y))
				if row_tile != null: targets.append(row_tile)
			for y in range(get_height()):
				var column_tile: Tile = get_tile(Vector2i(position.x, y))
				if column_tile != null and not targets.has(column_tile): targets.append(column_tile)
		"bomb":
			for y in range(maxi(0, position.y - 1), mini(get_height(), position.y + 2)):
				for x in range(maxi(0, position.x - 1), mini(get_width(), position.x + 2)):
					var area_tile: Tile = get_tile(Vector2i(x, y))
					if area_tile != null: targets.append(area_tile)
		"thunder":
			var target_type: int = target.get_tile_type()
			for tile in _grid.values():
				if tile.get_tile_type() == target_type: targets.append(tile)
		"ethan":
			for y in range(maxi(0, position.y - 2), mini(get_height(), position.y + 3)):
				for x in range(maxi(0, position.x - 2), mini(get_width(), position.x + 3)):
					var rescue_tile: Tile = get_tile(Vector2i(x, y))
					if rescue_tile != null: targets.append(rescue_tile)
		_:
			return false
	if targets.is_empty():
		return false
	_locked = true
	_booster_mode = ""
	_required_booster_target = Vector2i(-1, -1)
	booster_used.emit(kind)
	_resolve_external_clear(targets, kind)
	return true


func _resolve_special_powerup(powerup_tile: Tile) -> void:
	var kind := str(powerup_tile.get_meta("powerup_kind", "rocket"))
	special_activated.emit(kind)
	var target_type := int(powerup_tile.get_tile_type())
	var targets: Array = []
	if kind == "thunder":
		for tile in _grid.values():
			if tile.get_tile_type() == target_type: targets.append(tile)
	elif kind == "bomb":
		var position := powerup_tile.get_grid_position()
		for y in range(maxi(0, position.y - 1), mini(get_height(), position.y + 2)):
			for x in range(maxi(0, position.x - 1), mini(get_width(), position.x + 2)):
				var tile: Tile = get_tile(Vector2i(x, y))
				if tile != null: targets.append(tile)
	else:
		var position := powerup_tile.get_grid_position()
		for x in range(get_width()):
			var row_tile: Tile = get_tile(Vector2i(x, position.y))
			if row_tile != null: targets.append(row_tile)
		for y in range(get_height()):
			var column_tile: Tile = get_tile(Vector2i(position.x, y))
			if column_tile != null and not targets.has(column_tile): targets.append(column_tile)
	powerup_tile.clear_powerup()
	powerup_tile.remove_meta("powerup_kind")
	_resolve_external_clear(targets, kind)


func play_celebration_shake(intensity: float = 1.0) -> void:
	var origin := position
	var strength := 7.0 * clampf(intensity, 0.5, 1.6)
	var shake := create_tween()
	shake.tween_property(self, "position", origin + Vector2(strength, 0.0), 0.045)
	shake.tween_property(self, "position", origin + Vector2(-strength, strength * 0.28), 0.045)
	shake.tween_property(self, "position", origin + Vector2(strength * 0.72, -strength * 0.28), 0.045)
	shake.tween_property(self, "position", origin, 0.07).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _resolve_external_clear(tiles: Array, effect: String) -> void:
	var unique_tiles: Array = []
	for tile in tiles:
		if is_instance_valid(tile) and not unique_tiles.has(tile): unique_tiles.append(tile)
	if unique_tiles.is_empty():
		_locked = false
		turn_resolved.emit()
		return
	if effect == "thunder":
		SignalBus.play_sfx.emit("thunder_crack")
		SignalBus.play_sfx.emit("thunder_roll")
	else:
		SignalBus.play_sfx.emit("powerup_" + effect)
	notify_match_tiles(unique_tiles)
	var burst := create_tween().set_parallel(true)
	for tile in unique_tiles:
		burst.tween_property(tile, "scale", Vector2.ONE * 1.22, 0.08)
	await burst.finished
	await animate_match_tiles(unique_tiles)
	for tile in unique_tiles:
		remove_tile(tile.get_grid_position())
	var movements: Array = _gravity_solver.apply_gravity(self)
	await animate_falling_tiles(movements)
	_refill_system.refill(self)
	await _cascade_processor.process_animated(self)
	_locked = false
	turn_resolved.emit()


func animate_match_tiles(tiles: Array) -> void:
	var tween := create_tween().set_parallel(true)
	for tile in tiles:
		if is_instance_valid(tile):
			tween.tween_property(tile, "scale", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(tile, "modulate:a", 0.0, 0.14)
	await tween.finished


func animate_falling_tiles(movements: Array) -> void:
	if movements.is_empty():
		return
	var tween := create_tween().set_parallel(true)
	for movement in movements:
		var tile: Tile = movement["tile"]
		if is_instance_valid(tile):
			tile.position = movement["from"]
			tween.tween_property(tile, "position", movement["to"], 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished


func get_all_tiles() -> Array:
	return _grid.values()


func get_row(index: int) -> Array:
	var row: Array = []
	for x in range(get_width()):
		row.append(get_tile(Vector2i(x, index)))
	return row


func get_column(index: int) -> Array:
	var column: Array = []
	for y in range(get_height()):
		column.append(get_tile(Vector2i(index, y)))
	return column


func get_neighbors(position: Vector2i) -> Array:
	var neighbors: Array = []
	for offset in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor = get_tile(position + offset)
		if neighbor != null:
			neighbors.append(neighbor)
	return neighbors


func get_match_finder() -> MatchFinder:
	return _match_finder


func lock() -> void:
	_locked = true


func unlock() -> void:
	_locked = false


func is_locked() -> bool:
	return _locked


func is_stable() -> bool:
	return _match_finder == null or not _match_finder.has_matches(self)


func update() -> void:
	if not _locked and _cascade_processor != null:
		_cascade_processor.process(self)
	if _board_shuffler != null and _board_shuffler.needs_shuffle(self):
		_board_shuffler.shuffle(self)


func _set_tile_visual_position(tile: Tile, grid_position: Vector2i) -> void:
	if tile == null:
		return
	tile.position = Vector2(
			grid_position.x * _tile_size + _tile_size * 0.5,
			grid_position.y * _tile_size + _tile_size * 0.5
	)
	tile.set_visual_size(float(_tile_size - 4))


func _attach_tile(tile: Tile, grid_position: Vector2i) -> void:
	if tile.get_parent() == null:
		add_child(tile)
	tile.set_hitbox_size(_tile_size)
	_set_tile_visual_position(tile, grid_position)


func _input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer_gesture(event.position)
		else:
			_finish_pointer_gesture(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer_gesture(event.position)
		else:
			_finish_pointer_gesture(event.position)


func _begin_pointer_gesture(screen_position: Vector2) -> void:
	_drag_start = _tile_at_screen_position(screen_position)
	_press_screen_position = screen_position
	if _drag_start == null:
		return
	if _tap_selection != null and _tap_selection != _drag_start:
		var first_position := _tap_selection.get_grid_position()
		var second_position := _drag_start.get_grid_position()
		if absi(first_position.x - second_position.x) + absi(first_position.y - second_position.y) == 1:
			swap_tiles(first_position, second_position)
			_tap_selection.reset_tile_modulate()
			_tap_selection = null
			_drag_start = null
			return
	if _tap_selection != null and is_instance_valid(_tap_selection):
		_tap_selection.reset_tile_modulate()
	_tap_selection = _drag_start
	_tap_selection.set_tile_modulate(Color(1.18, 1.18, 0.85, 1.0))


func _tile_at_screen_position(screen_position: Vector2) -> Tile:
	var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_position
	var grid_position := Vector2i(
		int(floor(local_position.x / _tile_size)),
		int(floor(local_position.y / _tile_size))
	)
	return get_tile(grid_position)


func _finish_swipe(target: Tile, drag_delta: Vector2) -> void:
	var start := _drag_start
	_drag_start = null
	if start == null:
		return
	if target != null and start != target:
		start.reset_tile_modulate()
		if _tap_selection != null and is_instance_valid(_tap_selection):
			_tap_selection.reset_tile_modulate()
		_tap_selection = null
		swap_tiles(start.get_grid_position(), target.get_grid_position())
		return
	if drag_delta.length() >= 18.0:
		var offset: Vector2i
		if absf(drag_delta.x) > absf(drag_delta.y):
			offset = Vector2i.RIGHT if drag_delta.x > 0 else Vector2i.LEFT
		else:
			offset = Vector2i.DOWN if drag_delta.y > 0 else Vector2i.UP
		var destination := start.get_grid_position() + offset
		if is_inside(destination):
			start.reset_tile_modulate()
			_tap_selection = null
			swap_tiles(start.get_grid_position(), destination)


func _finish_pointer_gesture(screen_position: Vector2) -> void:
	var release_tile := _tile_at_screen_position(screen_position)
	if not _booster_mode.is_empty():
		var selected_kind := _booster_mode
		if release_tile != null and _required_booster_target != Vector2i(-1, -1) and release_tile.get_grid_position() != _required_booster_target:
			move_rejected.emit()
			_drag_start = null
			_tap_selection = null
			return
		_booster_mode = ""
		if release_tile != null:
			use_booster_at(selected_kind, release_tile.get_grid_position())
		_drag_start = null
		_tap_selection = null
		return
	if _drag_start != null and release_tile == _drag_start:
		var delta := screen_position - _press_screen_position
		if delta.length() >= 18.0:
			var direction: Vector2i
			if absf(delta.x) > absf(delta.y):
				direction = Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT
			else:
				direction = Vector2i.DOWN if delta.y > 0 else Vector2i.UP
			release_tile = get_tile(_drag_start.get_grid_position() + direction)
	_finish_swipe(release_tile, screen_position - _press_screen_position)
