extends Node
class_name MoveValidator


func initialize() -> void:
	pass


func is_valid_swipe(tile_a, tile_b) -> bool:
	if tile_a == null or tile_b == null or not is_adjacent(tile_a, tile_b):
		return false
	return can_swap(tile_a, tile_b)


func is_adjacent(tile_a, tile_b) -> bool:
	var first: Vector2i = tile_a.get_grid_position()
	var second: Vector2i = tile_b.get_grid_position()
	return absi(first.x - second.x) + absi(first.y - second.y) == 1


func can_swap(tile_a, tile_b) -> bool:
	var board = tile_a.get_parent()
	if board == null or not board.has_method("get_match_finder"):
		return false
	var first: Vector2i = tile_a.get_grid_position()
	var second: Vector2i = tile_b.get_grid_position()
	if board.is_swap_blocked(first) or board.is_swap_blocked(second): return false
	if tile_a.has_powerup() or tile_b.has_powerup(): return true
	return would_create_match(board, tile_a, tile_b)


func would_create_match(board, tile_a, tile_b) -> bool:
	if board == null:
		return false
	var first_position: Vector2i = tile_a.get_grid_position()
	var second_position: Vector2i = tile_b.get_grid_position()
	if board.has_method("is_swap_blocked") and (board.is_swap_blocked(first_position) or board.is_swap_blocked(second_position)):
		return false
	return _simulate_swap(board, first_position, second_position)


func _simulate_swap(board, first_position: Vector2i, second_position: Vector2i) -> bool:
	if board.get_tile(first_position) == null or board.get_tile(second_position) == null:
		return false
	# Validate against a virtual layout. Moving live tiles here was also snapping
	# sprites while move hints and shuffle checks searched the board.
	for origin in [first_position, second_position]:
		var type := _swapped_type(board, origin, first_position, second_position)
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var count := 1
			for sign_value in [-1, 1]:
				var cursor: Vector2i = origin + direction * sign_value
				while board.is_inside(cursor) and _swapped_type(board, cursor, first_position, second_position) == type:
					count += 1
					cursor += direction * sign_value
			if count >= 3: return true
	return false


func _swapped_type(board, cell: Vector2i, first: Vector2i, second: Vector2i) -> int:
	var source := second if cell == first else (first if cell == second else cell)
	var tile = board.get_tile(source)
	return int(tile.get_tile_type()) if tile != null else -1
