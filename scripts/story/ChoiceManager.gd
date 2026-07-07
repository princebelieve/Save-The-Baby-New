extends Node
class_name ChoiceManager

signal choices_shown(choices: Array)
signal choices_hidden
signal choice_selected(choice: Dictionary)

var _choices: Array = []
var _selected_choice: Dictionary = {}
var _has_active_choices: bool = false


# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	reset()


# =========================================================
# CHOICES DISPLAY
# =========================================================
func show_choices(choice_list: Array) -> void:
	if choice_list.is_empty():
		DebugLogger.error("ChoiceManager: Empty choice list.")
		return

	_choices = choice_list
	_has_active_choices = true
	_selected_choice = {}

	choices_shown.emit(_choices)
	SignalBus.story_choice_presented.emit(_choices)


func hide_choices() -> void:
	_has_active_choices = false
	choices_hidden.emit()
	SignalBus.story_choices_hidden.emit()


# =========================================================
# SELECTION
# =========================================================
func select_choice(choice_id: String) -> void:
	if not _has_active_choices:
		return

	for choice in _choices:
		if choice.has("id") and choice["id"] == choice_id:
			_selected_choice = choice

			choice_selected.emit(choice)
			SignalBus.choice_selected.emit(choice)

			DebugLogger.info("ChoiceManager: Selected choice -> %s" % choice_id)
			return

	DebugLogger.error("ChoiceManager: Choice not found -> %s" % choice_id)


func cancel_choice() -> void:
	_selected_choice = {}

	DebugLogger.info("ChoiceManager: Choice cancelled.")


# =========================================================
# STATE
# =========================================================
func has_choices() -> bool:
	return _has_active_choices and not _choices.is_empty()


func get_selected_choice() -> Dictionary:
	return _selected_choice


func get_choice_result(choice_id: String) -> Dictionary:
	for choice in _choices:
		if choice.has("id") and choice["id"] == choice_id:
			return choice

	return {}


# =========================================================
# UTILITY
# =========================================================
func clear() -> void:
	_choices.clear()
	_selected_choice = {}
	_has_active_choices = false


func reset() -> void:
	clear()