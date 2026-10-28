extends Node
class_name StoryManager

# =========================================================
# SIGNALS
# =========================================================
signal story_started(id)
signal dialogue_started(id)
signal dialogue_finished(id)
signal choice_selected(choice)
signal story_finished(id)

# =========================================================
# INTERNAL STATE
# =========================================================
var _current_story: Dictionary = {}
var _current_scene: int = -1
var _current_dialogue: int = -1

var _dialogue_player: DialoguePlayer
var _choice_manager: ChoiceManager
var _portrait_manager: PortraitManager


# =========================================================
# INITIALIZATION
# =========================================================
func initialize() -> void:
	_current_story = {}
	_current_scene = -1
	_current_dialogue = -1


func _ready() -> void:
	initialize()


# =========================================================
# STORY LOADING
# =========================================================
func load_story(id: String) -> bool:
	var path := _build_story_path(id)

	if not JsonLoader.file_exists(path):
		DebugLogger.error("StoryManager: Story not found -> %s" % path)
		return false

	var data := JsonLoader.load_file(path)

	if not _validate_story(data):
		DebugLogger.error("StoryManager: Invalid story -> %s" % path)
		return false

	_current_story = data
	_current_scene = -1
	_current_dialogue = -1

	DebugLogger.info("StoryManager: Loaded story -> %s" % id)
	return true


# =========================================================
# STORY CONTROL
# =========================================================
func start_story(id: String) -> void:
	if not load_story(id):
		return

	story_started.emit(id)
	SignalBus.story_started.emit(id)

	goto_scene(0)


func end_story() -> void:
	var story_id: String = str(_current_story.get("story_id", ""))

	story_finished.emit(story_id)
	SignalBus.story_finished.emit(story_id)

	DebugLogger.info("StoryManager: Finished -> %s" % story_id)

	reset()


func skip_story() -> void:
	DebugLogger.info("StoryManager: Skipped story.")
	end_story()


# =========================================================
# SCENE NAVIGATION
# =========================================================
func load_scene(scene_id: int) -> void:
	goto_scene(scene_id)


func reload_scene() -> void:
	goto_scene(_current_scene)


func goto_scene(scene_id: int) -> void:
	if _current_story.is_empty():
		return

	var scenes: Array = _current_story.get("scenes", [])
	if scene_id < 0 or scene_id >= scenes.size():
		end_story()
		return

	_current_scene = scene_id
	_current_dialogue = -1

	var scene: Dictionary = scenes[_current_scene]

	if scene.has("dialogues"):
		var dialogues: Array = scene["dialogues"]
		if not dialogues.is_empty():
			next_dialogue()


func goto_next_scene() -> void:
	goto_scene(_current_scene + 1)


func goto_previous_scene() -> void:
	goto_scene(_current_scene - 1)


# =========================================================
# DIALOGUE CONTROL (DELEGATED)
# =========================================================
func next_dialogue() -> void:
	if _current_story.is_empty():
		return

	var scene := _get_current_scene()
	if scene.is_empty():
		end_story()
		return

	var dialogues: Array = scene.get("dialogues", [])

	_current_dialogue += 1

	if _current_dialogue >= dialogues.size():
		if scene.has("choices") and not scene["choices"].is_empty():
			present_choices(scene["choices"])
			return

		goto_next_scene()
		return

	play_dialogue(dialogues[_current_dialogue])


func previous_dialogue() -> void:
	if _current_story.is_empty() or _current_dialogue <= 0:
		return
	_current_dialogue -= 2
	next_dialogue()


func play_dialogue(dialogue: Dictionary) -> void:
	var index := _current_dialogue

	dialogue_started.emit(index)
	SignalBus.dialogue_started.emit(index)

	# Delegation point:
	if _dialogue_player:
		_dialogue_player.load_dialogue([dialogue])
		_dialogue_player.start()

	dialogue_finished.emit(index)
	SignalBus.dialogue_finished.emit(index)


# =========================================================
# CHOICES
# =========================================================
func present_choices(choices: Array) -> void:
	if _choice_manager:
		_choice_manager.show_choices(choices)

	SignalBus.story_choice_presented.emit(choices)


func select_choice(choice: Dictionary) -> void:
	choice_selected.emit(choice)
	SignalBus.choice_selected.emit(choice)


# =========================================================
# PROGRESS
# =========================================================
func record_choice(choice_id: String) -> void:
	pass # optional save hook


func get_story_progress() -> Dictionary:
	if _current_story.is_empty():
		return {}

	var scenes: Array = _current_story.get("scenes", [])
	var total_dialogues := 0

	for s in scenes:
		if s.has("dialogues"):
			total_dialogues += s["dialogues"].size()

	return {
		"story_id": _current_story.get("story_id", ""),
		"scene": _current_scene,
		"dialogue": _current_dialogue,
		"total_dialogues": total_dialogues
	}


func get_story_data() -> Dictionary:
	return _current_story.duplicate(true)


func get_current_dialogue() -> Dictionary:
	var scene := _get_current_scene()
	var dialogues: Array = scene.get("dialogues", [])
	if _current_dialogue < 0 or _current_dialogue >= dialogues.size():
		return {}
	return dialogues[_current_dialogue].duplicate(true)


func set_story_progress(progress: Dictionary) -> void:
	_current_scene = progress.get("scene", -1)
	_current_dialogue = progress.get("dialogue", -1)


func is_story_finished() -> bool:
	return _current_story.is_empty()


# =========================================================
# GAME FLOW HOOKS
# =========================================================
func notify_gameplay_start() -> void:
	pass


func notify_story_finished() -> void:
	pass


# =========================================================
# INTERNAL HELPERS
# =========================================================
func _get_current_scene() -> Dictionary:
	if _current_story.is_empty():
		return {}

	var scenes: Array = _current_story.get("scenes", [])
	if _current_scene < 0 or _current_scene >= scenes.size():
		return {}

	return scenes[_current_scene]


func reset() -> void:
	_current_story = {}
	_current_scene = -1
	_current_dialogue = -1


func shutdown() -> void:
	reset()


func _build_story_path(story_id: String) -> String:
	return "%s%s%s" % [
		Constants.StoryPaths.DIRECTORY,
		story_id,
		Constants.StoryPaths.FILE_EXTENSION
	]


func _validate_story(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	var required := [
		"story_id",
		"title",
		"background_music",
		"default_background",
		"characters",
		"scenes",
		"metadata"
	]

	for k in required:
		if not data.has(k):
			return false

	return true
