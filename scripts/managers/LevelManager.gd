extends Node

signal level_loading(level)
signal level_loaded(level)
signal level_started(level)
signal level_completed(level)
signal level_failed(level)

var _current_level: int = 1
var _level_data: Dictionary = {}

const _LEVELS_CONFIG_PATH := Constants.ConfigPaths.LEVELS


func _ready() -> void:
	initialize()


func initialize() -> void:
	_current_level = 1
	_level_data = {}


func load_level(level_id: int) -> bool:
	level_loading.emit(level_id)
	SignalBus.level_loading.emit(level_id)

	var levels: Variant = ConfigLoader.load(_LEVELS_CONFIG_PATH)

	if levels == null:
		DebugLogger.error("LevelManager: Failed to load levels configuration.")
		return false

	var level_data: Dictionary = {}

	match typeof(levels):
		TYPE_ARRAY:
			for entry in levels:
				if entry is Dictionary and entry.get("level_id", -1) == level_id:
					level_data = entry
					break

		TYPE_DICTIONARY:
			if levels.has("levels"):
				for entry in levels["levels"]:
					if entry is Dictionary and entry.get("level_id", -1) == level_id:
						level_data = entry
						break
			elif levels.has(str(level_id)):
				level_data = levels[str(level_id)]
			elif levels.has(level_id):
				level_data = levels[level_id]

	if level_data.is_empty():
		DebugLogger.error("LevelManager: Level %d not found." % level_id)
		return false

	_current_level = level_id
	_level_data = level_data

	level_loaded.emit(_current_level)
	SignalBus.level_loaded.emit(_level_data)

	DebugLogger.info("Loaded level %d." % _current_level)

	return true


func reload_level() -> bool:
	return load_level(_current_level)


func start_level() -> void:
	if _level_data.is_empty():
		DebugLogger.warning("LevelManager: Cannot start. No level loaded.")
		return

	level_started.emit(_current_level)
	SignalBus.level_started.emit(_current_level)

	if has_node("../BoardManager"):
		var board_manager := get_node("../BoardManager")
		if board_manager.has_method("create_board"):
			board_manager.create_board(_level_data)

	DebugLogger.info("Started level %d." % _current_level)


func complete_level() -> void:
	level_completed.emit(_current_level)
	SignalBus.level_completed.emit(_current_level)

	DebugLogger.info("Completed level %d." % _current_level)


func fail_level() -> void:
	level_failed.emit(_current_level)
	SignalBus.level_failed.emit(_current_level)

	DebugLogger.info("Failed level %d." % _current_level)


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
	var game_config: Dictionary = ConfigLoader.load(Constants.ConfigPaths.GAME)

	if game_config.is_empty():
		return false

	var max_levels: int = int(game_config.get("max_levels", 0))

	if max_levels <= 0:
		return false

	return _current_level >= max_levels