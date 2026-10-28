extends Control
class_name LoadingScreen

# =========================================================
# PURPOSE
# =========================================================
# Displays loading progress during scene transitions.
#
# ONLY RESPONSIBILITIES:
# - Show loading UI
# - Display progress and messages
# - Handle spinner visuals
# - Forward no gameplay logic
#
# DOES NOT:
# - Load scenes
# - Control game flow
# - Decide when loading starts/stops

# =========================================================
# STATE
# =========================================================

var _is_visible: bool = false
var _progress: float = 0.0


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()
	hide()


# =========================================================
# LOADING FLOW
# =========================================================

func start_loading() -> void:
	_is_visible = true
	visible = true
	_progress = 0.0


func finish_loading() -> void:
	_progress = 1.0


func cancel_loading() -> void:
	_progress = 0.0
	hide()


func set_progress(percent: float) -> void:
	_progress = clamp(percent, 0.0, 1.0)


func get_progress() -> float:
	return _progress


# =========================================================
# DISPLAY
# =========================================================

func set_message(text: String) -> void:
	pass  # UI binding only


func show_spinner() -> void:
	pass  # handled by UI animation


func hide_spinner() -> void:
	pass


# =========================================================
# VISIBILITY
# =========================================================

# =========================================================
# UTILITY
# =========================================================

func reset() -> void:
	_is_visible = false
	_progress = 0.0
	visible = false
