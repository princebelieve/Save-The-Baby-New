extends RefCounted
class_name SaveData

# =========================================================
# PURPOSE
#
# Represents one complete save.
# Contains persistent player data only.
# Contains no gameplay logic.
# Contains no file logic.
# Contains no serialization logic.
# Contains no validation logic.
# =========================================================


# =========================================================
# INTERNAL DATA
# =========================================================

var _data: Dictionary = {}
var _version: String = ""
var _timestamp: int = 0


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


func reset() -> void:
	_data.clear()
	_version = ""
	_timestamp = 0


func duplicate_data() -> SaveData:
	var copy := SaveData.new()

	copy.initialize()
	copy._data = _duplicate_value(_data)
	copy._version = _version
	copy._timestamp = _timestamp

	return copy


# =========================================================
# SAVE DATA
# =========================================================

func set_value(key: Variant, value: Variant) -> void:
	_data[key] = _duplicate_value(value)


func get_value(key: Variant) -> Variant:
	return _data.get(key)


func has_value(key: Variant) -> bool:
	return _data.has(key)


func remove_value(key: Variant) -> void:
	_data.erase(key)


func clear() -> void:
	_data.clear()


# =========================================================
# SECTIONS
# =========================================================

func set_section(name: String, data: Dictionary) -> void:
	_data[name] = _duplicate_value(data)


func get_section(name: String) -> Dictionary:
	if not has_section(name):
		return {}

	var section = _data[name]

	if section is Dictionary:
		return _duplicate_value(section)

	return {}


func has_section(name: String) -> bool:
	return _data.has(name) and _data[name] is Dictionary


func remove_section(name: String) -> void:
	_data.erase(name)


# =========================================================
# METADATA
# =========================================================

func set_save_version(version: String) -> void:
	_version = version


func get_save_version() -> String:
	return _version


func set_timestamp(timestamp: int) -> void:
	_timestamp = timestamp


func get_timestamp() -> int:
	return _timestamp


# =========================================================
# INTERNAL
# =========================================================

func _duplicate_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			return value.duplicate(true)

		TYPE_ARRAY:
			return value.duplicate(true)

		_:
			return value