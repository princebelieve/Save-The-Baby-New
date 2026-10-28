extends Node
class_name TileFactory

# =========================================================
# DEPENDENCIES
# =========================================================

var _tile_scene: PackedScene
var _tile_database: TileDatabase


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(tile_scene: PackedScene, tile_database: TileDatabase) -> void:
	_tile_scene = tile_scene
	_tile_database = tile_database


# =========================================================
# CREATION
# =========================================================

func create_tile(tile_type) -> Tile:
	var tile: Tile = _tile_scene.instantiate()
	_apply_database_data(tile, tile_type)
	return tile


func create_tile_at(tile_type, grid_position: Vector2i) -> Tile:
	var tile: Tile = create_tile(tile_type)
	tile.initialize(tile_type, grid_position)
	return tile


func create_random_tile() -> Tile:
	if _tile_database == null:
		return null

	var data = _tile_database.get_random_spawnable_tile()
	if data.is_empty():
		return null

	return create_tile(data.get("enum"))


func create_random_tile_at(position: Vector2i) -> Tile:
	if _tile_database == null:
		return null

	var data = _tile_database.get_random_spawnable_tile()
	if data.is_empty():
		return null

	return create_tile_at(data.get("enum"), position)


# =========================================================
# COPY
# =========================================================

func duplicate_tile(tile: Tile) -> Tile:
	if tile == null:
		return null

	var new_tile: Tile = _tile_scene.instantiate()

	new_tile.set_tile_state(tile.get_tile_state().duplicate_state())

	_apply_database_data(new_tile, tile.get_tile_type())

	return new_tile


# =========================================================
# LIFECYCLE
# =========================================================

func destroy_tile(tile: Tile) -> void:
	if tile == null:
		return

	tile.queue_free()


func recycle_tile(tile: Tile) -> void:
	if tile == null:
		return

	tile.reset()


func reset_tile(tile: Tile) -> void:
	if tile == null:
		return

	tile.reset()


# =========================================================
# INTERNAL
# =========================================================

func _apply_database_data(tile: Tile, tile_type) -> void:
	if tile == null or _tile_database == null:
		return

	var data = _tile_database.get_tile_by_enum(tile_type)
	if data.is_empty():
		return

	_assign_metadata(tile, data)
	_assign_texture(tile, data)
	_assign_animation_set(tile, data)


func _assign_metadata(tile: Tile, data: Dictionary) -> void:
	# Metadata is already enforced via TileState
	# Factory does not interpret gameplay meaning
	pass


func _assign_texture(tile: Tile, data: Dictionary) -> void:
	var texture_path: String = data.get("texture", "")
	if texture_path == "":
		return

	var texture := ResourceManager.load_texture(texture_path)
	if texture:
		tile.set_texture(texture)


func _assign_animation_set(tile: Tile, data: Dictionary) -> void:
	# Animation sets are referenced, not executed
	# Actual animation execution belongs to AnimationManager/TileAnimator
	tile.set_meta("animation_set", data.get("animation_set", "default"))
