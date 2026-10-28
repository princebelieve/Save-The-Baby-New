extends Node2D
class_name Board

var _grid: Dictionary = {}
var _locked: bool = false
var _level_data: Dictionary = {}
var _tile_size: int = 64
var _drag_start: Tile

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

	var viewport_size := get_viewport_rect().size
	position = Vector2(
		(viewport_size.x - get_width() * _tile_size) * 0.5,
		maxf(120.0, (viewport_size.y - get_height() * _tile_size) * 0.45)
	)
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


func is_inside(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < get_width() and position.y < get_height()


func set_tile(position: Vector2i, tile) -> void:
	if not is_inside(position):
		return
	if tile == null:
		_grid.erase(position)
		return
	_grid[position] = tile
	tile.set_grid_position(position)
	_attach_tile(tile, position)


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
		return false
	set_tile(position_a, tile_b)
	set_tile(position_b, tile_a)
	update()
	return true


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
	var pressed_callback := Callable(self, "_on_tile_pressed")
	var released_callback := Callable(self, "_on_tile_released")
	if not tile.pressed.is_connected(pressed_callback):
		tile.pressed.connect(pressed_callback)
	if not tile.released.is_connected(released_callback):
		tile.released.connect(released_callback)


func _on_tile_pressed(tile: Tile) -> void:
	if not _locked:
		_drag_start = tile


func _on_tile_released(tile: Tile) -> void:
	if _locked or _drag_start == null:
		_drag_start = null
		return
	var start := _drag_start
	_drag_start = null
	if start != tile:
		swap_tiles(start.get_grid_position(), tile.get_grid_position())


func _input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = _tile_at_screen_position(event.position)
		else:
			_finish_swipe(_tile_at_screen_position(event.position))
	elif event is InputEventScreenTouch:
		if event.pressed:
			_drag_start = _tile_at_screen_position(event.position)
		else:
			_finish_swipe(_tile_at_screen_position(event.position))


func _tile_at_screen_position(screen_position: Vector2) -> Tile:
	var local_position := to_local(screen_position)
	var grid_position := Vector2i(
		int(floor(local_position.x / _tile_size)),
		int(floor(local_position.y / _tile_size))
	)
	return get_tile(grid_position)


func _finish_swipe(target: Tile) -> void:
	var start := _drag_start
	_drag_start = null
	if start != null and target != null and start != target:
		swap_tiles(start.get_grid_position(), target.get_grid_position())
