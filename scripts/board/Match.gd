extends RefCounted
class_name Match

# =========================================================
# INTERNAL STATE
# =========================================================

var _tiles: Array = []
var _pattern = null  # optional metadata (horizontal, vertical, L-shape, etc.)


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(pattern = null) -> void:
	_tiles.clear()
	_pattern = pattern


# =========================================================
# PUBLIC API
# =========================================================

func add_tile(tile) -> void:
	if tile == null:
		return

	if _tiles.has(tile):
		return

	_tiles.append(tile)


func remove_tile(tile) -> void:
	_tiles.erase(tile)


func get_tiles() -> Array:
	return _tiles.duplicate()


func size() -> int:
	return _tiles.size()


func contains(tile) -> bool:
	return _tiles.has(tile)


func get_center_tile():
	if _tiles.is_empty():
		return null

	# Simple heuristic: middle index
	var mid_index = int(_tiles.size() / 2)
	return _tiles[mid_index]


func get_pattern():
	return _pattern


func is_valid() -> bool:
	return _tiles.size() >= 3