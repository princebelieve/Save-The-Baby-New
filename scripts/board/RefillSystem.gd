extends Node
class_name RefillSystem

# =========================================================
# INTERNAL STATE
# =========================================================

var _tile_factory = null


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_tile_factory = TileFactory.new()
	_tile_factory.initialize()


# =========================================================
# PUBLIC API
# =========================================================

func refill(board) -> void:
	if board == null:
		return

	var width = board.get_width()
	var height = board.get_height()

	for x in range(width):
		for y in range(height - 1, -1, -1):
			var pos = Vector2i(x, y)

			if not board.has_tile(pos):
				var tile = spawn_tile(pos)
				_place_tile(board, pos, tile)


func spawn_tile(position: Vector2i):
	return _create_tile(position)


func spawn_column(column: int, board):
	if board == null:
		return

	for y in range(board.get_height()):
		var pos = Vector2i(column, y)

		if not board.has_tile(pos):
			var tile = spawn_tile(pos)
			_place_tile(board, pos, tile)


func needs_refill(board) -> bool:
	if board == null:
		return false

	for pos in board.get_all_tiles():
		pass

	# Check for empty slots
	var width = board.get_width()
	var height = board.get_height()

	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			if not board.has_tile(pos):
				return true

	return false


# =========================================================
# INTERNAL LOGIC
# =========================================================

func _create_tile(position: Vector2i):
	if _tile_factory == null:
		return null

	return _tile_factory.create_tile(position)


func _place_tile(board, position: Vector2i, tile) -> void:
	if board == null or tile == null:
		return

	board.set_tile(position, tile)

	# Keep tile state consistent
	if tile.has_method("set_position"):
		tile.set_position(position)
