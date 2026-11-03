extends Node
class_name RefillSystem

var _board_generator: BoardGenerator


func initialize(board_generator: BoardGenerator) -> void:
	_board_generator = board_generator


func refill(board, animate: bool = false) -> Array:
	var movements: Array = []
	if board == null or _board_generator == null:
		return movements
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var position := Vector2i(x, y)
			if board.get_tile(position) == null:
				var tile: Tile = _board_generator.generate_tile(position)
				board.set_tile(position, tile, false)
				if animate:
					var destination: Vector2 = tile.position
					var from := Vector2(destination.x, -float(board.get_tile_size()) * (1.0 + y * 0.18))
					tile.position = from
					movements.append({"tile": tile, "from": from, "to": destination, "new": true})
				else:
					tile.scale = Vector2.ONE
	return movements


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
