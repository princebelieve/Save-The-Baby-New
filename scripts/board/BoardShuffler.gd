extends Node
class_name BoardShuffler

# =========================================================
# INTERNAL STATE
# =========================================================

var _move_validator = null


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_move_validator = MoveValidator.new()
	_move_validator.initialize()


# =========================================================
# PUBLIC API
# =========================================================

func shuffle(board) -> void:
	if board == null:
		return

	if not needs_shuffle(board):
		return

	var max_attempts = 10
	var attempt = 0

	while attempt < max_attempts:
		_randomize(board)

		if validate_shuffle(board):
			return

		attempt += 1


func needs_shuffle(board) -> bool:
	if board == null:
		return false

	var width = board.get_width()
	var height = board.get_height()

	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var tile = board.get_tile(pos)

			if tile == null:
				continue

			# Try adjacent swaps
			var neighbors = [
				Vector2i(1, 0),
				Vector2i(-1, 0),
				Vector2i(0, 1),
				Vector2i(0, -1)
			]

			for offset in neighbors:
				var npos = pos + offset

				if not board.has_tile(npos):
					continue

				var neighbor_tile = board.get_tile(npos)

				if neighbor_tile == null:
					continue

				if _move_validator.is_valid_swipe(tile, neighbor_tile):
					return false

	return true


func validate_shuffle(board) -> bool:
	# Board is valid if at least one valid move exists
	var width = board.get_width()
	var height = board.get_height()

	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var tile = board.get_tile(pos)

			if tile == null:
				continue

			var neighbors = [
				Vector2i(1, 0),
				Vector2i(-1, 0),
				Vector2i(0, 1),
				Vector2i(0, -1)
			]

			for offset in neighbors:
				var npos = pos + offset

				if not board.has_tile(npos):
					continue

				var neighbor_tile = board.get_tile(npos)

				if neighbor_tile == null:
					continue

				if _move_validator.is_valid_swipe(tile, neighbor_tile):
					return true

	return false


# =========================================================
# INTERNAL LOGIC
# =========================================================

func _randomize(board) -> void:
	var tiles = board.get_all_tiles()
	var positions = []

	# Collect all positions
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			positions.append(Vector2i(x, y))

	# Clear cells before reassignment so a shuffle never duplicates a tile reference.
	for position in positions:
		board.set_tile(position, null)

	RandomGenerator.shuffle(positions)

	# Reassign tiles randomly
	for i in range(min(tiles.size(), positions.size())):
		var tile = tiles[i]
		var pos = positions[i]

		board.set_tile(pos, tile)


func _validate(board) -> bool:
	return validate_shuffle(board)
