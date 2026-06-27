extends Node
class_name JsonLoader

# --------------------------------------------------
# JsonLoader.gd (Version 1.0 Freeze)
#
# Purpose:
# Generic JSON serialization utility.
#
# Rules:
# - No gameplay logic
# - No file system logic (delegates to FileHelper)
# - No state mutation
# - Pure JSON encode/decode layer
# --------------------------------------------------


# =========================
# Initialization
# =========================
func initialize() -> void:
	pass


# =========================
# Loading
# =========================
func load_file(path: String) -> Dictionary:
	if not FileHelper.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if typeof(data) == TYPE_DICTIONARY:
		return data

	return {}


func load_array(path: String) -> Array:
	if not FileHelper.file_exists(path):
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if typeof(data) == TYPE_ARRAY:
		return data

	return []


# =========================
# Saving
# =========================
func save_file(path: String, data) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(data))
	file.close()

	return true


# =========================
# Validation
# =========================
func file_exists(path: String) -> bool:
	return FileHelper.file_exists(path)


func validate_json(path: String) -> bool:
	if not FileHelper.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)

	# real validation = must successfully parse AND not be null
	if parsed == null:
		return false

	return true