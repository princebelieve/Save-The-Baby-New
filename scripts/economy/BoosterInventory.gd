extends Node
class_name BoosterInventory

# =========================================================
# PURPOSE
# =========================================================
# Stores all boosters owned outside gameplay.
#
# Rules:
# - Inventory only
# - No gameplay logic
# - No powerup behavior
# - No reward logic
# - No UI logic
# - No save logic
#
# Powerup behavior belongs to Powerup System.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _boosters: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


func reset() -> void:
	clear()


# =========================================================
# INVENTORY
# =========================================================

func add_booster(type: String, amount: int) -> void:
	if amount <= 0:
		return

	if not _boosters.has(type):
		_boosters[type] = 0

	_boosters[type] += amount


func remove_booster(type: String, amount: int) -> void:
	if amount <= 0:
		return

	if not _boosters.has(type):
		return

	_boosters[type] = max(0, _boosters[type] - amount)


func use_booster(type: String) -> bool:
	# IMPORTANT:
	# This only consumes inventory.
	# It does NOT trigger gameplay effects.
	# That belongs to Powerup System.

	if not has_booster(type):
		return false

	remove_booster(type, 1)
	return true


func get_booster_count(type: String) -> int:
	if not _boosters.has(type):
		return 0

	return _boosters[type]


func has_booster(type: String) -> bool:
	return get_booster_count(type) > 0


func get_all_boosters() -> Dictionary:
	return _boosters.duplicate(true)


func clear() -> void:
	_boosters.clear()
