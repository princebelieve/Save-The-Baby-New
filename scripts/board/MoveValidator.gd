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
	return would_create_match(board, tile_a, tile_b)


func would_create_match(board, tile_a, tile_b) -> bool:
	if board == null:
		return false
	return _simulate_swap(board, tile_a.get_grid_position(), tile_b.get_grid_position())


func _simulate_swap(board, first_position: Vector2i, second_position: Vector2i) -> bool:
	var first_tile = board.get_tile(first_position)
	var second_tile = board.get_tile(second_position)
	if first_tile == null or second_tile == null:
		return false

	board.set_tile(first_position, second_tile)
	board.set_tile(second_position, first_tile)
	var match_finder: MatchFinder = board.get_match_finder()
	var has_match := match_finder != null and match_finder.has_matches(board)
	board.set_tile(first_position, first_tile)
	board.set_tile(second_position, second_tile)
	return has_match
