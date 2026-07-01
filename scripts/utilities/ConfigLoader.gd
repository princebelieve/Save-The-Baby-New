extends Node
class_name ConfigLoader

# =========================================================
# PURPOSE
# Loads and caches configuration files.
# Used by managers.
# Never owns gameplay.
# =========================================================

var _cache: Dictionary = {}

# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	_cache.clear()


# =========================================================
# CORE CONTROL
# =========================================================

func reload() -> void:
	_cache.clear()


func clear_cache() -> void:
	_cache.clear()


# =========================================================
# LOADING
# =========================================================

func load(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]

	var data = JsonLoader.load_file(path)

	if typeof(data) != TYPE_DICTIONARY:
		DebugLogger.error("ConfigLoader: Invalid config format (expected Dictionary) -> " + path)
		return {}

	_cache[path] = data
	return data


func reload_file(path: String) -> Dictionary:
	_cache.erase(path)
	return load(path)


# =========================================================
# QUERY API
# =========================================================

func has(path: String) -> bool:
	return _cache.has(path)


func get(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]

	return load(path)


func get_value(path: String, key: String, default = null):
	var data = get(path)

	if typeof(data) != TYPE_DICTIONARY:
		return default

	if data.has(key):
		return data[key]

	return default


func get_section(path: String, section: String) -> Dictionary:
	var data = get(path)

	if typeof(data) != TYPE_DICTIONARY:
		return {}

	if data.has(section) and typeof(data[section]) == TYPE_DICTIONARY:
		return data[section]

	return {}


# =========================================================
# INTERNAL VALIDATION (PRIVATE)
# =========================================================

func _validate(path: String, data) -> bool:
	if data == null:
		DebugLogger.error("ConfigLoader: Null config -> " + path)
		return false

	if typeof(data) != TYPE_DICTIONARY:
		DebugLogger.error("ConfigLoader: Config is not a dictionary -> " + path)
		return false

	return true