class_name BoardManager
extends Node2D

# ============================================================================
# BOARD MANAGER
#
# Phase 1
#
# Responsibilities in this milestone:
#
# - Create board
# - Create grid
# - Spawn tiles
# - Position tiles
# - Store board state
#
# NOT YET:
#
# - Swapping
# - Match detection
# - Gravity
# - Refill
# - Cascades
# - Objectives
# ============================================================================


# ============================================================================
# CONFIGURATION
# ============================================================================

const BoardConfig = preload("res://scripts/board/BoardConfig.gd")
const TILE_SCENE = preload("res://scenes/board/Tile.tscn")


# ============================================================================
# NODES
# ============================================================================

@onready var tiles_container: Node2D = $Tiles


# ============================================================================
# BOARD DATA
# ============================================================================

var board : Array = []


# ============================================================================
# READY
# ============================================================================

func _ready() -> void:

	create_empty_board()
	spawn_initial_board()


# ============================================================================
# BOARD CREATION
# ============================================================================

func create_empty_board() -> void:

	board.clear()

	for row in BoardConfig.BOARD_HEIGHT:

		var board_row : Array = []

		for column in BoardConfig.BOARD_WIDTH:

			board_row.append(null)

		board.append(board_row)


# ============================================================================
# INITIAL SPAWN
# ============================================================================

func spawn_initial_board() -> void:

	for row in BoardConfig.BOARD_HEIGHT:

		for column in BoardConfig.BOARD_WIDTH:

			spawn_tile(column, row)


# ============================================================================
# SPAWN TILE
# ============================================================================

func spawn_tile(column:int, row:int) -> void:

	var tile:Tile = TILE_SCENE.instantiate()

	tiles_container.add_child(tile)

	var world_position := grid_to_world(column, row)

	tile.position = world_position

	tile.column = column
	tile.row = row

	board[row][column] = tile


# ============================================================================
# GRID -> WORLD
# ============================================================================

func grid_to_world(column:int, row:int) -> Vector2:

	var x := column * BoardConfig.TILE_SIZE
	var y := row * BoardConfig.TILE_SIZE

	return Vector2(x, y)


# ============================================================================
# WORLD -> GRID
# ============================================================================

func world_to_grid(position:Vector2) -> Vector2i:

	var column := int(position.x / BoardConfig.TILE_SIZE)
	var row := int(position.y / BoardConfig.TILE_SIZE)

	return Vector2i(column, row)


# ============================================================================
# GET TILE
# ============================================================================

func get_tile(column:int, row:int) -> Tile:

	if not is_inside_board(column, row):
		return null

	return board[row][column]


# ============================================================================
# SET TILE
# ============================================================================

func set_tile(column:int, row:int, tile:Tile) -> void:

	if not is_inside_board(column, row):
		return

	board[row][column] = tile


# ============================================================================
# BOARD LIMITS
# ============================================================================

func is_inside_board(column:int, row:int) -> bool:

	return (
		column >= 0
		and column < BoardConfig.BOARD_WIDTH
		and row >= 0
		and row < BoardConfig.BOARD_HEIGHT
	)


# ============================================================================
# DEBUG
# ============================================================================

func print_board() -> void:

	print("--------------------------------")

	for row in BoardConfig.BOARD_HEIGHT:

		var line := ""

		for column in BoardConfig.BOARD_WIDTH:

			if board[row][column] == null:
				line += "[ ]"
			else:
				line += "[X]"

		print(line)

	print("--------------------------------")
