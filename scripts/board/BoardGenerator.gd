extends Node
class_name BoardGenerator

# =========================================================
# INTERNAL STATE
# =========================================================

var _tile_factory = null
var _config = null


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_tile_factory = TileFactory.new()
	_tile_factory.initialize()

	# Config is optional at this layer; treated as opaque if provided later
	_config = null


# =========================================================
# GENERATION ENTRY POINT
# =========================================================

func generate(level_data):
	var width = level_data.width
	var height = level_data.height

	var board = generate_empty(width, height)
	fill_board(board)

	_remove_initial_matches(board)
	ensure_valid_moves(board)

	_validate_board(board)

	return board


# =========================================================
# EMPTY BOARD CREATION
# =========================================================

func generate_empty(width: int, height: int) -> Dictionary:
	var board = {}

	for y in range(height):
		for x in range(width):
			board[Vector2i(x, y)] = null

	return board


# =========================================================
# BOARD FILLING
# =========================================================

func fill_board(board: Dictionary) -> void:
	for position in board.keys():
		board[position] = generate_tile(position)


func generate_tile(position: Vector2i):
	return _create_tile(position)


# =========================================================
# VALIDATION: INITIAL BOARD SAFETY
# =========================================================

func remove_initial_matches(board: Dictionary) -> void:
	while has_initial_matches(board):
		for position in board.keys():
			if _forms_match(board, position):
				board[position] = _create_tile(position)


func ensure_valid_moves(board: Dictionary) -> void:
	while not has_valid_moves(board):
		_randomize_board(board)


func has_initial_matches(board: Dictionary) -> bool:
	for position in board.keys():
		if _forms_match(board, position):
			return true
	return false


func has_valid_moves(board: Dictionary) -> bool:
	# Lightweight simulation scan
	for pos in board.keys():
		var neighbors = _get_swappable_neighbors(board, pos)

		for n in neighbors:
			if _would_create_match(board, pos, n):
				return true

	return false


# =========================================================
# INTERNAL TILE CREATION
# =========================================================

func _create_tile(position: Vector2i):
	# Delegates actual instantiation to TileFactory
	if _tile_factory == null:
		return null

	return _tile_factory.create_tile(position)


func _fill_position(board: Dictionary, position: Vector2i):
	board[position] = _create_tile(position)


# =========================================================
# VALIDATION HELPERS
# =========================================================

func _forms_match(board: Dictionary, position: Vector2i) -> bool:
	var tile = board.get(position, null)
	if tile == null:
		return false

	# Check horizontal
	var left = board.get(position + Vector2i(-1, 0), null)
	var right = board.get(position + Vector2i(1, 0), null)

	if left != null and right != null:
		if left.type == tile.type and right.type == tile.type:
			return true

	# Check vertical
	var up = board.get(position + Vector2i(0, -1), null)
	var down = board.get(position + Vector2i(0, 1), null)

	if up != null and down != null:
		if up.type == tile.type and down.type == tile.type:
			return true

	return false


func _get_swappable_neighbors(board: Dictionary, position: Vector2i) -> Array:
	var results = []

	var offsets = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for o in offsets:
		var p = position + o
		if board.has(p):
			results.append(p)

	return results


func _would_create_match(board: Dictionary, a: Vector2i, b: Vector2i) -> bool:
	var temp_a = board[a]
	var temp_b = board[b]

	# simulate swap
	board[a] = temp_b
	board[b] = temp_a

	var result = _forms_match(board, a) or _forms_match(board, b)

	# revert swap
	board[a] = temp_a
	board[b] = temp_b

	return result


func _randomize_board(board: Dictionary) -> void:
	var keys = board.keys()

	for i in range(keys.size()):
		var j = randi() % keys.size()

		var tmp = board[keys[i]]
		board[keys[i]] = board[keys[j]]
		board[keys[j]] = tmp


func _validate_board(board: Dictionary) -> void:
	# Final safety pass (no mutation unless necessary)
	if has_initial_matches(board):
		push_warning("BoardGenerator: unresolved initial matches detected")

	if not has_valid_moves(board):
		push_warning("BoardGenerator: generated board has no valid moves")