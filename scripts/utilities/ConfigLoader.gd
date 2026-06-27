extends Node
class_name ConfigLoader

# --------------------------------------------------
# ConfigLoader.gd (Version 1.0 Freeze)
#
# Purpose:
# Loads and caches configuration files.
#
# Rules:
# - Used by managers
# - Never owns gameplay
# - No gameplay logic
# - No coordination logic
# --------------------------------------------------


# =========================
# Internal State
# =========================
var _cache: Dictionary = {}


# =========================
# Initialization
# =========================
func initialize() -> void:
	_cache.clear()


# =========================
# Public API
# =========================
func reload() -> void:
	_cache.clear()


func clear_cache() -> void:
	_cache.clear()


func load(path: String):
	if _cache.has(path):
		return _cache[path]

	if not FileHelper.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if not _validate(data):
		return null

	_cache[path] = data
	return data


func reload_file(path: String):
	_cache.erase(path)
	return load(path)


func has(path: String) -> bool:
	return _cache.has(path)


func get(path: String):
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


func get_section(path: String, section: String):
	var data = get(path)

	if typeof(data) != TYPE_DICTIONARY:
		return null

	if data.has(section) and typeof(data[section]) == TYPE_DICTIONARY:
		return data[section]

	return null


# =========================
# Internal
# =========================
func _validate(data) -> bool:
	# ConfigLoader only ensures valid JSON structure exists
	# No gameplay-specific validation allowed
	return data != null