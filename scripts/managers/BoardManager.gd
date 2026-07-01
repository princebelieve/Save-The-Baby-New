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


func initialize() -> void:
	_board = null
	_board_locked = false


func create_board(level_data) -> void:
	clear_board()

	_board = Board.new()
	add_child(_board)

	_board.initialize(level_data)
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

	_board.swap_tiles(tile_a, tile_b)


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