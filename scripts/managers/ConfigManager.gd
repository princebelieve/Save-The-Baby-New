extends Node

class_name ConfigManager


var _configs: Dictionary = {}


func _ready() -> void:
	load_all()


# ==========================================================
# LOADING
# ==========================================================

func load_all() -> void:
	_configs.clear()

	_load_config("game", Constants.GAME_CONFIG)
	_load_config("audio", Constants.AUDIO_CONFIG)
	_load_config("economy", Constants.ECONOMY_CONFIG)
	_load_config("settings", Constants.SETTINGS_CONFIG)
	_load_config("tiles", Constants.TILES_CONFIG)
	_load_config("powerups", Constants.POWERUPS_CONFIG)
	_load_config("obstacles", Constants.OBSTACLES_CONFIG)
	_load_config("rewards", Constants.REWARDS_CONFIG)
	_load_config("ui", Constants.UI_CONFIG)
	_load_config("animations", Constants.ANIMATIONS_CONFIG)


func reload_all() -> void:
	load_all()


func reload(name: String) -> void:
	match name:
		"game":
			_load_config(name, Constants.GAME_CONFIG)

		"audio":
			_load_config(name, Constants.AUDIO_CONFIG)

		"economy":
			_load_config(name, Constants.ECONOMY_CONFIG)

		"settings":
			_load_config(name, Constants.SETTINGS_CONFIG)

		"tiles":
			_load_config(name, Constants.TILES_CONFIG)

		"powerups":
			_load_config(name, Constants.POWERUPS_CONFIG)

		"obstacles":
			_load_config(name, Constants.OBSTACLES_CONFIG)

		"rewards":
			_load_config(name, Constants.REWARDS_CONFIG)

		"ui":
			_load_config(name, Constants.UI_CONFIG)

		"animations":
			_load_config(name, Constants.ANIMATIONS_CONFIG)

		_:
			push_warning("ConfigManager: Unknown config '%s'." % name)


func _load_config(name: String, path: String) -> void:
	var data := JsonLoader.load_file(path)

	if data.is_empty():
		push_warning("ConfigManager: Failed to load %s." % path)
		return

	_configs[name] = data


# ==========================================================
# ACCESS
# ==========================================================

func has_config(name: String) -> bool:
	return _configs.has(name)


func get_config(name: String) -> Dictionary:
	if _configs.has(name):
		return _configs[name]

	push_warning("ConfigManager: Missing config '%s'." % name)
	return {}


func get_value(
	config_name: String,
	key: String,
	default_value: Variant = null
) -> Variant:
	if not _configs.has(config_name):
		return default_value

	var config: Dictionary = _configs[config_name]

	if config.has(key):
		return config[key]

	return default_value


func has_key(config_name: String, key: String) -> bool:
	if not _configs.has(config_name):
		return false

	return _configs[config_name].has(key)


func get_section(
	config_name: String,
	section: String
) -> Dictionary:
	if not _configs.has(config_name):
		return {}

	var config: Dictionary = _configs[config_name]

	if not config.has(section):
		return {}

	var value = config[section]

	if value is Dictionary:
		return value

	return {}


func get_array(
	config_name: String,
	key: String
) -> Array:
	if not _configs.has(config_name):
		return []

	var config: Dictionary = _configs[config_name]

	if not config.has(key):
		return []

	var value = config[key]

	if value is Array:
		return value

	return []


func get_nested_value(
	config_name: String,
	section: String,
	key: String,
	default_value: Variant = null
) -> Variant:
	var data := get_section(config_name, section)

	if data.has(key):
		return data[key]

	return default_value


# ==========================================================
# DEBUG
# ==========================================================

func print_loaded_configs() -> void:
	print("--------------------------------")
	print("Loaded Configurations")
	print("--------------------------------")

	for name in _configs.keys():
		print("%s : Loaded" % name)

	print("--------------------------------")