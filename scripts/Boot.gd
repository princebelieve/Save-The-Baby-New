extends Node

# --------------------------------------------------
# Boot.gd
#
# Version 1.0
#
# Coordinates application startup.
#
# Responsibilities:
# - Initialize project utilities
# - Load project configuration
# - Instantiate Game scene
# - Initialize managers
# - Load save data
# - Start gameplay
# - Remove Boot scene
# --------------------------------------------------

var _game_scene: Node = null
var _managers: Node = null
var _is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _is_initialized:
		return

	_is_initialized = true

	initialize_utilities()
	load_configuration()
	create_game_scene()
	initialize_managers()
	load_save_data()
	start_game()
	finish_boot()


func initialize_utilities() -> void:
	DebugLogger.initialize()

	RandomGenerator.initialize()

	ConfigLoader.initialize()

	ResourceManager.initialize()

	JsonLoader.initialize()


func load_configuration() -> void:
	ConfigLoader.reload()


func create_game_scene() -> void:
	var packed_scene = ResourceManager.load_scene(Constants.ScenePaths.GAME)

	_game_scene = packed_scene.instantiate()

	get_tree().root.add_child(_game_scene)

	_managers = _game_scene.get_node("Managers")


func initialize_managers() -> void:
	for manager in _managers.get_children():
		if manager.has_method("initialize"):
			manager.initialize()


func load_save_data() -> void:
	var save_manager = _managers.get_node("SaveManager")

	save_manager.load_game()


func start_game() -> void:
	var game_manager = _managers.get_node("GameManager")

	game_manager.start_game()


func finish_boot() -> void:
	queue_free()