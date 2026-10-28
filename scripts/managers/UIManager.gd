extends Node
class_name UIManagerService

# =========================================================
# SIGNALS
# =========================================================
signal popup_opened(name)
signal popup_closed(name)
signal hud_updated

# =========================================================
# INTERNAL STATE
# =========================================================
var _current_screen: String = ""
var _open_popups: Array = []
var _input_locked: bool = false
var _is_initialized: bool = false


# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	if _is_initialized:
		return

	_current_screen = ""
	_open_popups.clear()
	_input_locked = false
	_is_initialized = true


func _ready() -> void:
	initialize()


# =========================================================
# SCREENS
# =========================================================
func show_screen(name: String) -> void:
	if name == "":
		return

	_current_screen = name

	SignalBus.popup_requested.emit(name, {})
	popup_opened.emit(name)


func hide_screen(name: String) -> void:
	if _current_screen != name:
		return

	_current_screen = ""

	popup_closed.emit(name)
	SignalBus.popup_closed.emit(name)


# =========================================================
# HUD
# =========================================================
func update_hud() -> void:
	hud_updated.emit()
	SignalBus.hud_updated.emit()


# =========================================================
# POPUPS
# =========================================================
func show_popup(name: String, data: Dictionary = {}) -> void:
	if name == "":
		return

	if not _open_popups.has(name):
		_open_popups.append(name)

	popup_opened.emit(name)
	SignalBus.popup_requested.emit(name, data)


func hide_popup(name: String) -> void:
	if _open_popups.has(name):
		_open_popups.erase(name)

	popup_closed.emit(name)
	SignalBus.popup_closed.emit(name)


func close_all_popups() -> void:
	for popup in _open_popups.duplicate():
		hide_popup(popup)


# =========================================================
# NOTIFICATIONS
# =========================================================
func show_notification(text: String) -> void:
	SignalBus.debug_message.emit(text)


func hide_notification() -> void:
	pass


# =========================================================
# INPUT CONTROL
# =========================================================
func lock_input() -> void:
	_input_locked = true


func unlock_input() -> void:
	_input_locked = false


func is_input_locked() -> bool:
	return _input_locked


# =========================================================
# UI LIFECYCLE
# =========================================================
func reset() -> void:
	_current_screen = ""
	_open_popups.clear()
	_input_locked = false


func shutdown() -> void:
	reset()
	_is_initialized = false


# =========================================================
# GAMEPLAY INTENT BRIDGE (CRITICAL MISSING PART)
# =========================================================
# These DO NOT execute gameplay.
# They forward intent to the appropriate manager layer.

func request_resume_game() -> void:
	SignalBus.game_resumed.emit()


func request_restart_level() -> void:
	SignalBus.game_restarted.emit()


func request_return_to_menu() -> void:
	SignalBus.game_quit.emit()


func request_open_settings() -> void:
	show_popup("Settings", {})


func request_quit_game() -> void:
	SignalBus.game_quit.emit()


func request_next_level() -> void:
	SignalBus.next_level_requested.emit()
