extends Node
class_name GravitySolver


func initialize() -> void:
	pass


func apply_gravity(board) -> Array:
	if board == null:
		return []
	var movements: Array = []
	for x in range(board.get_width()):
		var column: Array = []
		for y in range(board.get_height() - 1, -1, -1):
			var tile = board.get_tile(Vector2i(x, y))
			if tile != null:
				column.append(tile)
		for y in range(board.get_height()):
			board.set_tile(Vector2i(x, y), null)
		for index in range(column.size()):
			var destination := Vector2i(x, board.get_height() - 1 - index)
			var tile: Tile = column[index]
			var old_position := tile.position
			board.set_tile(destination, tile)
			if old_position != tile.position:
				movements.append({"tile": tile, "from": old_position, "to": tile.position})
	return movements


func calculate_fall(board) -> Dictionary:
	var fall_map: Dictionary = {}
	if board == null:
		return fall_map
	for x in range(board.get_width()):
		var next_y: int = board.get_height() - 1
		for y in range(board.get_height() - 1, -1, -1):
			var from_position := Vector2i(x, y)
			if board.get_tile(from_position) == null:
				continue
			if y != next_y:
				fall_map[from_position] = Vector2i(x, next_y)
			next_y -= 1
	return fall_map


func get_fall_path(tile, board = null) -> Array:
	if tile == null or board == null:
		return []
	var position: Vector2i = tile.get_grid_position()
	var path: Array = []
	for y in range(position.y + 1, board.get_height()):
		var below := Vector2i(position.x, y)
		if board.get_tile(below) != null:
			break
		path.append(below)
	return path


func has_floating_tiles(board) -> bool:
	if board == null:
		return false
	for x in range(board.get_width()):
		var found_empty_below := false
		for y in range(board.get_height() - 1, -1, -1):
			if board.get_tile(Vector2i(x, y)) == null:
				found_empty_below = true
			elif found_empty_below:
				return true
	return false
