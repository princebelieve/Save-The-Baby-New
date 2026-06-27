extends Node

class_name TileDatabase


var _tiles: Dictionary = {}


func _ready() -> void:
	load_database()


# ==========================================================
# LOADING
# ==========================================================

func load_database() -> void:
	_tiles.clear()

	var config := ConfigManager.get_config("tiles")

	if config.is_empty():
		push_warning("TileDatabase: tiles.json could not be loaded.")
		return

	if not config.has("tiles"):
		push_warning("TileDatabase: Missing 'tiles' section.")
		return

	var tile_list = config["tiles"]

	if tile_list is Array:
		for tile_data in tile_list:
			if tile_data is Dictionary:
				_register_tile(tile_data)


func reload_database() -> void:
	load_database()


func _register_tile(tile_data: Dictionary) -> void:
	if not tile_data.has("id"):
		push_warning("TileDatabase: Tile missing id.")
		return

	var id := String(tile_data["id"])

	_tiles[id] = tile_data


# ==========================================================
# LOOKUPS
# ==========================================================

func has_tile(id: String) -> bool:
	return _tiles.has(id)


func get_tile(id: String) -> Dictionary:
	if _tiles.has(id):
		return _tiles[id]

	push_warning("TileDatabase: Unknown tile '%s'." % id)
	return {}


func get_all_tiles() -> Dictionary:
	return _tiles


func get_tile_ids() -> Array:
	return _tiles.keys()


func get_tile_count() -> int:
	return _tiles.size()


# ==========================================================
# PROPERTIES
# ==========================================================

func get_property(
	id: String,
	property: String,
	default_value: Variant = null
) -> Variant:
	if not _tiles.has(id):
		return default_value

	var tile: Dictionary = _tiles[id]

	if tile.has(property):
		return tile[property]

	return default_value


func get_texture_path(id: String) -> String:
	return String(
		get_property(id, "texture", "")
	)


func get_name(id: String) -> String:
	return String(
		get_property(id, "name", "")
	)


func get_match_value(id: String) -> int:
	return int(
		get_property(id, "match_value", 0)
	)


func get_score(id: String) -> int:
	return int(
		get_property(id, "score", 0)
	)


func is_spawnable(id: String) -> bool:
	return bool(
		get_property(id, "spawnable", true)
	)


func has_powerup(id: String) -> bool:
	return bool(
		get_property(id, "powerup", false)
	)


func is_special(id: String) -> bool:
	return bool(
		get_property(id, "special", false)
	)


# ==========================================================
# RANDOM TILE
# ==========================================================

func get_random_tile() -> Dictionary:
	var available: Array = []

	for id in _tiles.keys():
		if is_spawnable(id):
			available.append(_tiles[id])

	if available.is_empty():
		return {}

	return RandomGenerator.random_item(available)


func get_random_tile_id() -> String:
	var tile := get_random_tile()

	if tile.is_empty():
		return ""

	return String(tile["id"])


# ==========================================================
# DEBUG
# ==========================================================

func print_database() -> void:
	print("--------------------------------")
	print("Tile Database")
	print("--------------------------------")

	for id in _tiles.keys():
		print(id)

	print("--------------------------------")
	print("Total Tiles: ", _tiles.size())
	print("--------------------------------")