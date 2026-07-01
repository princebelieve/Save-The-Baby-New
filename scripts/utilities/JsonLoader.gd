extends Node
class_name JsonLoader

# =========================================================
# PURPOSE
# Generic JSON serialization utility.
# No gameplay logic.
# No coordination responsibility.
# =========================================================

# Optional internal reuse of parsed data (safe cache)
var _cache: Dictionary = {}

# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	_cache.clear()

# =========================================================
# LOADING
# =========================================================

func load_file(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]

	if not file_exists(path):
		DebugLogger.error("JsonLoader: File not found -> " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		DebugLogger.error("JsonLoader: Cannot open file -> " + path)
		return {}

	var content := file.get_as_text()
	file.close()

	var result = JSON.parse_string(content)

	if typeof(result) != TYPE_DICTIONARY:
		DebugLogger.error("JsonLoader: Invalid JSON dictionary -> " + path)
		return {}

	_cache[path] = result
	return result


func load_array(path: String) -> Array:
	if _cache.has(path):
		return _cache[path]

	if not file_exists(path):
		DebugLogger.error("JsonLoader: File not found -> " + path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		DebugLogger.error("JsonLoader: Cannot open file -> " + path)
		return []

	var content := file.get_as_text()
	file.close()

	var result = JSON.parse_string(content)

	if typeof(result) != TYPE_ARRAY:
		DebugLogger.error("JsonLoader: Invalid JSON array -> " + path)
		return []

	_cache[path] = result
	return result

# =========================================================
# SAVING
# =========================================================

func save_file(path: String, data) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		DebugLogger.error("JsonLoader: Cannot write file -> " + path)
		return false

	var json_string := JSON.stringify(data)
	file.store_string(json_string)
	file.close()

	_cache[path] = data
	return true

# =========================================================
# VALIDATION
# =========================================================

func file_exists(path: String) -> bool:
	return FileHelper.file_exists(path)


func validate_json(path: String) -> bool:
	if not file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var result = JSON.parse_string(content)

	if result == null:
		return false

	# Valid JSON (either dictionary or array is acceptable)
	if typeof(result) == TYPE_DICTIONARY or typeof(result) == TYPE_ARRAY:
		return true

	return false