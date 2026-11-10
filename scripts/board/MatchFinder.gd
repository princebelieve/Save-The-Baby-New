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

	for found_match in matches:
		if found_match.contains(tile):
			return found_match

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
		_scan_line(board.get_row(y), matches)
	return matches


func _scan_columns(board) -> Array:
	var matches: Array = []
	for x in range(board.get_width()):
		_scan_line(board.get_column(x), matches)
	return matches


func _scan_line(line: Array, matches: Array) -> void:
	var types: Dictionary = {}
	for tile in line:
		if tile != null and int(tile.get_tile_type()) not in [Constants.TileType.ETHAN, Constants.TileType.VICTOR]:
			types[int(tile.get_tile_type())] = true
	for kind in types:
		var run: Array = []
		for tile in line + [null]:
			if tile != null and int(tile.get_tile_type()) in [kind, Constants.TileType.ETHAN]:
				run.append(tile)
			else:
				var ordinary := 0
				for piece in run:
					if int(piece.get_tile_type()) == kind: ordinary += 1
				if run.size() >= 3 and ordinary >= 2:
					var found := Match.new()
					found.initialize()
					for piece in run: found.add_tile(piece)
					matches.append(found)
				run = []
