extends Node

##
## SaveManager.gd
##
## Purpose:
## Owns all player save data.
## Coordinates the Save System.
##

signal save_requested
signal save_completed
signal save_failed

signal load_requested
signal load_completed
signal load_failed


# ------------------------------------------------------------------
# Internal State
# ------------------------------------------------------------------

var _save_data
var _save_path : String = "user://savegame.save"

var _serializer
var _save_file
var _validator
var _migrator
var _autosave_scheduler

var _is_initialized : bool = false


# ------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------

func initialize() -> void:
	if _is_initialized:
		return

	_serializer = SaveSerializer.new()
	_save_file = SaveFile.new()
	_validator = SaveValidator.new()
	_migrator = SaveMigrator.new()
	_autosave_scheduler = AutosaveScheduler.new()

	_serializer.initialize()
	_save_file.initialize()
	_validator.initialize()
	_migrator.initialize()
	_autosave_scheduler.initialize()

	_save_data = SaveData.new()
	_save_data.initialize()
	_save_data.set_save_version(str(Constants.SAVE_VERSION))
	_save_data.set_timestamp(TimeHelper.current_unix_time())

	_is_initialized = true


func _ready() -> void:
	initialize()


func _process(delta: float) -> void:
	if !_is_initialized:
		return

	_autosave_scheduler.update(delta)

	if _autosave_scheduler.is_time_to_autosave():
		auto_save()


# ------------------------------------------------------------------
# New Game
# ------------------------------------------------------------------

func new_game() -> void:
	_save_data.reset()
	_save_data.set_save_version(str(Constants.SAVE_VERSION))
	_save_data.set_timestamp(TimeHelper.current_unix_time())


# ------------------------------------------------------------------
# Saving
# ------------------------------------------------------------------

func save_game() -> bool:
	_save_data.set_timestamp(TimeHelper.current_unix_time())

	emit_signal("save_requested")

	var serialized_data = _serializer.serialize(_save_data)

	var success = _save_file.write(
		_save_path,
		serialized_data
	)

	if success:
		emit_signal("save_completed")
	else:
		emit_signal("save_failed")

	return success


func auto_save() -> bool:

	var success = save_game()

	if success:
		_autosave_scheduler.reset_timer()

	return success


# ------------------------------------------------------------------
# Loading
# ------------------------------------------------------------------

func load_game() -> bool:

	emit_signal("load_requested")

	if !_save_file.exists(_save_path):
		emit_signal("load_failed")
		return false

	var raw_data = _save_file.read(_save_path)

	var loaded_save = _serializer.deserialize(raw_data)

	if !_validator.validate(loaded_save):
		emit_signal("load_failed")
		return false

	if _migrator.can_migrate(
		loaded_save.get_save_version()
	):
		loaded_save = _migrator.migrate(loaded_save)

	_save_data = loaded_save

	emit_signal("load_completed")

	return true


# ------------------------------------------------------------------
# Save File Management
# ------------------------------------------------------------------

func delete_save() -> bool:
	return _save_file.delete(_save_path)


func save_exists() -> bool:
	return _save_file.exists(_save_path)


func export_save(path: String) -> bool:
	return _save_file.copy(
		_save_path,
		path
	)


func import_save(path: String) -> bool:

	if !_save_file.exists(path):
		return false

	return _save_file.copy(
		path,
		_save_path
	)


# ------------------------------------------------------------------
# Accessors
# ------------------------------------------------------------------

func get_save_data():
	return _save_data


func set_save_data(data) -> void:
	_save_data = data
