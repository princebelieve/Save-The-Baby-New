extends Node

signal game_started
signal game_paused
signal game_resumed
signal game_restarted
signal game_quit
signal game_state_changed(previous_state, current_state)

var _current_state: int = Constants.GameState.NONE
var _is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _is_initialized:
		return

	_is_initialized = true
	_current_state = Constants.GameState.NONE


func start_game() -> void:
	if is_game_running():
		return

	set_state(Constants.GameState.RUNNING)

	game_started.emit()
	SignalBus.game_started.emit()


func pause_game() -> void:
	if not is_game_running():
		return

	set_state(Constants.GameState.PAUSED)

	game_paused.emit()
	SignalBus.game_paused.emit()


func resume_game() -> void:
	if not is_game_paused():
		return

	set_state(Constants.GameState.RUNNING)

	game_resumed.emit()
	SignalBus.game_resumed.emit()


func restart_game() -> void:
	reset_game()

	game_restarted.emit()
	SignalBus.game_restarted.emit()

	start_game()


func quit_game() -> void:
	set_state(Constants.GameState.QUIT)

	game_quit.emit()
	SignalBus.game_quit.emit()

	get_tree().quit()


func set_state(state: int) -> void:
	if _current_state == state:
		return

	var previous_state := _current_state
	_current_state = state

	game_state_changed.emit(previous_state, _current_state)
	SignalBus.game_state_changed.emit(previous_state, _current_state)


func get_state() -> int:
	return _current_state


func is_state(state: int) -> bool:
	return _current_state == state


func is_game_running() -> bool:
	return _current_state == Constants.GameState.RUNNING


func is_game_paused() -> bool:
	return _current_state == Constants.GameState.PAUSED


func reset_game() -> void:
	_current_state = Constants.GameState.NONE