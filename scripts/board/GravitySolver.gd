extends Node
class_name GravitySolver


func initialize() -> void:
	pass


func apply_gravity(board) -> Array:
	if board == null:
		return []
	var movements: Array = []
	for x in range(board.get_width()):
		var y: int = board.get_height() - 1
		while y >= 0:
			if not board.is_playable_cell(Vector2i(x, y)):
				y -= 1
				continue
			var segment_bottom: int = y
			while y >= 0 and board.is_playable_cell(Vector2i(x, y)):
				y -= 1
			var segment_top: int = y + 1
			var column: Array[Tile] = []
			for source_y in range(segment_bottom, segment_top - 1, -1):
				var tile: Tile = board.get_tile(Vector2i(x, source_y))
				if tile != null:
					column.append(tile)
			for clear_y in range(segment_top, segment_bottom + 1):
				board.set_tile(Vector2i(x, clear_y), null)
			for index in range(column.size()):
				var destination := Vector2i(x, segment_bottom - index)
				var tile := column[index]
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
			if not board.is_playable_cell(from_position):
				next_y = y - 1
				continue
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
		if not board.is_playable_cell(below):
			break
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
			var position := Vector2i(x, y)
			if not board.is_playable_cell(position):
				found_empty_below = false
			elif board.get_tile(position) == null:
				found_empty_below = true
			elif found_empty_below:
				return true
	return false
