extends Node

signal level_loading(level)
signal level_loaded(level)
signal level_started(level)
signal level_completed(level)
signal level_failed(level)

var _current_level: int = 1
var _level_data: Dictionary = {}

func _ready() -> void:
	initialize()


func initialize() -> void:
	_current_level = 1
	_level_data.clear()


func load_level(level_id: int) -> bool:
	level_loading.emit(level_id)
	SignalBus.level_loading.emit(level_id)

	var path := _build_level_path(level_id)

	if not JsonLoader.file_exists(path):
		DebugLogger.error("LevelManager: Level file not found -> %s" % path)
		return false

	var data := JsonLoader.load_file(path)

	if not _validate_level(data):
		DebugLogger.error("LevelManager: Invalid level file -> %s" % path)
		return false

	_current_level = level_id
	_level_data = data

	level_loaded.emit(level_id)
	SignalBus.level_loaded.emit(_level_data)

	DebugLogger.info("Loaded level %03d." % level_id)

	return true


func reload_level() -> bool:
	return load_level(_current_level)


func start_level() -> void:
	if _level_data.is_empty():
		DebugLogger.warning("LevelManager: Cannot start. No level loaded.")
		return

	level_started.emit(_current_level)
	SignalBus.level_started.emit(_current_level)

	DebugLogger.info("Started level %03d." % _current_level)


func complete_level() -> void:
	level_completed.emit(_current_level)
	SignalBus.level_completed.emit(_current_level)

	DebugLogger.info("Completed level %03d." % _current_level)


func fail_level() -> void:
	level_failed.emit(_current_level)
	SignalBus.level_failed.emit(_current_level)

	DebugLogger.info("Failed level %03d." % _current_level)


func next_level() -> bool:
	if is_last_level():
		return false

	return load_level(_current_level + 1)


func previous_level() -> bool:
	if _current_level <= 1:
		return false

	return load_level(_current_level - 1)


func current_level() -> int:
	return _current_level


func get_level_data() -> Dictionary:
	return _level_data.duplicate(true)


func is_last_level() -> bool:
	var game_config := ConfigLoader.load(Constants.ConfigPaths.GAME)

	if game_config.is_empty():
		return false

	var max_levels := int(game_config.get("max_levels", 0))

	if max_levels <= 0:
		return false

	return _current_level >= max_levels


func _build_level_path(level_id: int) -> String:
	return "%s%s%03d%s" % [
		Constants.LevelPaths.DIRECTORY,
		Constants.LevelPaths.FILE_PREFIX,
		level_id,
		Constants.LevelPaths.FILE_EXTENSION
	]


func _validate_level(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	var required_keys := [
		"level_id",
		"name",
		"description",
		"difficulty",
		"board",
		"moves",
		"objectives",
		"tile_pool",
		"powerups",
		"obstacles",
		"rewards",
		"tutorial",
		"story",
		"audio",
		"background",
		"settings",
		"metadata"
	]

	for key in required_keys:
		if not data.has(key):
			DebugLogger.error("LevelManager: Missing key '%s'." % key)
			return false

	return true