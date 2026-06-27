extends Node

##
## GameManager
##
## Controls the overall game flow.
## Additional functionality will be added throughout development.
##


# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------

signal game_started

# -------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------

var current_level: int = 1

# -------------------------------------------------------------------
# Godot Lifecycle
# -------------------------------------------------------------------

func _ready() -> void:
	print("GameManager initialized.")
	emit_signal("game_started")