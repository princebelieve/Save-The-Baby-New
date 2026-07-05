extends Control
class_name VictoryScreen

var _ui_manager: UIManager = null
var _is_visible: bool = false


func initialize(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	reset()
	hide_results()


func show_results(result) -> void:
	_is_visible = true
	visible = true


func hide_results() -> void:
	_is_visible = false
	visible = false


func set_score(score: int) -> void:
	pass


func set_stars(stars: int) -> void:
	pass


func set_rewards(rewards) -> void:
	pass


# =========================================================
# NAVIGATION → UIManager only forwards INTENT
# =========================================================

func next_level() -> void:
	if _ui_manager:
		_ui_manager.request_next_level()


func replay_level() -> void:
	if _ui_manager:
		_ui_manager.request_restart_level()


func return_to_menu() -> void:
	if _ui_manager:
		_ui_manager.request_return_to_menu()


func play_open_animation() -> void:
	pass


func play_close_animation() -> void:
	pass


func reset() -> void:
	_is_visible = false
	visible = false