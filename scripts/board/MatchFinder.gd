extends Node
class_name MatchFinder

# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	pass


# =========================================================
# PUBLIC API
# =========================================================

func find_matches(board) -> Array:
	return find_all_matches(board)


func find_match_from_tile(board, tile) -> Match:
	if board == null or tile == null:
		return null

	var matches := find_all_matches(board)

	for match in matches:
		if match.contains(tile):
			return match

	return null


func find_horizontal_matches(board) -> Array:
	if board == null:
		return []

	return _scan_rows(board)


func find_vertical_matches(board) -> Array:
	if board == null:
		return []

	return _scan_columns(board)


func find_all_matches(board) -> Array:
	if board == null:
		return []

	var matches: Array = []

	matches.append_array(_scan_rows(board))
	matches.append_array(_scan_columns(board))

	return matches


func has_matches(board) -> bool:
	return !find_all_matches(board).is_empty()


# =========================================================
# INTERNAL
# =========================================================

func _scan_rows(board) -> Array:
	var matches: Array = []

	for y in range(board.get_height()):

		var current_tiles: Array = []
		var current_type = null

		for x in range(board.get_width()):

			var tile = board.get_tile(Vector2i(x, y))

			if tile == null:
				_collect_match(current_tiles, matches)
				current_tiles.clear()
				current_type = null
				continue

			var tile_type = tile.get_tile_type()

			if current_tiles.is_empty():
				current_tiles.append(tile)
				current_type = tile_type

			elif tile_type == current_type:
				current_tiles.append(tile)

			else:
				_collect_match(current_tiles, matches)

				current_tiles.clear()
				current_tiles.append(tile)

				current_type = tile_type

		_collect_match(current_tiles, matches)

	return matches


func _scan_columns(board) -> Array:
	var matches: Array = []

	for x in range(board.get_width()):

		var current_tiles: Array = []
		var current_type = null

		for y in range(board.get_height()):

			var tile = board.get_tile(Vector2i(x, y))

			if tile == null:
				_collect_match(current_tiles, matches)
				current_tiles.clear()
				current_type = null
				continue

			var tile_type = tile.get_tile_type()

			if current_tiles.is_empty():
				current_tiles.append(tile)
				current_type = tile_type

			elif tile_type == current_type:
				current_tiles.append(tile)

			else:
				_collect_match(current_tiles, matches)

				current_tiles.clear()
				current_tiles.append(tile)

				current_type = tile_type

		_collect_match(current_tiles, matches)

	return matches


func _collect_match(tile_list: Array, matches: Array) -> void:
	if tile_list.size() < 3:
		return

	var match := Match.new()

	match.initialize()

	for tile in tile_list:
		match.add_tile(tile)

	if match.is_valid():
		matches.append(match)