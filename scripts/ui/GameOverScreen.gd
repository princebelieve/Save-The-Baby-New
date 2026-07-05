extends Control
class_name GameOverScreen

# =========================================================
# PURPOSE
# =========================================================
# Displays level failure information.
#
# ONLY RESPONSIBILITIES:
# - Show game over UI
# - Display reason and objectives
# - Play UI animations
# - Forward user actions to UIManager
#
# DOES NOT:
# - Control game flow
# - Modify economy directly
# - Decide gameplay outcomes

# =========================================================
# STATE
# =========================================================

var _ui_manager: UIManager = null
var _is_visible: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	reset()
	hide_results(null)


# =========================================================
# RESULTS DISPLAY
# =========================================================

func show_results(result) -> void:
	_is_visible = true
	visible = true


func hide_results(result = null) -> void:
	_is_visible = false
	visible = false


func set_reason(reason: String) -> void:
	pass  # UI binding only


func set_remaining_objectives(objectives) -> void:
	pass  # UI binding only


# =========================================================
# NAVIGATION (FORWARD ONLY)
# =========================================================

func retry_level() -> void:
	if _ui_manager:
		_ui_manager.restart_level()


func return_to_menu() -> void:
	if _ui_manager:
		_ui_manager.return_to_menu()


func watch_reward_ad() -> void:
	if _ui_manager:
		_ui_manager.show_popup("RewardAd")


func buy_extra_moves() -> void:
	if _ui_manager:
		_ui_manager.show_popup("Shop")


# =========================================================
# ANIMATION (UI ONLY)
# =========================================================

func play_open_animation() -> void:
	pass


func play_close_animation() -> void:
	pass


# =========================================================
# UTILITY
# =========================================================

func reset() -> void:
	_is_visible = false
	visible = false