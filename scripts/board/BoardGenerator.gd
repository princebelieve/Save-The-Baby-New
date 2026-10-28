extends Node
class_name BoardGenerator

var _tile_factory: TileFactory
var _tile_database: TileDatabase
var _level_tile_definitions: Array[Dictionary] = []
var _level_tile_weights: Array[float] = []
var _generated_grid: Dictionary = {}
var _tile_size: int = 64


func initialize(tile_factory: TileFactory, tile_database: TileDatabase) -> void:
	_tile_factory = tile_factory
	_tile_database = tile_database


func generate(level_data: Dictionary) -> Dictionary:
	_generated_grid.clear()
	_level_tile_definitions.clear()
	_level_tile_weights.clear()

	var board_data: Dictionary = level_data.get("board", {})
	var width := int(board_data.get("columns", 0))
	var height := int(board_data.get("rows", 0))
	_tile_size = int(board_data.get("tile_size", 64))
	if width < 3 or height < 3 or _tile_size <= 0:
		push_error("BoardGenerator: Board dimensions must be at least 3 by 3.")
		return {}

	_load_level_tile_pool(level_data.get("tile_pool", {}))
	if _level_tile_definitions.size() < 3:
		push_error("BoardGenerator: A board requires at least three valid spawnable tile types.")
		return {}

	var type_grid := _generate_type_grid(width, height)
	if type_grid.is_empty():
		push_error("BoardGenerator: Could not generate a playable starting layout.")
		return {}

	for y in range(height):
		for x in range(width):
			var position := Vector2i(x, y)
			var definition: Dictionary = _definition_for_type(type_grid[position])
			var tile := _tile_factory.create_tile_at(definition["enum"], position)
			if tile == null:
				push_error("BoardGenerator: Failed to create tile '%s'." % definition["id"])
				return {}
			_generated_grid[position] = tile

	return _generated_grid.duplicate()


func get_generated_grid() -> Dictionary:
	return _generated_grid.duplicate()


func get_tile_size() -> int:
	return _tile_size


func generate_tile(position: Vector2i) -> Tile:
	if _tile_factory == null or _level_tile_definitions.is_empty():
		return null
	var definition := _choose_definition()
	return _tile_factory.create_tile_at(definition["enum"], position)


func _load_level_tile_pool(tile_pool) -> void:
	if typeof(tile_pool) != TYPE_DICTIONARY:
		return

	var ids: Array = tile_pool.get("tiles", [])
	var weights: Array = tile_pool.get("weights", [])
	for index in range(ids.size()):
		var definition: Dictionary = _tile_database.get_tile(str(ids[index]))
		if definition.is_empty() or not definition.get("spawnable", false):
			continue
		_level_tile_definitions.append(definition)
		var weight := float(definition.get("spawn_weight", 1.0))
		if index < weights.size():
			weight = float(weights[index])
		_level_tile_weights.append(maxf(0.0, weight))

	if not _level_tile_definitions.is_empty():
		return

	for definition in _tile_database.get_spawnable_tiles():
		_level_tile_definitions.append(definition)
		_level_tile_weights.append(maxf(0.0, float(definition.get("spawn_weight", 1.0))))


func _choose_definition() -> Dictionary:
	return RandomGenerator.weighted_choice(_level_tile_definitions, _level_tile_weights)


func _definition_for_type(tile_type: int) -> Dictionary:
	for definition in _level_tile_definitions:
		if int(definition.get("enum", -1)) == tile_type:
			return definition
	return {}


func _generate_type_grid(width: int, height: int) -> Dictionary:
	for _generation_attempt in range(40):
		var grid: Dictionary = {}
		for y in range(height):
			for x in range(width):
				var position := Vector2i(x, y)
				var candidates := _weighted_candidate_order()
				var selected_type := -1
				for candidate in candidates:
					if not _would_form_initial_match(grid, position, int(candidate["enum"])):
						selected_type = int(candidate["enum"])
						break
				if selected_type < 0:
					selected_type = int(_choose_definition()["enum"])
				grid[position] = selected_type
		if _has_valid_move(grid, width, height):
			return grid
	return {}


func _weighted_candidate_order() -> Array:
	var candidates: Array = []
	var definitions := _level_tile_definitions.duplicate()
	var weights := _level_tile_weights.duplicate()
	while not definitions.is_empty():
		var chosen: Dictionary = RandomGenerator.weighted_choice(definitions, weights)
		var index := definitions.find(chosen)
		candidates.append(chosen)
		definitions.remove_at(index)
		weights.remove_at(index)
	return candidates


func _would_form_initial_match(grid: Dictionary, position: Vector2i, tile_type: int) -> bool:
	if grid.get(position + Vector2i(-1, 0), -1) == tile_type and grid.get(position + Vector2i(-2, 0), -1) == tile_type:
		return true
	if grid.get(position + Vector2i(0, -1), -1) == tile_type and grid.get(position + Vector2i(0, -2), -1) == tile_type:
		return true
	return false


func _has_valid_move(grid: Dictionary, width: int, height: int) -> bool:
	for y in range(height):
		for x in range(width):
			var position := Vector2i(x, y)
			for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
				var neighbor: Vector2i = position + offset
				if not grid.has(neighbor):
					continue
				var first_type: int = grid[position]
				var second_type: int = grid[neighbor]
				grid[position] = second_type
				grid[neighbor] = first_type
				var creates_match := _has_match_at(grid, position, width, height) or _has_match_at(grid, neighbor, width, height)
				grid[position] = first_type
				grid[neighbor] = second_type
				if creates_match:
					return true
	return false


func _has_match_at(grid: Dictionary, position: Vector2i, width: int, height: int) -> bool:
	var tile_type: int = grid.get(position, -1)
	if tile_type < 0:
		return false
	for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
		var count := 1
		for sign_value in [-1, 1]:
			var cursor := position + direction * sign_value
			while cursor.x >= 0 and cursor.y >= 0 and cursor.x < width and cursor.y < height and grid.get(cursor, -1) == tile_type:
				count += 1
				cursor += direction * sign_value
		if count >= 3:
			return true
	return false
