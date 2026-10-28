extends Node
class_name RefillSystem

var _board_generator: BoardGenerator


func initialize(board_generator: BoardGenerator) -> void:
	_board_generator = board_generator


func refill(board) -> void:
	if board == null or _board_generator == null:
		return
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var position := Vector2i(x, y)
			if board.get_tile(position) == null:
				board.set_tile(position, _board_generator.generate_tile(position))


func spawn_tile(position: Vector2i):
	if _board_generator == null:
		return null
	return _board_generator.generate_tile(position)


func spawn_column(column: int, board) -> void:
	if board == null:
		return
	for y in range(board.get_height()):
		var position := Vector2i(column, y)
		if board.get_tile(position) == null:
			board.set_tile(position, spawn_tile(position))


func needs_refill(board) -> bool:
	if board == null:
		return false
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			if board.get_tile(Vector2i(x, y)) == null:
				return true
	return false
