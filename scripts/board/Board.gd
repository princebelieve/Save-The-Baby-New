extends Node2D
class_name Board

signal moves_changed(remaining_moves: int)
signal move_rejected
signal match_collected(tile_types: Array)

var _grid: Dictionary = {}
var _locked: bool = false
var _level_data: Dictionary = {}
var _tile_size: int = 64
var _drag_start: Tile
var _tap_selection: Tile
var _press_screen_position: Vector2 = Vector2.ZERO
var _remaining_moves: int = 0

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
	_tile_size = int(board_data.get("tile_size", 64))
	for position in _grid:
		var tile: Tile = _grid[position]
		_attach_tile(tile, position)
		tile.scale = Vector2.ONE * 0.72
		var spawn_tween := create_tween()
		spawn_tween.tween_property(tile, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var viewport_size := get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - get_width() * _tile_size) * 0.5,
		maxf(120.0, (viewport_size.y - get_height() * _tile_size) * 0.45)
	)
	moves_changed.emit(_remaining_moves)
	return true


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
	_drag_start = null


func _clear_systems() -> void:
	for system in [
		_tile_database, _tile_factory, _board_generator, _move_validator,
		_match_finder, _gravity_solver, _refill_system,
		_cascade_processor, _board_shuffler
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
	if not _move_validator.is_valid_swipe(tile_a, tile_b):
		move_rejected.emit()
		_animate_invalid_move(tile_a, tile_b)
		return false
	_locked = true
	_grid[position_a] = tile_b
	_grid[position_b] = tile_a
	tile_a.set_grid_position(position_b)
	tile_b.set_grid_position(position_a)
	_animate_swap_then_resolve(tile_a, tile_b)
	return true


func _animate_swap_then_resolve(tile_a: Tile, tile_b: Tile) -> void:
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
	await _cascade_processor.process_animated(self)
	_locked = false
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
	for tile in tiles:
		if tile != null:
			tile_types.append(tile.get_tile_type())
	match_collected.emit(tile_types)
	SignalBus.matches_found.emit(tiles)


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
