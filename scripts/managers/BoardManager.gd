extends Node

signal board_created
signal board_ready
signal board_locked
signal board_unlocked
signal board_cleared


var _board: Board = null
var _board_locked: bool = false


func _ready() -> void:
	initialize()
	if not SignalBus.level_loaded.is_connected(_on_level_loaded):
		SignalBus.level_loaded.connect(_on_level_loaded)


func initialize() -> void:
	_board = null
	_board_locked = false


func create_board(level_data) -> void:
	clear_board()

	var board_scene := ResourceManager.load_scene(Constants.ScenePaths.BOARD)
	if board_scene == null:
		DebugLogger.error("BoardManager: Board scene could not be loaded.")
		return
	_board = board_scene.instantiate() as Board
	if _board == null:
		DebugLogger.error("BoardManager: Board scene has no Board script.")
		return
	var board_root := get_tree().get_first_node_in_group("board_root")
	if board_root == null:
		DebugLogger.error("BoardManager: BoardRoot is missing from the game scene.")
		_board = null
		return
	board_root.add_child(_board)

	if not _board.initialize(level_data):
		DebugLogger.error("BoardManager: Failed to initialize the board.")
		clear_board()
		return
	_board_locked = false

	board_created.emit()
	SignalBus.board_created.emit()

	board_ready.emit()
	SignalBus.board_ready.emit()


func clear_board() -> void:
	if _board != null:
		_board.clear()
		_board.queue_free()
		_board = null

	_board_locked = false

	board_cleared.emit()
	SignalBus.board_cleared.emit()


func reset_board() -> void:
	if _board == null:
		return

	_board.reset()
	_board_locked = false

	board_ready.emit()
	SignalBus.board_ready.emit()


func lock_board() -> void:
	if _board_locked:
		return

	_board_locked = true

	if _board != null:
		_board.lock()

	board_locked.emit()
	SignalBus.board_locked.emit()


func unlock_board() -> void:
	if not _board_locked:
		return

	_board_locked = false

	if _board != null:
		_board.unlock()

	board_unlocked.emit()
	SignalBus.board_unlocked.emit()


func is_board_locked() -> bool:
	return _board_locked


func get_board() -> Board:
	return _board


func get_tile(position):
	if _board == null:
		return null

	return _board.get_tile(position)


func swap_tiles(tile_a, tile_b) -> void:
	if _board == null:
		return

	if _board_locked:
		return

	if tile_a == null or tile_b == null:
		return

	_board.swap_tiles(tile_a.get_grid_position(), tile_b.get_grid_position())


func refill_board() -> void:
	if _board == null:
		return

	_board.update()


func update_board() -> void:
	if _board == null:
		return

	_board.update()


func is_board_stable() -> bool:
	if _board == null:
		return true

	return _board.is_stable()


func _on_level_loaded(level_data: Dictionary) -> void:
	create_board(level_data)
