extends Node
class_name TileDatabase

# =========================================================
# INTERNAL CACHE
# =========================================================

var _tile_cache: Dictionary = {}
var _config_data: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reload()


func reload() -> void:
	clear()

	_config_data = ConfigLoader.load_config("tiles") # expects configs/tiles.json

	if _config_data == null:
		push_error("TileDatabase: Failed to load tiles config.")
		_config_data = {}

	_build_cache()


func clear() -> void:
	_tile_cache.clear()
	_config_data.clear()


# =========================================================
# CACHE BUILD
# =========================================================

func _build_cache() -> void:
	if not _config_data.has("tiles"):
		return

	for tile_entry in _config_data["tiles"]:
		var id = tile_entry.get("id")
		if id == null:
			continue

		_tile_cache[id] = tile_entry


# =========================================================
# LOOKUP
# =========================================================

func get_tile(id) -> Dictionary:
	return _tile_cache.get(id, {})


func has_tile(id) -> bool:
	return _tile_cache.has(id)


func get_tile_by_enum(type) -> Dictionary:
	for tile in _tile_cache.values():
		if tile.get("type") == type:
			return tile
	return {}


func get_tile_name(type) -> String:
	var tile = get_tile_by_enum(type)
	return tile.get("name", "")


func get_tile_texture_path(type) -> String:
	var tile = get_tile_by_enum(type)
	return tile.get("texture", "")


func get_tile_icon_path(type) -> String:
	var tile = get_tile_by_enum(type)
	return tile.get("icon", "")


func get_tile_animation_set(type) -> String:
	var tile = get_tile_by_enum(type)
	return tile.get("animation_set", "")


func get_tile_score(type) -> int:
	var tile = get_tile_by_enum(type)
	return tile.get("score", 0)


# =========================================================
# COLLECTIONS
# =========================================================

func get_all_tiles() -> Array:
	return _tile_cache.values()


func get_matchable_tiles() -> Array:
	var result := []
	for tile in _tile_cache.values():
		if tile.get("matchable", true):
			result.append(tile)
	return result


func get_spawnable_tiles() -> Array:
	var result := []
	for tile in _tile_cache.values():
		if tile.get("spawnable", true):
			result.append(tile)
	return result


func get_special_tiles() -> Array:
	var result := []
	for tile in _tile_cache.values():
		if tile.get("special", false):
			result.append(tile)
	return result


func get_hidden_tiles() -> Array:
	var result := []
	for tile in _tile_cache.values():
		if tile.get("hidden", false):
			result.append(tile)
	return result


# =========================================================
# RANDOM
# =========================================================

func get_random_spawnable_tile():
	var pool = get_spawnable_tiles()
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


# =========================================================
# VALIDATION
# =========================================================

func is_matchable(type) -> bool:
	var tile = get_tile_by_enum(type)
	return tile.get("matchable", true)


func is_spawnable(type) -> bool:
	var tile = get_tile_by_enum(type)
	return tile.get("spawnable", true)


func is_special(type) -> bool:
	var tile = get_tile_by_enum(type)
	return tile.get("special", false)


func is_hidden(type) -> bool:
	var tile = get_tile_by_enum(type)
	return tile.get("hidden", false)