extends Node
class_name EthanInventory

# =========================================================
# PURPOSE
# =========================================================
# Owns all persistent Ethan-related resources.
#
# Ethan is a special gameplay mechanic, so it is NOT treated
# as a standard booster.
#
# Rules:
# - Stores ownership only
# - Tracks availability
# - Handles suggestion state
# - No board logic
# - No tile logic
# - No reward logic
# - No gameplay execution
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _ethan_count: int = 0
var _suggestion_shown: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


func reset() -> void:
	_ethan_count = 0
	_suggestion_shown = false


# =========================================================
# INVENTORY
# =========================================================

func add_ethan(amount: int) -> void:
	if amount <= 0:
		return

	_ethan_count += amount


func remove_ethan(amount: int) -> void:
	if amount <= 0:
		return

	_ethan_count = max(0, _ethan_count - amount)


func use_ethan() -> bool:
	# IMPORTANT:
	# This only consumes inventory.
	# Actual Ethan gameplay effect (board interaction, tile logic)
	# belongs to Board/Tile systems.

	if _ethan_count <= 0:
		return false

	_ethan_count -= 1
	return true


func get_ethan_count() -> int:
	return _ethan_count


func has_ethan() -> bool:
	return _ethan_count > 0


# =========================================================
# SUGGESTIONS
# =========================================================

func can_suggest_ethan() -> bool:
	return _ethan_count > 0 and not _suggestion_shown


func mark_suggestion_shown() -> void:
	_suggestion_shown = true


func reset_suggestion() -> void:
	_suggestion_shown = false
