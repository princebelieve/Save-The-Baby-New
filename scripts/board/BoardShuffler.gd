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
	add_child(_move_validator)
	_move_validator.initialize()


# =========================================================
# PUBLIC API
# =========================================================

func shuffle(board) -> void:
	if board == null:
		return

	if not needs_shuffle(board):
		return

	var max_attempts = 100
	var attempt = 0

	while attempt < max_attempts:
		attempt += 1
		if not _randomize(board):
			continue

		if validate_shuffle(board):
			SignalBus.board_shuffled.emit()
			return
	if board.repair_dead_board():
		SignalBus.board_shuffled.emit()


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
			if tile.has_powerup():
				return false

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
	if board.get_match_finder().has_matches(board):
		return false
	# Board is valid if at least one valid move exists
	var width = board.get_width()
	var height = board.get_height()

	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			var tile = board.get_tile(pos)

			if tile == null:
				continue
			if tile.has_powerup():
				return true

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

func _randomize(board) -> bool:
	var tiles = board.get_all_tiles()
	var positions = []
	var placement: Dictionary = {}
	RandomGenerator.shuffle(tiles)
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var cell := Vector2i(x, y)
			if not board.has_tile(cell):
				continue
			positions.append(cell)
			var selected := -1
			for index in range(tiles.size()):
				var type: int = tiles[index].get_tile_type()
				var left: Tile = placement.get(cell + Vector2i.LEFT)
				var left_two: Tile = placement.get(cell + Vector2i.LEFT * 2)
				var up: Tile = placement.get(cell + Vector2i.UP)
				var up_two: Tile = placement.get(cell + Vector2i.UP * 2)
				if left != null and left_two != null and int(left.get_tile_type()) == type and int(left_two.get_tile_type()) == type:
					continue
				if up != null and up_two != null and int(up.get_tile_type()) == type and int(up_two.get_tile_type()) == type:
					continue
				selected = index
				break
			if selected < 0:
				return false
			placement[cell] = tiles[selected]
			tiles.remove_at(selected)
	# Commit only complete layouts; unsuccessful attempts leave the grid intact.
	for position in positions:
		board.set_tile(position, null)
	for position in positions:
		board.set_tile(position, placement[position])
	return true


func _validate(board) -> bool:
	return validate_shuffle(board)
