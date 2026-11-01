extends "res://tests/booster_tutorial_playthrough.gd"


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	output = "res://.test-data/academy"
	if "--fast" in OS.get_cmdline_user_args(): Engine.time_scale = 3.0
	if "--short" in OS.get_cmdline_user_args():
		get_window().content_scale_size = Vector2i(720, 960)
		get_window().size = Vector2i(600, 800)
		output += "-short"
	DirAccess.make_dir_recursive_absolute(output)
	RandomGenerator.initialize(20261102)
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await wait(2.2)
	game._launch_layer.queue_free()
	game._launch_layer = null
	# Legacy demo rows and future lesson flags cannot populate the real journal.
	game._campaign_progress.set_value("case_journal", "entries", {})
	for lesson in game._academy_lessons():
		game._campaign_progress.set_value("academy", str(lesson["id"]), true)
	check(CaseJournal.entries(game._campaign_progress).is_empty(), "An unread journal must have no seeded references or inferred lessons")
	game._campaign_progress.set_value("academy_completed", "rocket", false)
	game.get_node("Managers/LevelManager").load_level(4)
	game._begin_level("alone")
	await wait(0.3)
	var seen := CaseJournal.entries(game._campaign_progress)
	check(seen.size() == 1 and seen[0]["id"] == "rocket_pieces", "Only the instruction actually presented may be recorded")
	check(seen[0]["facts"].size() == 1 and seen[0]["facts"].has("make"), "Unseen pages of the same skill must stay absent")
	await click_button(game._tutorial_overlay._skip_button)
	check(CaseJournal.entries(game._campaign_progress).size() == 1, "Skipping must not add the remaining lesson skills")
	game._discover_journal_fact("rocket", 0)
	check(CaseJournal.entries(game._campaign_progress)[0]["facts"].size() == 1, "Repeating an instruction must not duplicate it")
	var journal_path := "user://case_journal_roundtrip.cfg"
	check(CampaignProgressStore.write(game._campaign_progress, journal_path) == OK, "Journal must save")
	var reopened := ConfigFile.new()
	check(CampaignProgressStore.read(reopened, journal_path) == OK and CaseJournal.entries(reopened) == CaseJournal.entries(game._campaign_progress), "Discovered journal must survive restart")
	# Returning player: practice was completed in an older save, academy lesson was not.
	game._campaign_progress.set_value("tutorials", "8", true)
	game._campaign_progress.set_value("academy_completed", "thunder", false)
	game.get_node("Managers/LevelManager").load_level(8)
	game._begin_level("alone")
	await wait(0.3)
	await complete_pages(game._tutorial_overlay)
	check(not game._tutorial_overlay.visible and not game._tutorial_active and not game._board.is_locked(), "Level 8 final Continue must close for a returning player with completed practice")
	game._campaign_progress.set_value("tutorials", "8", false)
	for lesson in game._academy_lessons():
		game._campaign_progress.set_value("academy", str(lesson["id"]), false)
		game._campaign_progress.set_value("academy_completed", str(lesson["id"]), false)
	for level_id in [1, 4, 6, 8, 9, 12, 16, 20, 24, 28, 33, 41]:
		game.get_node("Managers/LevelManager").load_level(level_id)
		game._begin_level("alone")
		await wait(0.3)
		check(game._tutorial_action == "academy_lesson", "New mechanic must start with David's lesson: %d" % level_id)
		check(game._board.is_locked(), "Lesson must prevent accidental board input")
		var overlay := game._tutorial_overlay
		await capture("%03d_lesson" % level_id)
		check(overlay._bubble.get_global_rect().encloses(overlay._skip_button.get_global_rect()), "Skip must fit the banner")
		if overlay._pages.size() > 1:
			var first_copy := overlay._body_label.text
			await click_button(overlay._acknowledge_button)
			await click_button(overlay._previous_button)
			check(overlay._page == 0 and overlay._body_label.text == first_copy, "Previous must return to the same page")
		await complete_pages(overlay)
		check(bool(game._campaign_progress.get_value("academy_completed", str(game._academy_lessons().filter(func(l): return int(l["level"]) == level_id)[0]["id"]), false)), "Finished lesson must persist separately from its archive entry")
		if level_id == 1:
			check(not game._board.is_locked() and game._tutorial_action == "guided_swap", "Lesson must hand over to playable guided practice")
			var deferred_skip := [false]
			overlay._skip_button.pressed.connect(func(): deferred_skip[0] = game._tutorial_skip_pending and game._board.is_locked(), CONNECT_ONE_SHOT)
			var move := game._board._required_swap.duplicate()
			check(game._board.swap_tiles(move[0], move[1]), "Guided move must start")
			await click_button(overlay._skip_button)
			check(deferred_skip[0], "Skipping during a move must wait for its animation")
			var deadline := Time.get_ticks_msec() + 10000
			while game._tutorial_skip_pending and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
		if game._tutorial_active:
			await click_button(overlay._skip_button)
		check(not game._tutorial_active and not game._board.is_locked(), "Skip or Continue must restore play")
		check(game._board._required_swap.is_empty() and game._board._booster_mode.is_empty(), "Skip must clear tutorial restrictions")
		game._show_case_file()
		await wait(0.3)
		var discovered := CaseJournal.entries(game._campaign_progress)
		var entry: Dictionary = discovered.back()
		var lesson_button := find_button(game._case_file_layer, str(entry["title"]))
		check(lesson_button != null, "Discovered skill must have its own correctly titled card")
		if lesson_button != null:
			await open_card(lesson_button)
			var popup := game._detail_layer.get_child(0) as IllustratedPopup
			check(popup._heading.text == str(entry["title"]), "Popup title must match the selected case label")
			check(popup._art_path == str(entry["illustration"]), "Popup art must belong to the selected skill")
			await capture("%03d_case_detail" % level_id)
			await click_button(popup._skip_button)
		game._close_case_file()
		await wait(0.1)
	for level_id in [4, 6, 8]:
		await exercise_tutorial(level_id)
	# Decisions are independent at every chapter, with cancellation and confirmation.
	for chapter in range(1, 7):
		game._pending_level_id = [1, 9, 16, 23, 31, 41][chapter - 1]
		game._pending_route_id = game._current_route_id
		game._pending_story_id = "chapter%02d" % chapter
		game._start_campaign_story(game._pending_story_id)
		var data := game._story_manager.get_story_data()
		var expected: String = data["scenes"][0]["route_dialogues"][game._current_route_id][0]["text"]
		check(str(game._story_manager.get_current_dialogue().get("text", "")) == expected, "Previous approach must select distinct chapter dialogue")
		var choices: Array = data["scenes"][0]["choices"]
		game._finish_dialogue_typing()
		game._present_route_choices(choices)
		await wait(0.4)
		await click_button(game._choice_box.get_child(chapter % 3))
		check(game._detail_layer != null, "Choice must preview consequences")
		await capture("chapter%d_confirm" % chapter)
		await click_button((game._detail_layer.get_child(0) as IllustratedPopup)._skip_button)
		check(game._choice_box.get_child_count() == 3, "Back must leave all approaches available")
		await click_button(game._choice_box.get_child(chapter % 3))
		await complete_pages(game._detail_layer.get_child(0) as IllustratedPopup)
		var history: Dictionary = game._campaign_progress.get_value("story_choices", "history", {})
		check(history.has("chapter%02d" % chapter), "Each chapter decision must persist")
		check(game._current_route_id == str(choices[chapter % 3]["id"]), "New decision must replace the earlier approach")
		await click_button(game._story_continue_button)
		check(game._briefing_layer != null, "Chapter decision must continue to mission briefing")
		game._briefing_layer.queue_free()
		game._briefing_layer = null
	print("ACADEMY_PLAYTHROUGH: ", failures.size(), " failures")
	var report := FileAccess.open(output + "/result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures, "viewport": str(get_viewport().get_visible_rect().size)}, "  "))
	game.queue_free()
	await wait(2.5)
	get_tree().quit(0 if failures.is_empty() else 1)


func find_button(node: Node, caption: String) -> BaseButton:
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var found := find_button(child, caption)
		if found != null: return found
	return null


func open_card(button: BaseButton) -> void:
	var ancestor := button.get_parent()
	while ancestor != null and not ancestor is ScrollContainer:
		ancestor = ancestor.get_parent()
	if ancestor is ScrollContainer:
		ancestor.ensure_control_visible(button)
	await wait(0.2)
	await click_button(button)

