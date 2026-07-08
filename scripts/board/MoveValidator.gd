extends Node
class_name MoveValidator

# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	# Stateless system for now
	pass


# =========================================================
# PUBLIC API
# =========================================================

func is_valid_swipe(tile_a, tile_b) -> bool:
	if tile_a == null or tile_b == null:
		return false

	if not is_adjacent(tile_a, tile_b):
		return false

	return can_swap(tile_a, tile_b)


func is_adjacent(tile_a, tile_b) -> bool:
	var pos_a = tile_a.position
	var pos_b = tile_b.position

	var dx = abs(pos_a.x - pos_b.x)
	var dy = abs(pos_a.y - pos_b.y)

	# Must be directly horizontal or vertical neighbor
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)


func can_swap(tile_a, tile_b) -> bool:
	# Delegates actual match logic check
	# Swap is allowed only if it results in a match
	var board = tile_a.get_parent_board()

	if board == null:
		return false

	return would_create_match(board, tile_a, tile_b)


func would_create_match(board, tile_a, tile_b) -> bool:
	if board == null:
		return false

	var pos_a = tile_a.position
	var pos_b = tile_b.position

	return _simulate_swap(board, pos_a, pos_b)


# =========================================================
# INTERNAL LOGIC
# =========================================================

func _simulate_swap(board, pos_a: Vector2i, pos_b: Vector2i) -> bool:
	var tile_a = board.get_tile(pos_a)
	var tile_b = board.get_tile(pos_b)

	if tile_a == null or tile_b == null:
		return false

	# Temporarily swap references
	board.set_tile(pos_a, tile_b)
	board.set_tile(pos_b, tile_a)

	# Check if swap produces any match
	var match_finder = board._match_finder
	if match_finder == null:
		# restore before exit
		board.set_tile(pos_a, tile_a)
		board.set_tile(pos_b, tile_b)
		return false

	var has_match = match_finder.has_matches(board)

	# Restore original state immediately
	board.set_tile(pos_a, tile_a)
	board.set_tile(pos_b, tile_b)

	return has_match


func _check_direction(pos_a: Vector2i, pos_b: Vector2i) -> Vector2i:
	return Vector2i(
		sign(pos_b.x - pos_a.x),
		sign(pos_b.y - pos_a.y)
	)
