extends Node
class_name ObstacleDatabase

# =========================================================
# INTERNAL CACHE
# =========================================================

var _obstacle_cache: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reload()


func reload() -> void:
	clear()

	# Loads from ConfigLoader (data layer only)
	var data = ConfigLoader.load_config("obstacles")

	if data == null:
		DebugLogger.log_error("ObstacleDatabase: Failed to load obstacles config")
		return

	if typeof(data) != TYPE_DICTIONARY:
		DebugLogger.log_error("ObstacleDatabase: Invalid obstacles config format")
		return

	_obstacle_cache = data


func clear() -> void:
	_obstacle_cache.clear()


# =========================================================
# LOOKUP
# =========================================================

func get_obstacle(id: String):
	if not _obstacle_cache.has(id):
		return null
	return _obstacle_cache[id]


func has_obstacle(id: String) -> bool:
	return _obstacle_cache.has(id)


func get_obstacle_by_enum(type):
	for key in _obstacle_cache.keys():
		var entry = _obstacle_cache[key]
		if entry.has("type") and entry["type"] == type:
			return entry
	return null


func get_name(type):
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return ""
	return entry.get("name", "")


func get_texture_path(type):
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return ""
	return entry.get("texture", "")


func get_animation_set(type):
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return null
	return entry.get("animation_set", null)


func get_health(type):
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return 0
	return entry.get("health", 0)


func get_destroy_score(type):
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return 0
	return entry.get("destroy_score", 0)


# =========================================================
# COLLECTIONS
# =========================================================

func get_all() -> Array:
	return _obstacle_cache.values()


func get_removable() -> Array:
	var result := []
	for entry in _obstacle_cache.values():
		if entry.get("removable", false):
			result.append(entry)
	return result


func get_blocking() -> Array:
	var result := []
	for entry in _obstacle_cache.values():
		if entry.get("blocks_gravity", false):
			result.append(entry)
	return result


func get_hidden() -> Array:
	var result := []
	for entry in _obstacle_cache.values():
		if entry.get("hidden", false):
			result.append(entry)
	return result


# =========================================================
# VALIDATION (READ-ONLY RULE CHECKS)
# =========================================================

func is_removable(type) -> bool:
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return false
	return entry.get("removable", false)


func blocks_matching(type) -> bool:
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return false
	return entry.get("blocks_matching", false)


func blocks_gravity(type) -> bool:
	var entry = get_obstacle_by_enum(type)
	if entry == null:
		return false
	return entry.get("blocks_gravity", false)