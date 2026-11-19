extends Node
class_name GravitySolver


func initialize() -> void:
	pass


func apply_gravity(board) -> Array:
	if board == null: return []
	var origins: Dictionary = {}
	var paths: Dictionary = {}
	for tile in board.get_all_tiles():
		origins[tile] = tile.position
		paths[tile] = [tile.position]
	# Every step descends one row. Fixed blockers retain their captive tile.
	for step in range(board.get_height() * board.get_width()):
		var moved := false
		for y in range(board.get_height() - 2, -1, -1):
			for x in range(board.get_width()):
				var source := Vector2i(x, y)
				if not board.is_flow_cell(source): continue
				var tile: Tile = board.get_tile(source)
				if tile == null: continue
				var destination := source + Vector2i.DOWN
				if not board.is_flow_cell(destination) or board.get_tile(destination) != null:
					destination = source
					for side in [-1, 1]:
						var diagonal := source + Vector2i(side, 1)
						var above := diagonal + Vector2i.UP
						if board.is_flow_cell(diagonal) and board.get_tile(diagonal) == null and (not board.is_flow_cell(above) or board.get_tile(above) == null):
							destination = diagonal
							break
				if destination == source: continue
				board.set_tile(source, null)
				board.set_tile(destination, tile)
				paths[tile].append(tile.position)
				moved = true
		if not moved: break
	var movements: Array = []
	for tile in origins:
		if tile.position != origins[tile]: movements.append({"tile": tile, "from": origins[tile], "to": tile.position, "path": paths[tile]})
	return movements


func calculate_fall(board) -> Dictionary:
	var fall_map: Dictionary = {}
	if board == null:
		return fall_map
	for x in range(board.get_width()):
		var next_y: int = board.get_height() - 1
		for y in range(board.get_height() - 1, -1, -1):
			var from_position := Vector2i(x, y)
			if not board.is_flow_cell(from_position):
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
		if not board.is_flow_cell(below):
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
			if not board.is_flow_cell(position):
				found_empty_below = false
			elif board.get_tile(position) == null:
				found_empty_below = true
			elif found_empty_below:
				return true
	return false
