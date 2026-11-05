extends Node

const Serial = preload("res://scripts/story/StoryCampaign.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var manager := StoryManager.new()
	add_child(manager)
	var story_ids: Array[String] = ["opening_story"]
	for i in range(1,7):
		story_ids.append("chapter%02d" % i)
	for i in range(1,11):
		story_ids.append("season%02d" % i)
	for i in range(1,101):
		for phase in ["intro","outro"]:
			story_ids.append("serial%03d_%s" % [i,phase])
	for id in story_ids:
		for route in ["police","signal","alone"]:
			manager.set_approach(route)
			check(manager.load_story(id),id+" loads on "+route)
			var data := manager.get_story_data()
			check(ResourceLoader.exists(str(data.default_background)),id+" background exists")
			var count := 0
			for scene in data.scenes:
				check(not scene.dialogues.is_empty(),id+" has visible dialogue")
				for dialogue in scene.dialogues:
					count += 1
					var text := (str(dialogue.speaker)+" "+str(dialogue.text)).to_lower()
					check(route == "police" or not text.contains("morris"),id+" restricts Morris to police")
					check(ResourceLoader.exists(str(dialogue.portrait)),id+" portrait exists")
			manager.load_story(id)
			var repeated := 0
			for scene in manager.get_story_data().scenes:
				repeated += scene.dialogues.size()
			check(count == repeated,id+" does not duplicate branch dialogue on reload")
	manager.queue_free()
	for id in range(51,1051):
		var level := JsonLoader.load_file("res://levels/level%03d.json" % id)
		var episode := Serial.episode_for(id)
		check(not episode.is_empty(),"episode exists %d" % id)
		var rebuilt := Serial.apply_to_level(level.duplicate(true))
		check(level.story == rebuilt.story,"offline/runtime narrative hooks agree %d" % id)
		check(level.name == rebuilt.name and level.description == rebuilt.description,"level narrative agrees %d" % id)
		check(str(level.story.win_outcome).contains("Ethan is still missing"),"no rescue on win %d" % id)
	var progress := ConfigFile.new()
	progress.set_value("story_choices","history",{"serial001_outro":{"id":"signal","response":"obsolete saved dialogue"}})
	Serial.compact_history(progress)
	check(progress.get_value("story_choices","history").serial001_outro == {"id":"signal"},"legacy decisions compact")
	check(Serial.resolve_choice("serial001_outro","signal").speaker == "David","compact decision resolves original response")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(Game.CAMPAIGN_PROGRESS_PATH+suffix):
			DirAccess.remove_absolute(Game.CAMPAIGN_PROGRESS_PATH+suffix)
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._skip_opening_story()
	game.get_node("Managers/LevelManager").load_level(435)
	game._begin_level("signal")
	game._finish_tutorial()
	for expected in ["My money or Ethan.","I told you, David. You won't return alive."]:
		await game._show_level_result(false)
		await get_tree().create_timer(0.3).timeout
		var failure: Node = game._result_layer.find_child("FailureScreen",true,false)
		check(failure != null,"every loss instantiates the designated failure scene")
		if failure != null:
			check(failure.get_node("VictorTaunt").text == expected,"loss rotates Victor's taunts")
			check(failure.get_node("VictorPortrait").texture != null,"loss shows Victor")
			var original_size := get_tree().root.size
			var original_scale := get_tree().root.content_scale_size
			for dimensions in [Vector2i(720,960),Vector2i(720,1280),Vector2i(720,1600)]:
				get_tree().root.size = dimensions
				get_tree().root.content_scale_size = dimensions
				await get_tree().create_timer(0.45).timeout
				var bounds := get_viewport().get_visible_rect()
				check(bounds.encloses(failure.get_global_rect()),"Victor failure portrait and dialogue fit %s" % dimensions)
				for button in game._result_layer.find_children("*","BaseButton",true,false):
					if button.is_visible_in_tree():
						check(bounds.encloses(button.get_global_rect()),"failure action fits %s: %s" % [dimensions,button.text])
			get_tree().root.size = original_size
			get_tree().root.content_scale_size = original_scale
		check(game._current_level_id == 435,"loss does not advance the level")
		check(not game._completed_levels.has("435"),"loss does not mark a level won")
		game._dismiss_level_result()
		await get_tree().process_frame
	var saved := ConfigFile.new()
	CampaignProgressStore.read(saved,Game.CAMPAIGN_PROGRESS_PATH)
	check(int(saved.get_value("campaign","failed_attempts",0)) == 2,"failure rotation survives a save")
	game._on_story_finished("serial010_outro")
	check(game._campaign_progress.get_value("story_seen","serial010_outro",false),"finished story marked seen")
	check(str(game._campaign_progress.get_value("story_progress","latest",{}).summary).contains("accounts"),"latest evidence appears in case file data")
	check(not CaseJournal.entries(game._campaign_progress).is_empty(),"season finale creates a journal entry")
	var completed: Dictionary = {}
	var stars: Dictionary = {}
	for id in range(1,1051):
		completed[str(id)] = true
		stars[str(id)] = 3
	game._campaign_progress.set_value("campaign","completed_levels",completed)
	game._campaign_progress.set_value("campaign","level_stars",stars)
	var history: Dictionary = {}
	for id in story_ids:
		game._campaign_progress.set_value("story_seen",id,true)
		if id.ends_with("outro") or not id.begins_with("serial"):
			history[id] = {"id":"signal"}
	game._campaign_progress.set_value("story_choices","history",history)
	for season in range(1,11):
		game._on_story_finished("serial%03d_outro" % (season*10))
	var snapshot: Dictionary = {}
	for section in game._campaign_progress.get_sections():
		var values: Dictionary = {}
		for key in game._campaign_progress.get_section_keys(section):
			values[key] = game._campaign_progress.get_value(section,key)
		snapshot[section] = values
	var encoded := JSON.stringify(snapshot)
	check(encoded.to_utf8_buffer().size() < 96000,"full story campaign stays within cloud save limit")
	var fixture := FileAccess.open("res://.test-data/story-complete-save.json",FileAccess.WRITE)
	fixture.store_string(encoded)
	fixture.close()
	print("Completed campaign story save: %d bytes" % encoded.to_utf8_buffer().size())
	game.queue_free()
	await get_tree().create_timer(2.3).timeout
	print("Story checks: %d checks; %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
