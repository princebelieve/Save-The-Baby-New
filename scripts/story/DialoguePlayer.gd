extends Node
class_name DialoguePlayer

signal line_changed(line_data: Dictionary)
signal dialogue_started
signal dialogue_finished
signal index_changed(index: int)

var _dialogue: Array = []
var _current_index: int = -1
var _is_active: bool = false


# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	reset()


# =========================================================
# DIALOGUE LOADING
# =========================================================
func load_dialogue(dialogue_data: Array) -> void:
	if dialogue_data.is_empty():
		DebugLogger.error("DialoguePlayer: Empty dialogue data.")
		return

	_dialogue = dialogue_data
	_current_index = -1

	DebugLogger.info("DialoguePlayer: Dialogue loaded (%d lines)." % _dialogue.size())


func start() -> void:
	if _dialogue.is_empty():
		DebugLogger.error("DialoguePlayer: Cannot start empty dialogue.")
		return

	_is_active = true
	_current_index = 0

	dialogue_started.emit()
	show_line(_dialogue[_current_index])


func stop() -> void:
	_is_active = false
	dialogue_finished.emit()


func restart() -> void:
	if _dialogue.is_empty():
		return

	_current_index = 0
	_is_active = true

	show_line(_dialogue[_current_index])


# =========================================================
# NAVIGATION
# =========================================================
func next_line() -> void:
	if not _is_active:
		return

	if not has_next_line():
		stop()
		return

	_current_index += 1
	index_changed.emit(_current_index)

	show_line(_dialogue[_current_index])


func previous_line() -> void:
	if not _is_active:
		return

	if _current_index <= 0:
		return

	_current_index -= 1
	index_changed.emit(_current_index)

	show_line(_dialogue[_current_index])


func skip() -> void:
	if _dialogue.is_empty():
		return

	_current_index = _dialogue.size() - 1
	index_changed.emit(_current_index)

	show_line(_dialogue[_current_index])


# =========================================================
# STATE QUERIES
# =========================================================
func is_finished() -> bool:
	return _current_index >= _dialogue.size() - 1


func get_current_line() -> Dictionary:
	if _dialogue.is_empty() or _current_index < 0:
		return {}

	return _dialogue[_current_index]


func get_current_index() -> int:
	return _current_index


func get_total_lines() -> int:
	return _dialogue.size()


func has_next_line() -> bool:
	return _current_index + 1 < _dialogue.size()


# =========================================================
# DISPLAY
# =========================================================
func show_line(line_data: Dictionary) -> void:
	if line_data.is_empty():
		return

	line_changed.emit(line_data)


func hide() -> void:
	line_changed.emit({})


func clear() -> void:
	_dialogue.clear()
	reset()


# =========================================================
# UTILITY
# =========================================================
func reset() -> void:
	_dialogue = []
	_current_index = -1
	_is_active = false