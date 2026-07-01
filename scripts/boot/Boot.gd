extends Node

var _game_scene: Node = null
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


func finish_boot() -> void:
	queue_free()