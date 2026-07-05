extends Node
class_name GravitySolver

# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	# Stateless resolver
	pass


# =========================================================
# PUBLIC API
# =========================================================

func apply_gravity(board) -> void:
	if board == null:
		return

	var fall_data = calculate_fall(board)
	_move_tiles(board, fall_data)


func calculate_fall(board) -> Dictionary:
	var fall_map = {}

	var width = board.get_width()
	var height = board.get_height()

	# For each column, process from bottom to top
	for x in range(width):
		var empty_slots = []

		for y in range(height - 1, -1, -1):
			var pos = Vector2i(x, y)

			if not board.has_tile(pos):
				empty_slots.append(pos)
			else:
				if not empty_slots.is_empty():
					var target = empty_slots.pop_front()
					fall_map[pos] = target
					empty_slots.append(pos)

	return fall_map


func get_fall_path(tile, board = null) -> Array:
	if tile == null or board == null:
		return []

	var pos = tile.position
	var width = board.get_width()

	var path = []
	var current_y = pos.y

	while current_y + 1 < board.get_height():
		var below = Vector2i(pos.x, current_y + 1)

		if board.has_tile(below):
			break

		path.append(below)
		current_y += 1

	return path


func has_floating_tiles(board) -> bool:
	var width = board.get_width()
	var height = board.get_height()

	for x in range(width):
		var found_empty_below = false

		for y in range(height - 1, -1, -1):
			var pos = Vector2i(x, y)

			if not board.has_tile(pos):
				found_empty_below = true
			elif found_empty_below:
				return true

	return false


# =========================================================
# INTERNAL LOGIC
# =========================================================

func _move_tiles(board, fall_map: Dictionary) -> void:
	# Apply computed movement
	for from_pos in fall_map.keys():
		var to_pos = fall_map[from_pos]

		var tile = board.get_tile(from_pos)
		if tile == null:
			continue

		board.set_tile(to_pos, tile)
		board.set_tile(from_pos, null)

		# Update tile's internal position reference if it exists
		if tile.has_method("set_position"):
			tile.set_position(to_pos)


func _find_empty_spaces(board) -> Array:
	var empties = []

	for y in range(board.get_height()):
		for x in range(board.get_width()):
			var pos = Vector2i(x, y)

			if not board.has_tile(pos):
				empties.append(pos)

	return empties