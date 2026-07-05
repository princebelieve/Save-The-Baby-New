extends Control
class_name PauseMenu

var _ui_manager: UIManager = null
var _is_visible: bool = false


func initialize(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	reset()
	hide_menu()


func show_menu() -> void:
	_is_visible = true
	visible = true


func hide_menu() -> void:
	_is_visible = false
	visible = false


func toggle() -> void:
	if _is_visible:
		hide_menu()
	else:
		show_menu()


func is_visible() -> bool:
	return _is_visible


# =========================================================
# ACTIONS → ALWAYS FORWARD TO UIManager
# =========================================================

func resume_game() -> void:
	if _ui_manager:
		_ui_manager.request_resume_game()


func restart_level() -> void:
	if _ui_manager:
		_ui_manager.request_restart_level()


func open_settings() -> void:
	if _ui_manager:
		_ui_manager.request_open_settings()


func return_to_menu() -> void:
	if _ui_manager:
		_ui_manager.request_return_to_menu()


func quit_game() -> void:
	if _ui_manager:
		_ui_manager.request_quit_game()


func reset() -> void:
	_is_visible = false
	visible = false