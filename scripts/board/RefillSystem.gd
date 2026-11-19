extends Node
class_name RefillSystem

var _board_generator: BoardGenerator


func initialize(board_generator: BoardGenerator) -> void:
	_board_generator = board_generator


func refill(board, animate: bool = false) -> Array:
	var movements: Array = []
	if board == null or _board_generator == null: return movements
	var origins: Dictionary = {}
	var spawned: Dictionary = {}
	var paths: Dictionary = {}
	for tile in board.get_all_tiles():
		origins[tile] = tile.position
		paths[tile] = [tile.position]
	var gravity := GravitySolver.new()
	for cycle in range(board.get_width() * board.get_height()):
		var added := false
		for y in range(board.get_height()):
			for x in range(board.get_width()):
				var cell := Vector2i(x, y)
				if not board.is_refill_source(cell) or board.get_tile(cell) != null: continue
				var tile: Tile = _board_generator.generate_refill_tile(cell, board)
				board.set_tile(cell, tile, false)
				origins[tile] = tile.position - Vector2(0, board.get_tile_size())
				paths[tile] = [origins[tile], tile.position]
				spawned[tile] = true
				added = true
		for movement in gravity.apply_gravity(board):
			var path: Array = movement.path
			paths[movement.tile].append_array(path.slice(1))
		if not added: break
	gravity.free()
	# Choose refill types at their settled cells, not at the inlet. Otherwise
	# inlet-safe tiles can manufacture long accidental cascades after falling.
	for original in spawned.keys():
		var cell: Vector2i = original.get_grid_position()
		var origin: Vector2 = origins[original]
		var path: Array = paths[original]
		board.remove_tile(cell)
		var replacement: Tile = _board_generator.generate_refill_tile(cell, board)
		board.set_tile(cell, replacement, false)
		origins.erase(original)
		paths.erase(original)
		spawned.erase(original)
		origins[replacement] = origin
		paths[replacement] = path
		spawned[replacement] = true
	for tile in origins:
		if tile.position != origins[tile]:
			movements.append({"tile": tile, "from": origins[tile], "to": tile.position, "new": spawned.has(tile), "path": paths[tile]})
	return movements if animate else []


func spawn_tile(position: Vector2i):
	if _board_generator == null:
		return null
	return _board_generator.generate_tile(position)


func spawn_column(_column: int, board) -> void:
	refill(board)

func needs_refill(board) -> bool:
	if board == null: return false
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var cell := Vector2i(x, y)
			if board.is_refill_source(cell) and board.get_tile(cell) == null: return true
	return false
