extends Node
class_name Board

# =========================================================
# INTERNAL STATE
# =========================================================

var _grid: Dictionary = {}  # Vector2i -> Tile
var _locked: bool = false
var _level_data = null

var _board_generator: BoardGenerator = null
var _move_validator: MoveValidator = null
var _match_finder: MatchFinder = null
var _gravity_solver: GravitySolver = null
var _refill_system: RefillSystem = null
var _cascade_processor: CascadeProcessor = null
var _board_shuffler: BoardShuffler = null

# =========================================================
# INITIALIZATION
# =========================================================

func initialize(level_data) -> void:
	_level_data = level_data
	_grid.clear()

	_locked = false

	_board_generator = BoardGenerator.new()
	_move_validator = MoveValidator.new()
	_match_finder = MatchFinder.new()
	_gravity_solver = GravitySolver.new()
	_refill_system = RefillSystem.new()
	_cascade_processor = CascadeProcessor.new()
	_board_shuffler = BoardShuffler.new()

	_board_generator.initialize()
	_move_validator.initialize()
	_match_finder.initialize()
	_gravity_solver.initialize()
	_refill_system.initialize()
	_cascade_processor.initialize()
	_board_shuffler.initialize()

	_board_generator.generate(level_data)
	_grid = _board_generator.get_generated_grid()


func reset() -> void:
	if _board_generator == null:
		return

	clear()
	initialize(_level_data)


func clear() -> void:
	for pos in _grid.keys():
		var tile = _grid[pos]
		if tile != null and is_instance_valid(tile):
			tile.queue_free()

	_grid.clear()


# =========================================================
# BOARD INFO
# =========================================================

func get_width() -> int:
	return _level_data.width if _level_data != null else 0


func get_height() -> int:
	return _level_data.height if _level_data != null else 0


func get_size() -> Vector2i:
	return Vector2i(get_width(), get_height())


func is_inside(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 \
	and position.x < get_width() \
	and position.y < get_height()


# =========================================================
# TILE ACCESS
# =========================================================

func set_tile(position: Vector2i, tile) -> void:
	if not is_inside(position):
		return
	_grid[position] = tile


func get_tile(position: Vector2i):
	if not is_inside(position):
		return null
	return _grid.get(position, null)


func remove_tile(position: Vector2i):
	if not is_inside(position):
		return

	var tile = _grid.get(position, null)
	if tile != null and is_instance_valid(tile):
		tile.queue_free()

	_grid.erase(position)


func has_tile(position: Vector2i) -> bool:
	return _grid.has(position)


func swap_tiles(position_a: Vector2i, position_b: Vector2i) -> void:
	if _locked:
		return

	if not is_inside(position_a) or not is_inside(position_b):
		return

	var tile_a = get_tile(position_a)
	var tile_b = get_tile(position_b)

	if tile_a == null or tile_b == null:
		return

	_grid[position_a] = tile_b
	_grid[position_b] = tile_a


# =========================================================
# GRID QUERIES
# =========================================================

func get_all_tiles() -> Array:
	return _grid.values()


func get_row(index: int) -> Array:
	var row = []
	for x in range(get_width()):
		var pos = Vector2i(x, index)
		if _grid.has(pos):
			row.append(_grid[pos])
	return row


func get_column(index: int) -> Array:
	var col = []
	for y in range(get_height()):
		var pos = Vector2i(index, y)
		if _grid.has(pos):
			col.append(_grid[pos])
	return col


func get_neighbors(position: Vector2i) -> Array:
	var offsets = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	var result = []

	for offset in offsets:
		var pos = position + offset
		if is_inside(pos) and _grid.has(pos):
			result.append(_grid[pos])

	return result


# =========================================================
# GAMEPLAY STATE CONTROL
# =========================================================

func lock() -> void:
	_locked = true


func unlock() -> void:
	_locked = false


func is_locked() -> bool:
	return _locked


func is_stable() -> bool:
	if _match_finder == null:
		return true

	return not _match_finder.has_matches(self)


func update() -> void:
	if _locked:
		return

	# Cascade processing is the full board resolution loop
	if _cascade_processor != null:
		_cascade_processor.process(self)
