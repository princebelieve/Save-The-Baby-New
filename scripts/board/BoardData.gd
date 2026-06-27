extends RefCounted

class_name BoardData


var width: int = 0
var height: int = 0

var tiles: Array = []


func initialize(board_width: int, board_height: int) -> void:
	width = board_width
	height = board_height

	tiles.clear()

	for y in range(height):
		var row: Array = []
		row.resize(width)

		for x in range(width):
			row[x] = null

		tiles.append(row)


func clear() -> void:
	for y in range(height):
		for x in range(width):
			tiles[y][x] = null


func is_inside(x: int, y: int) -> bool:
	return (
		x >= 0
		and x < width
		and y >= 0
		and y < height
	)


func has_tile(x: int, y: int) -> bool:
	if not is_inside(x, y):
		return false

	return tiles[y][x] != null


func get_tile(x: int, y: int) -> Tile:
	if not is_inside(x, y):
		return null

	return tiles[y][x]


func set_tile(x: int, y: int, tile: Tile) -> void:
	if not is_inside(x, y):
		return

	tiles[y][x] = tile

	if tile != null:
		tile.set_grid_position(Vector2i(x, y))


func remove_tile(x: int, y: int) -> Tile:
	if not is_inside(x, y):
		return null

	var tile: Tile = tiles[y][x]
	tiles[y][x] = null

	return tile


func move_tile(
	from_x: int,
	from_y: int,
	to_x: int,
	to_y: int
) -> bool:

	if not is_inside(from_x, from_y):
		return false

	if not is_inside(to_x, to_y):
		return false

	var tile := get_tile(from_x, from_y)

	if tile == null:
		return false

	tiles[to_y][to_x] = tile
	tiles[from_y][from_x] = null

	tile.set_grid_position(Vector2i(to_x, to_y))

	return true


func swap_tiles(
	x1: int,
	y1: int,
	x2: int,
	y2: int
) -> bool:

	if not is_inside(x1, y1):
		return false

	if not is_inside(x2, y2):
		return false

	var first := get_tile(x1, y1)
	var second := get_tile(x2, y2)

	tiles[y1][x1] = second
	tiles[y2][x2] = first

	if first != null:
		first.set_grid_position(Vector2i(x2, y2))

	if second != null:
		second.set_grid_position(Vector2i(x1, y1))

	return true


func get_row(row: int) -> Array:
	if row < 0 or row >= height:
		return []

	return tiles[row]


func get_column(column: int) -> Array:
	if column < 0 or column >= width:
		return []

	var result: Array = []

	for y in range(height):
		result.append(tiles[y][column])

	return result


func get_neighbors(x: int, y: int) -> Array:
	var neighbors: Array = []

	var offsets := [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]

	for offset in offsets:
		var nx := x + offset.x
		var ny := y + offset.y

		if is_inside(nx, ny):
			var tile := get_tile(nx, ny)

			if tile != null:
				neighbors.append(tile)

	return neighbors


func get_all_tiles() -> Array:
	var result: Array = []

	for y in range(height):
		for x in range(width):
			var tile := tiles[y][x]

			if tile != null:
				result.append(tile)

	return result


func count_tiles() -> int:
	var count := 0

	for y in range(height):
		for x in range(width):
			if tiles[y][x] != null:
				count += 1

	return count


func is_full() -> bool:
	return count_tiles() == width * height


func is_empty() -> bool:
	return count_tiles() == 0


func duplicate_board() -> BoardData:
	var copy := BoardData.new()

	copy.initialize(width, height)

	for y in range(height):
		for x in range(width):
			copy.tiles[y][x] = tiles[y][x]

	return copy


func to_dictionary() -> Dictionary:
	var board: Array = []

	for y in range(height):
		var row: Array = []

		for x in range(width):
			var tile := tiles[y][x]

			if tile == null:
				row.append(null)
			else:
				row.append(tile.get_tile_type())

		board.append(row)

	return {
		"width": width,
		"height": height,
		"tiles": board
	}


func print_board() -> void:
	print("--------------------------------")

	for y in range(height):
		var line := ""

		for x in range(width):
			var tile := tiles[y][x]

			if tile == null:
				line += ". "
			else:
				line += "%d " % tile.get_tile_type()

		print(line)

	print("--------------------------------")