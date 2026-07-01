extends Node

class_name DebugLogger

# =========================================================
# PURPOSE
#
# Central logging utility.
#
# Rules:
# - No gameplay logic.
# - No manager dependencies.
# - No coordination responsibilities.
# - Can be disabled in release builds.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _enabled: bool = true


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	# Automatically disable logging in release builds.
	_enabled = OS.is_debug_build()


# =========================================================
# PUBLIC LOGGING API
# =========================================================

func info(message) -> void:
	if not _enabled:
		return

	print("[INFO] ", str(message))


func warning(message) -> void:
	if not _enabled:
		return

	push_warning(str(message))


func error(message) -> void:
	if not _enabled:
		return

	push_error(str(message))


func debug(message) -> void:
	if not _enabled:
		return

	print("[DEBUG] ", str(message))


# =========================================================
# LOG CONTROL
# =========================================================

func clear_log() -> void:
	# Godot does not expose an API to clear the Output panel.
	# This function exists to satisfy the frozen public API.
	pass


func enable() -> void:
	_enabled = true


func disable() -> void:
	_enabled = false