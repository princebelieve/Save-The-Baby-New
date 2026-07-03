extends Node

signal story_started(id)
signal dialogue_started(id)
signal dialogue_finished(id)
signal choice_selected(choice)
signal story_finished(id)

var _current_story: Dictionary = {}
var _current_scene: int = -1
var _current_dialogue: int = -1


func _ready() -> void:
	initialize()


func initialize() -> void:
	_current_story.clear()
    _current_scene = -1
	_current_dialogue = -1


func load_story(id: String) -> bool:
	var path := _build_story_path(id)

	if not JsonLoader.file_exists(path):
		DebugLogger.error("StoryManager: Story file not found -> %s" % path)
		return false

	var data := JsonLoader.load_file(path)

	if not _validate_story(data):
		DebugLogger.error("StoryManager: Invalid story file -> %s" % path)
		return false

	_current_story = data
    _current_scene = -1
	_current_dialogue = -1

	DebugLogger.info("StoryManager: Loaded story '%s'." % id)

	return true


func start_story(id: String) -> void:
	if not load_story(id):
		return

	story_started.emit(id)
	SignalBus.story_started.emit(id)

	if _current_story.has("scenes"):
		var scenes: Array = _current_story["scenes"]

		if not scenes.is_empty():
			var scene: Dictionary = scenes[0]

			if scene.has("dialogues"):
				var dialogues: Array = scene["dialogues"]

				if not dialogues.is_empty():
                    _current_scene = 0
					_current_dialogue = 0
					play_dialogue(dialogues[_current_dialogue])


func play_dialogue(dialogue: Dictionary) -> void:
	dialogue_started.emit(_current_dialogue)
	SignalBus.dialogue_started.emit(_current_dialogue)

	# DialoguePlayer is responsible for displaying dialogue.
	# StoryManager only coordinates progression.

	dialogue_finished.emit(_current_dialogue)
	SignalBus.dialogue_finished.emit(_current_dialogue)


func present_choices(choices: Array) -> void:
	SignalBus.story_choice_presented.emit(choices)


func select_choice(choice: Dictionary) -> void:
	choice_selected.emit(choice)
	SignalBus.choice_selected.emit(choice)


func next_dialogue() -> void:
	if _current_story.is_empty():
		return

	if not _current_story.has("scenes"):
		return

	var scenes: Array = _current_story["scenes"]

	if scenes.is_empty():
		end_story()
		return

	var scene: Dictionary = scenes[_current_scene]

	if not scene.has("dialogues"):
		end_story()
		return

	var dialogues: Array = scene["dialogues"]

	_current_dialogue += 1

	if _current_dialogue >= dialogues.size():
		if scene.has("choices"):
			var choices: Array = scene["choices"]

			if not choices.is_empty():
				present_choices(choices)
				return

		end_story()
		return

	play_dialogue(dialogues[_current_dialogue])


func skip_story() -> void:
	if _current_story.is_empty():
		return

	DebugLogger.info("StoryManager: Story skipped.")

	end_story()


func end_story() -> void:
	if _current_story.is_empty():
		return

	var story_id := ""

	if _current_story.has("story_id"):
		story_id = str(_current_story["story_id"])

	story_finished.emit(story_id)
	SignalBus.story_finished.emit(story_id)

	DebugLogger.info("StoryManager: Story finished -> %s" % story_id)

	initialize()


func story_progress() -> Dictionary:
	if _current_story.is_empty():
		return {}

	var total_dialogues := 0

	if _current_story.has("scenes"):
		for scene in _current_story["scenes"]:
			if scene.has("dialogues"):
				total_dialogues += scene["dialogues"].size()

	return {
		"story_id": _current_story.get("story_id", ""),
		"current_dialogue": _current_dialogue,
		"total_dialogues": total_dialogues
	}


func _build_story_path(story_id: String) -> String:
	return "%s%s%s" % [
		Constants.StoryPaths.DIRECTORY,
		story_id,
		Constants.StoryPaths.FILE_EXTENSION
	]


func _validate_story(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	var required_keys := [
		"story_id",
		"title",
		"background_music",
		"default_background",
		"characters",
		"scenes",
		"metadata"
	]

	for key in required_keys:
		if not data.has(key):
			DebugLogger.error("StoryManager: Missing key '%s'." % key)
			return false

	return true