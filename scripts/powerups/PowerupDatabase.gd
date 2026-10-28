extends Node
class_name PowerupDatabase


# =========================================================
# PURPOSE
# Loads and provides access to powerup definitions.
#
# Responsibilities:
# - Cache powerup configuration data
# - Provide lookup functions
#
# Contains:
# - No gameplay logic
# - No creation logic
# - No activation logic
# - No resource loading
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _powerup_cache: Dictionary = {}


const POWERUP_CONFIG_PATH := Constants.ConfigPaths.POWERUPS


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_powerup_cache.clear()

	_load_database()


func reload() -> void:
	clear()

	_load_database()


func clear() -> void:
	_powerup_cache.clear()


# =========================================================
# LOOKUP
# =========================================================

func get_powerup(id):
	return _powerup_cache.get(id, {})


func has_powerup(id) -> bool:
	return _powerup_cache.has(id)


func get_powerup_by_enum(type):
	for powerup in _powerup_cache.values():
		if powerup.get("enum") == type:
			return powerup

	return {}


func get_name(type):
	var data := get_powerup_by_enum(type)

	return data.get("name", "")


func get_texture_path(type):
	var data := get_powerup_by_enum(type)

	return data.get("texture", "")


func get_icon_path(type):
	var data := get_powerup_by_enum(type)

	return data.get("icon", "")


func get_animation_set(type):
	var data := get_powerup_by_enum(type)

	return data.get("animation_set", {})


func get_activation_type(type):
	var data := get_powerup_by_enum(type)

	return data.get("activation_type", null)


func get_combination_rules(type):
	var data := get_powerup_by_enum(type)

	return data.get("combination_rules", {})


func get_description(type):
	var data := get_powerup_by_enum(type)

	return data.get("description", "")


# =========================================================
# COLLECTIONS
# =========================================================

func get_all() -> Dictionary:
	return _powerup_cache


func get_match_created() -> Array:
	var result: Array = []

	for powerup in _powerup_cache.values():
		if powerup.get("created_by_match", false):
			result.append(powerup)

	return result


func get_booster_created() -> Array:
	var result: Array = []

	for powerup in _powerup_cache.values():
		if powerup.get("created_by_booster", false):
			result.append(powerup)

	return result


func get_combinable() -> Array:
	var result: Array = []

	for powerup in _powerup_cache.values():
		if powerup.get("combinable", false):
			result.append(powerup)

	return result


# =========================================================
# INTERNAL LOADING
# =========================================================

func _load_database() -> void:
	var data := ConfigLoader.get(POWERUP_CONFIG_PATH)

	if data.is_empty():
		DebugLogger.error("PowerupDatabase: Failed loading powerup config.")
		return


	if data.has("powerups") and typeof(data["powerups"]) == TYPE_DICTIONARY:
		_powerup_cache = data["powerups"]
	else:
		_powerup_cache = data
