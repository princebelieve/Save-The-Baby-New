class_name BoardConfig
extends Resource

# ============================================================================
# BOARD CONFIGURATION
# ----------------------------------------------------------------------------
# This resource stores the board settings.
#
# Phase 1:
#   - Default values are used.
#
# Future:
#   - LevelManager will create or load a BoardConfig from level JSON.
#   - BoardManager will only read values from this object.
# ============================================================================


# ============================================================================
# BOARD SIZE
# ============================================================================

@export_range(4, 20)
var columns: int = 8

@export_range(4, 20)
var rows: int = 8


# ============================================================================
# TILE SETTINGS
# ============================================================================

@export_range(32, 256)
var tile_size: int = 96

# World position of the top-left tile.
@export
var board_origin: Vector2 = Vector2.ZERO


# ============================================================================
# SPAWN SETTINGS
# ============================================================================

# List of collectible tile IDs that may appear on this board.
# Later this will come from each level's JSON.
@export
var spawn_pool: Array[String] = [
	"key",
	"phone",
	"fingerprint",
	"recorder",
	"tape",
	"clock"
]

# Prevent empty boards.
func validate() -> void:
	if columns < 1:
		columns = 1

	if rows < 1:
		rows = 1

	if tile_size < 1:
		tile_size = 1

	if spawn_pool.is_empty():
		spawn_pool = [
			"key",
			"phone",
			"fingerprint",
			"recorder",
			"tape",
			"clock"
		]


# ============================================================================
# GETTERS
# ============================================================================

func get_columns() -> int:
	return columns


func get_rows() -> int:
	return rows


func get_tile_size() -> int:
	return tile_size


func get_board_origin() -> Vector2:
	return board_origin


func get_spawn_pool() -> Array[String]:
	return spawn_pool.duplicate()


func get_board_width_pixels() -> int:
	return columns * tile_size


func get_board_height_pixels() -> int:
	return rows * tile_size


func get_total_tiles() -> int:
	return columns * rows


func get_board_size() -> Vector2i:
	return Vector2i(columns, rows)


# ============================================================================
# BOARD HELPERS
# ============================================================================

func is_inside_board(column: int, row: int) -> bool:
	return (
		column >= 0
		and column < columns
		and row >= 0
		and row < rows
	)


func board_to_world(column: int, row: int) -> Vector2:
	return board_origin + Vector2(
		column * tile_size,
		row * tile_size
	)


func world_to_board(world_position: Vector2) -> Vector2i:
	var local := world_position - board_origin

	return Vector2i(
		int(local.x / tile_size),
		int(local.y / tile_size)
	)


# ============================================================================
# RANDOM TILE
# ============================================================================

func get_random_tile_id() -> String:
	if spawn_pool.is_empty():
		return ""

	return spawn_pool.pick_random()


# ============================================================================
# DEBUG
# ============================================================================

func print_summary() -> void:
	print("--------------------------------")
	print("BOARD CONFIG")
	print("--------------------------------")
	print("Columns: ", columns)
	print("Rows: ", rows)
	print("Tile Size: ", tile_size)
	print("Origin: ", board_origin)
	print("Spawn Pool: ", spawn_pool)
	print("Total Tiles: ", get_total_tiles())
	print("--------------------------------")