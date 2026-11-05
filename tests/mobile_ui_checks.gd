extends Node

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 8:
		await get_tree().process_frame

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func inspect(root: Control, context: String) -> void:
	var bounds := root.get_global_rect().grow(2)
	for node in root.find_children("*", "Control", true, false):
		if not node.is_visible_in_tree(): continue
		if node is Button:
			check(bounds.encloses(node.get_global_rect()), "%s: button fits phone: %s" % [context, node.text])
			check(node.size.y >= 88 or str(node.name).begins_with("Piece"), "%s: touch target height" % context)
		if node is Label:
			check(node.get_theme_font_size("font_size") >= 32, "%s: legible text: %s" % [context, node.text])
			check(bounds.encloses(node.get_global_rect()), "%s: label fits phone: %s" % [context, node.text])

func _run() -> void:
	var progress := ConfigFile.new()
	var gallery := preload("res://scripts/rewards/PortraitGallery.gd").new()
	add_child(gallery)
	var portrait := str(DailyActivities.settings().portraits[0])
	progress.set_value("daily", "portraits", {portrait: 2})
	for height in [1100, 1280, 1600]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, height)
		add_child(viewport)
		var hub := RewardsHub.new()
		hub.configure(progress, gallery)
		viewport.add_child(hub)
		await settle()
		inspect(hub, "home %d" % height)
		hub._show_menu()
		await settle()
		inspect(hub, "field menu %d" % height)
		hub.go_back()
		await settle()
		check(hub._page == "home", "Back closes field menu before the underlying screen")
		for page in ["daily", "album", "portrait", "goals", "rules", "settings"]:
			hub._open(page)
			await settle()
			inspect(hub, "%s %d" % [page, height])
			hub.go_back()
			await settle()
		hub._open("daily")
		hub._change_day(1)
		check(hub._day == 1, "reward advances one day at a time")
		hub.go_back()
		check(hub._page == "home", "back restores rewards hub")
		hub.queue_free()
		await settle()
		var puzzle := PortraitPuzzle.new()
		puzzle.configure({"portrait": portrait, "slot": 123, "pieces": [8,1,2,3,4,5,6,7,0], "deadline": TimeHelper.current_unix_time() + 120})
		viewport.add_child(puzzle)
		await settle()
		inspect(puzzle, "puzzle %d" % height)
		check(puzzle._progress_label.text == "7 / 9", "HUD tracks pieces in place")
		puzzle._show_help()
		await settle()
		inspect(puzzle, "preview %d" % height)
		puzzle._overlay.queue_free()
		await settle()
		puzzle._select(0)
		puzzle._select(8)
		check(not puzzle._running, "solving puzzle ends the timer")
		puzzle.show_reward(15, 1)
		await settle()
		inspect(puzzle, "completed %d" % height)
		puzzle.queue_free()
		await settle()
		for columns in [4, 5]:
			var pieces := range(columns * columns)
			pieces[0] = columns * columns - 1
			pieces[columns * columns - 1] = 0
			var larger := PortraitPuzzle.new()
			larger.configure({"portrait": portrait, "slot": 123, "columns": columns, "rows": columns, "pieces": pieces, "deadline": TimeHelper.current_unix_time() + 240})
			viewport.add_child(larger)
			await settle()
			inspect(larger, "%dx%d puzzle %d" % [columns, columns, height])
			check(larger._buttons.size() == columns * columns, "all fragments visible")
			check(larger._progress_label.text == "%d / %d" % [columns * columns - 2, columns * columns], "larger HUD denominator")
			var atlas: AtlasTexture = larger._buttons[0].icon
			check(atlas.region.size.is_equal_approx(larger._image.get_size() / columns), "larger puzzle covers whole image")
			larger._select(0)
			larger._select(columns * columns - 1)
			check(not larger._running, "larger puzzle solves through taps")
			larger.queue_free()
			await settle()
		viewport.queue_free()
		await settle()
	var legacy_progress := ConfigFile.new()
	var now := TimeHelper.current_unix_time()
	legacy_progress.set_value("daily", "attempt", {"slot": DailyActivities.slot_at(now), "portrait": portrait, "pieces": range(9), "deadline": now + 120})
	check(not DailyActivities.finish_portrait(legacy_progress, DailyActivities.slot_at(now), now + 1).is_empty(), "nine-piece saves remain compatible")
	await _check_game_menus()
	print("MOBILE_UI_CHECKS: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_game_menus() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1100)
	add_child(viewport)
	var game = preload("res://scenes/game/Game.tscn").instantiate()
	viewport.add_child(game)
	await get_tree().create_timer(2).timeout
	game._skip_opening_story()
	game.get_node("Managers/LevelManager").load_level(435)
	game._begin_level("signal")
	game._finish_tutorial()
	game._show_pause_menu(true)
	await settle()
	inspect(game._pause_layer.get_child(0), "pause on short phone")
	game._show_settings_popup()
	await settle()
	var settings: AcceptDialog = game._pause_layer.find_child("AudioSettings", true, false)
	check(settings != null and settings.visible, "settings opens from pause")
	check(settings.size.y <= 1100, "settings fits short phone")
	check(settings.get_ok_button().size.y >= 92, "settings close target is large")
	for name in ["MusicVolume", "EffectsVolume", "MusicEnabled", "EffectsEnabled"]:
		check(settings.find_child(name, true, false).size.y >= 92, "audio target height: " + name)
	game._handle_back_request()
	check(not settings.visible and is_instance_valid(game._pause_layer), "Back dismisses settings before pause")
	game._show_case_file()
	await settle()
	check(is_instance_valid(game._case_file_layer), "case file opens from pause")
	for button in game._case_file_layer.find_children("*", "Button", true, false):
		check(button.size.y >= 92, "case file touch target: " + button.text)
	game._handle_back_request()
	check(game._case_file_layer == null, "Back closes case file")
	game._close_pause_menu()
	game._board._remaining_moves = 0
	await game._show_level_result(false)
	await settle()
	inspect(game._result_layer.get_child(0), "failure on short phone")
	game._result_layer.queue_free()
	game._result_layer = null
	game._show_daily_rewards()
	var hub = game._daily_rewards_layer.get_node("RewardsHub")
	hub.settings_requested.emit()
	await settle()
	settings = game._daily_rewards_layer.find_child("AudioSettings", true, false)
	check(settings != null and settings.visible, "settings opens from field menu")
	game._handle_back_request()
	check(is_instance_valid(game._daily_rewards_layer), "Back keeps activity screen beneath settings")
	hub.case_file_requested.emit()
	await settle()
	check(is_instance_valid(game._case_file_layer), "case file opens from activity menu")
	game._handle_back_request()
	check(game._case_file_layer == null and is_instance_valid(game._daily_rewards_layer), "Back closes case file before activity")
	game._highest_unlocked_level = 4
	game._completed_levels = {"1": 1, "2": 2, "3": 3}
	game._return_from_activity_to_map()
	await settle()
	check(game._portrait_layer == null and game._daily_rewards_layer == null and game._pause_layer == null, "Map navigation dismisses activity and pause overlays")
	var map_bounds: Rect2 = game._campaign_map.get_global_rect().grow(2)
	for button in game._campaign_map.find_children("*", "Button", true, false):
		check(button.size.y >= 92, "map navigation touch height: " + button.text)
		check(map_bounds.encloses(button.get_global_rect()), "map navigation stays on phone: " + button.text)
	var map = game._campaign_map
	check(map._level_positions.size() == 1050, "all 1050 cases are discoverable")
	for level in [1, 2, 3]:
		var stars: Control = map.find_child("Stars%03d" % level, true, false)
		check(stars != null and stars.earned == level, "earned star counts stay accurate")
		check(stars.size.is_equal_approx(Vector2(156, 60)), "stars have a phone-sized rating strip")
	map.scroll_to_level(55)
	await settle()
	check(map.find_child("Level055", true, false) != null, "scrolling goes beyond the former 50-case boundary")
	check(map.find_child("Level055", true, false).disabled, "future cases remain locked")
	map.scroll_to_level(1050)
	await settle()
	check(map.find_child("Level1050", true, false) != null, "final real case is reachable on the map")
	check(map._visible_chapters.size() <= 4, "offscreen chapters unload on mobile")
	check(map.find_child("Level001", true, false) == null, "distant nodes are not kept alive")
	check(map.find_child("MoreLevelsAhead", true, false) != null, "the trail has a continuation marker")
	check(map.find_child("Level1051", true, false) == null, "no nonexistent playable level is advertised")
	map.scroll_to_level(2)
	await settle()
	check(map.find_child("Stars002", true, false).earned == 2, "stars survive chapter unload and reload")
	viewport.queue_free()
	await settle()
