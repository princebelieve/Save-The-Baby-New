extends Node

class_name TileFactory


var tile_database: TileDatabase
var resource_manager: ResourceManager


func _ready() -> void:
	_initialize_dependencies()


# ==========================================================
# INITIALIZATION
# ==========================================================

func _initialize_dependencies() -> void:
	if tile_database == null:
		tile_database = get_node_or_null("/root/TileDatabase")

	if resource_manager == null:
		resource_manager = get_node_or_null("/root/ResourceManager")


# ==========================================================
# TILE CREATION
# ==========================================================

func create_tile(
	tile_id: String,
	grid_position: Vector2i
) -> Tile:
	if tile_database == null:
		push_error("TileFactory: TileDatabase not found.")
		return null

	var tile_data := tile_database.get_tile(tile_id)

	if tile_data.is_empty():
		push_error("TileFactory: Unknown tile '%s'." % tile_id)
		return null

	var tile := Tile.new()

	var tile_type := _get_tile_type(tile_id)

	tile.initialize(
		tile_type,
		grid_position
	)

	_apply_tile_data(tile, tile_data)

	return tile


func create_random_tile(
	grid_position: Vector2i
) -> Tile:
	if tile_database == null:
		push_error("TileFactory: TileDatabase not found.")
		return null

	var tile_data := tile_database.get_random_tile()

	if tile_data.is_empty():
		push_error("TileFactory: No spawnable tiles found.")
		return null

	return create_tile(
		String(tile_data["id"]),
		grid_position
	)


# ==========================================================
# DATA APPLICATION
# ==========================================================

func _apply_tile_data(
	tile: Tile,
	tile_data: Dictionary
) -> void:
	if tile_data.has("texture"):
		var texture := _load_texture(
			String(tile_data["texture"])
		)

		if texture != null:
			tile.set_texture(texture)

	if tile_data.has("health"):
		tile.state.health = int(tile_data["health"])

	if tile_data.has("powerup"):
		if bool(tile_data["powerup"]):
			tile.state.powerup = Constants.PowerupType.NONE

	if tile_data.has("obstacle"):
		if bool(tile_data["obstacle"]):
			tile.state.obstacle = Constants.ObstacleType.NONE


func _load_texture(path: String) -> Texture2D:
	if resource_manager == null:
		return load(path)

	return resource_manager.load_texture(path)


# ==========================================================
# TILE TYPE CONVERSION
# ==========================================================

func _get_tile_type(
	tile_id: String
) -> Constants.TileType:
	match tile_id.to_lower():

		"key":
			return Constants.TileType.KEY

		"phone":
			return Constants.TileType.PHONE

		"fingerprint":
			return Constants.TileType.FINGERPRINT

		"recorder":
			return Constants.TileType.RECORDER

		"plier":
			return Constants.TileType.PLIER

		"clock":
			return Constants.TileType.CLOCK

		"ethan":
			return Constants.TileType.ETHAN

		_:
			push_warning(
				"TileFactory: Unknown tile id '%s'. Using KEY."
				% tile_id
			)
			return Constants.TileType.KEY


# ==========================================================
# HELPERS
# ==========================================================

func create_tiles_from_ids(
	ids: Array,
	start_position: Vector2i = Vector2i.ZERO
) -> Array:
	var tiles: Array = []

	var x := start_position.x

	for id in ids:
		var tile := create_tile(
			String(id),
			Vector2i(x, start_position.y)
		)

		if tile != null:
			tiles.append(tile)

		x += 1

	return tiles


# ==========================================================
# DEBUG
# ==========================================================

func print_available_tiles() -> void:
	if tile_database == null:
		return

	print("--------------------------------")
	print("Available Tiles")
	print("--------------------------------")

	for id in tile_database.get_tile_ids():
		print(id)

	print("--------------------------------")