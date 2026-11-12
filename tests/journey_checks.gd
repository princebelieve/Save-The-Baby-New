extends Node
var failures := 0
var checks := 0
var game: Game

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 12: await get_tree().process_frame

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	get_window().content_scale_size = Vector2i(720,1280)
	get_window().size = Vector2i(360,640)
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._start_opening_story()
	game._skip_opening_story()
	game._finish_tutorial()
	if game._campaign_progress.has_section("chapter_introductions"):
		game._campaign_progress.erase_section("chapter_introductions")
	var first := JsonLoader.load_file("res://levels/level001.json")
	check(game._show_new_chapter(first, "alone"), "first chapter gets an illustrated introduction")
	await settle()
	var intro: Control = game._chapter_layer.get_child(0)
	check(int(intro.details.chapter_id) == 1, "introduction reflects the actual chapter")
	await click(intro.find_child("EnterChapter", true, false))
	await settle()
	check(game._campaign_progress.get_value("chapter_introductions", "1", false), "continuing remembers the introduction")
	check(not game._show_new_chapter(first, "alone"), "replaying a chapter does not repeat its introduction")
	var season := JsonLoader.load_file("res://levels/level051.json")
	check(game._show_new_chapter(season, "alone"), "new season introduces its new location")
	check(str(game._chapter_layer.get_child(0).details.season_title) == "The River Between Us", "season title is taken from authored story metadata")
	game._handle_back_request()
	check(game._chapter_layer == null and not game._campaign_progress.get_value("chapter_introductions", "7", false), "Back leaves introduction without entering or marking the chapter")
	game._highest_unlocked_level = 1
	game._on_campaign_level_selected(51, "alone")
	check(game._chapter_layer == null, "locked chapters cannot be entered through the introduction")
	if game._campaign_progress.has_section("daily"): game._campaign_progress.erase_section("daily")
	var now := TimeHelper.current_unix_time()
	game._record_daily_mission("specials", 1)
	check(game._campaign_progress.get_value("daily", "supply_rewards", {}).is_empty(), "partial task does not issue a supply")
	game._record_daily_mission("specials", 1)
	var key := "%d:specials" % DailyActivities.day_at(now)
	check(game._campaign_progress.get_value("daily", "supply_rewards", {}).has(key), "ordinary special creation earns a Rocket reward")
	var stock := game._economy_manager.get_booster_count("rocket")
	game._claim_daily_supply(key)
	game._claim_daily_supply(key)
	check(game._economy_manager.get_booster_count("rocket") == stock + 1, "task reward grants inventory exactly once")
	game._record_daily_mission("specials", 5)
	check(not game._campaign_progress.get_value("daily", "supply_rewards", {}).has(key), "repeated special creation cannot reissue today's reward")
	game._record_daily_mission("blockers", 3)
	key = "%d:blockers" % DailyActivities.day_at(now)
	game._economy_manager.set_lives(5)
	game._claim_daily_supply(key)
	check(game._campaign_progress.get_value("daily", "supply_rewards", {}).has(key), "full lives preserve an earned life")
	game._close_detail()
	game._economy_manager.set_lives(4)
	game._claim_daily_supply(key)
	check(game._economy_manager.get_lives() == 5 and not game._campaign_progress.get_value("daily", "supply_rewards", {}).has(key), "life reward can be claimed when a life is needed")
	var saved := ConfigFile.new()
	CampaignProgressStore.read(saved, Game.CAMPAIGN_PROGRESS_PATH)
	check(int(saved.get_value("campaign", "lives", -1)) == 5, "life claim persists with the consumed marker")
	await fresh_player_moves()
	await phone_screens()
	game.queue_free()
	await settle()
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(1).timeout
	check(game._campaign_progress.get_value("chapter_introductions", "1", false), "new game instance restores chapter presentation markers")
	check(not game._show_new_chapter(first, "alone"), "relaunch does not reintroduce a visited chapter")
	var carried := ConfigFile.new()
	DailyActivities.record_mission(carried, "specials", 2, now)
	DailyActivities.record_mission(carried, "blockers", 1, now + 86400)
	check(carried.get_value("daily", "supply_rewards", {}).has("%d:specials" % DailyActivities.day_at(now)), "unclaimed prizes survive the daily reset")
	check(not DailyActivities.claim_supply(carried, "%d:specials" % DailyActivities.day_at(now), now + 86400).is_empty(), "yesterday's earned prize remains claimable")
	game.queue_free()
	await settle()
	print("JOURNEY_CHECKS: %d checks; %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func inspect_screen(screen: Node, label: String) -> void:
	var bounds := get_viewport().get_visible_rect().grow(2)
	for control in screen.find_children("*", "Button", true, false):
		if control.is_visible_in_tree():
			check(bounds.encloses(control.get_global_rect()), label + ": action fits " + control.text)
			check(control.size.y >= 88, label + ": touch target " + control.text)

func click(button: BaseButton) -> void:
	var point := button.get_global_rect().get_center()
	await tap(point)

func tap(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await settle()

func fresh_player_moves() -> void:
	game._campaign_progress.set_value("preferences", "tutorials", true)
	game._campaign_progress.set_value("academy_completed", "first_moves", false)
	game._campaign_progress.set_value("tutorials", "1", false)
	game.get_node("Managers/LevelManager").load_level(1)
	game._begin_level("alone")
	await settle()
	if game._tutorial_action != "academy_lesson":
		game._start_academy_lesson(game.get_node("Managers/LevelManager").get_level_data())
	await settle()
	await screenshot("first-lesson")
	await click(game._tutorial_overlay._acknowledge_button)
	check(game._tutorial_action == "guided_swap", "fresh player's pointer tap moves from introduction into guided play")
	var required: Array = game._board._required_swap.duplicate()
	check(required.size() == 2, "first lesson offers a real valid swap")
	if required.size() == 2:
		var before: int = game._board.get_remaining_moves()
		await tap(game._board.get_cell_screen_rect(required[0]).get_center())
		await tap(game._board.get_cell_screen_rect(required[1]).get_center())
		var deadline := Time.get_ticks_msec() + 5000
		while game._board.is_locked() and game._tutorial_action == "guided_swap" and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		check(game._board.get_remaining_moves() == before - 1, "fresh player's actual pointer swap spends exactly one move")
	game._finish_tutorial()

func screenshot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.test-data/journey-" + label + ".png")

func phone_screens() -> void:
	# Logical 720-wide canvas represents phone widths via Godot's keep-width
	# scaling; the compact height additionally exercises a short phone.
	for dimensions in [Vector2i(360,550), Vector2i(320,568), Vector2i(360,640), Vector2i(390,844), Vector2i(412,915)]:
		var height := roundi(float(dimensions.y) * 720.0 / dimensions.x)
		get_window().content_scale_size = Vector2i(720, height)
		get_window().size = dimensions
		await settle()
		game._show_daily_rewards()
		await settle()
		var hub: RewardsHub = game._daily_rewards_layer.get_node("RewardsHub")
		for page in ["daily", "goals", "prizes"]:
			hub._open(page)
			await settle()
			inspect_screen(hub, "%s %d" % [page, height])
			await screenshot("%s-%d" % [page, height])
			hub.go_back()
		game._close_daily_rewards()
		var season := JsonLoader.load_file("res://levels/level051.json")
		game._show_new_chapter(season, "alone")
		await settle()
		inspect_screen(game._chapter_layer, "chapter %d" % height)
		await screenshot("chapter-%d" % height)
		game._handle_back_request()
		game.get_node("Managers/LevelManager").load_level(1)
		game._begin_level("alone")
		game._finish_tutorial()
		game._board._remaining_moves = 0
		game._on_moves_changed(0)
		game._evaluate_level_end()
		await settle()
		check(is_instance_valid(game._result_layer), "zero moves reaches failure through gameplay end evaluation")
		var actions := game._result_layer.find_child("ResultActions", true, false)
		inspect_screen(actions, "failure %d" % height)
		await screenshot("failure-%d" % height)
		game._dismiss_level_result()
		game._economy_manager.set_lives(5)
		game._current_level_id = 1
		await game._show_level_result(true)
		await settle()
		actions = game._result_layer.find_child("ResultActions", true, false)
		inspect_screen(actions, "victory %d" % height)
		await screenshot("victory-%d" % height)
		var amount: int = game._economy_manager.get_coins()
		await game._show_level_result(true)
		check(game._economy_manager.get_coins() == amount, "result re-entry does not duplicate earned coins")
		game._dismiss_level_result()
		await settle()
	# Returning-player data survives a full save/read round trip.
	var saved := ConfigFile.new()
	CampaignProgressStore.read(saved, Game.CAMPAIGN_PROGRESS_PATH)
	check(saved.get_value("chapter_introductions", "1", false), "returning session retains chapter presentation state")
	check(not game._show_new_chapter(JsonLoader.load_file("res://levels/level001.json"), "alone"), "returning session bypasses completed introduction")
