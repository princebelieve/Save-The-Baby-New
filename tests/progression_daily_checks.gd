extends Node

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")


func _run() -> void:
	var progress := ConfigFile.new()
	var now := 20000 * DailyActivities.DAY + 100
	var first := DailyActivities.stamp(progress, now)
	check(int(first.coins) == 5 and int(first.streak) == 1, "First daily stamp")
	check(DailyActivities.stamp(progress, now + 1).is_empty(), "No repeated daily claim")
	check(DailyActivities.stamp(progress, now - 1).is_empty(), "Clock rollback rejected")
	check(int(DailyActivities.stamp(progress, now + 86400).streak) == 2, "Consecutive day")
	check(int(DailyActivities.stamp(progress, now + 3 * 86400).streak) == 3, "One missed day protected")
	check(int(DailyActivities.stamp(progress, now + 5 * 86400).streak) == 1, "Grace cannot be reused within a week")
	var weekly := ConfigFile.new()
	# Start on a UTC Monday.
	var monday := 20003 * 86400 + 100
	for day in 5:
		var reward := DailyActivities.stamp(weekly, monday + day * 86400)
		if day == 4:
			check(int(reward.coins) == 75, "Fifth weekly stamp includes chest coins")
	var missions := ConfigFile.new()
	check(DailyActivities.record_mission(missions, "specials", 1, now) == 0, "Partial daily goal")
	check(DailyActivities.record_mission(missions, "specials", 1, now + 1) == 10, "Daily goal payout")
	check(DailyActivities.record_mission(missions, "specials", 2, now + 2) == 0, "Daily goal pays only once")
	check(DailyActivities.record_mission(missions, "specials", 2, now + 86400) == 10, "Daily goals reset tomorrow")
	progress = ConfigFile.new()
	var attempt := DailyActivities.start_portrait(progress, now)
	check(not attempt.is_empty(), "Portrait slot opens")
	check(DailyActivities.start_portrait(progress, now + 1).is_empty(), "Slot cannot restart")
	check(not DailyActivities.active_attempt(progress, now + 10).is_empty(), "Active attempt resumes")
	check(DailyActivities.finish_portrait(progress, int(attempt.slot), now + 10).is_empty(), "Unsolved portrait earns nothing")
	attempt.pieces = range(attempt.pieces.size())
	progress.set_value("daily", "attempt", attempt)
	var reward := DailyActivities.finish_portrait(progress, int(attempt.slot), now + 20)
	check(int(reward.coins) == 20, "Portrait and first daily stamp combine")
	check(DailyActivities.finish_portrait(progress, int(attempt.slot), now + 21).is_empty(), "Portrait pays only once")
	check(not DailyActivities.available(progress, now + 60), "Completed slot remains consumed")
	check(DailyActivities.available(progress, now + 43200), "Second daily slot available")
	attempt = DailyActivities.start_portrait(progress, now + 43200)
	check(DailyActivities.active_attempt(progress, int(attempt.deadline)).is_empty(), "Deadline expires exactly")
	check(DailyActivities.finish_portrait(progress, int(attempt.slot), int(attempt.deadline) + 1).is_empty(), "Expired puzzle pays nothing")
	var boundary := ConfigFile.new()
	attempt = DailyActivities.start_portrait(boundary, now - 100 + 43199)
	check(int(attempt.deadline) == now - 100 + 43199 + int(DailyActivities.puzzle_for_slot(int(attempt.slot)).seconds), "Starting near reset grants the full advertised duration")
	for portrait in DailyActivities.settings().portraits:
		check(ResourceLoader.exists(str(portrait)), "Portrait asset exists: %s" % portrait)
	var catalog: Array = DailyActivities.settings().portraits
	var seen: Dictionary = {}
	var dimensions: Dictionary = {}
	for slot in catalog.size():
		var sample_progress := ConfigFile.new()
		var sample := DailyActivities.start_portrait(sample_progress, slot * 43200 + 100)
		check(not seen.has(sample.portrait), "Artwork does not repeat within catalog rotation")
		seen[sample.portrait] = true
		var size := int(sample.columns) * int(sample.rows)
		dimensions[size] = true
		check(sample.pieces.size() == size, "Difficulty matches permutation length")
		var sorted: Array = sample.pieces.duplicate()
		sorted.sort()
		check(sorted == range(size), "Every fragment occurs exactly once")
		check(sample.pieces != range(size), "Puzzle starts shuffled")
		check(DailyActivities.finish_portrait(sample_progress, int(sample.slot), slot * 43200 + 101).is_empty(), "Unsolved larger puzzle cannot pay")
		sample.pieces = range(size)
		sample_progress.set_value("daily", "attempt", sample)
		check(not DailyActivities.finish_portrait(sample_progress, int(sample.slot), slot * 43200 + 102).is_empty(), "Every difficulty completes and pays")
	check(dimensions.has(9) and dimensions.has(16) and dimensions.has(25), "Three difficulty sizes rotate")
	for tile in JsonLoader.load_file("res://configs/tiles.json").tiles:
		check(catalog.has(str(tile.icon)), "All tile artwork included: " + str(tile.id))
	var legacy := ConfigFile.new()
	legacy.set_value("daily", "attempt", {"slot": DailyActivities.slot_at(now), "portrait": str(catalog[0]), "pieces": range(9), "deadline": now + 120})
	check(not DailyActivities.finish_portrait(legacy, DailyActivities.slot_at(now), now + 1).is_empty(), "Existing nine-piece saves still complete")
	var calculator := RewardCalculator.new()
	add_child(calculator)
	calculator.initialize()
	var authored_rewards: Array = calculator.calculate_level_rewards({"level": 1})
	check(not authored_rewards.is_empty() and typeof(authored_rewards[0].amount) == TYPE_INT and typeof(authored_rewards[0].type) == TYPE_INT, "File-backed reward numbers normalize to internal integers")
	check(calculator.calculate_reward_set("test", [{"type": 0, "amount": 1.5}]).is_empty(), "Fractional reward counts remain invalid")
	calculator.queue_free()
	var manager := load("res://scripts/managers/LevelManager.gd").new() as Node
	add_child(manager)
	var shuffler := BoardShuffler.new()
	shuffler.initialize()
	var database := TileDatabase.new()
	database.initialize()
	var signatures: Dictionary = {}
	for level_id in range(51, 1051):
		var path := "res://levels/level%03d.json" % level_id
		check(FileAccess.file_exists(path), "Level file exists: %s" % path)
		var definition := JsonLoader.load_file(path)
		check(not definition.is_empty(), "Level JSON parses: %s" % path)
		check(manager._validate_level(definition), "Full schema %d" % level_id)
		check(int(definition.level_id) == level_id, "Correct level identity")
		var episode := (level_id-51)/10+1
		var step := (level_id-51)%10
		check(definition.story.before_level == ("serial%03d_intro" % episode if step == 0 else ""), "Episode intro hook %d" % level_id)
		check(definition.story.after_level == ("serial%03d_outro" % episode if step == 9 else ""), "Episode discovery hook %d" % level_id)
		var generator := BoardGenerator.new()
		generator._tile_database = database
		generator._load_level_tile_pool(definition.tile_pool)
		generator._seeded_rng = RandomNumberGenerator.new()
		generator._seeded_rng.seed = int(definition.metadata.seed)
		for cell in definition.board.blocked_cells:
			generator._blocked_cells[Vector2i(int(cell[0]), int(cell[1]))] = true
		var grid: Dictionary = generator._generate_type_grid(int(definition.board.columns), int(definition.board.rows))
		check(not grid.is_empty(), "Legal starting grid %d" % level_id)
		var occupied: Dictionary = {}
		for obstacle in definition.obstacles.items:
			var cell := Vector2i(int(obstacle.x), int(obstacle.y))
			check(grid.has(cell) and not occupied.has(cell), "Valid distinct obstacle placement")
			occupied[cell] = true
		var signature := JSON.stringify([definition.board, definition.objectives, definition.obstacles, definition.tile_pool])
		check(not signatures.has(signature), "Distinct level composition %d" % level_id)
		signatures[signature] = true
		generator.free()
		if level_id % 100 == 0:
			print("Checked %d level files" % (level_id - 50))
		if true:
			var board := Board.new()
			add_child(board)
			check(board.initialize(definition), "Runtime file-backed board %d" % level_id)
			check(board.is_stable() and not shuffler.needs_shuffle(board), "Runtime board playable after obstacles %d" % level_id)
			if level_id % 100 == 0:
				var before: Array[int] = []
				for tile in board.get_all_tiles():
					before.append(tile.get_tile_type())
				var retry := Board.new()
				add_child(retry)
				check(retry.initialize(definition), "Seeded retry initializes")
				var after: Array[int] = []
				for tile in retry.get_all_tiles():
					after.append(tile.get_tile_type())
				check(before == after, "Seeded retries recreate the same opening")
				retry.queue_free()
			board.queue_free()
			await get_tree().process_frame
	check(not manager.has_level(1051), "Campaign upper bound has no file")
	check(manager.load_level(1050) and manager.is_last_level(), "Final case loads and is final")
	check(manager.has_level(51) and not manager.has_level(1051), "Navigation crosses authored boundary")
	check(manager.load_level(51) and manager.get_level_data() == JsonLoader.load_file("res://levels/level051.json"), "Loader reads the numbered JSON file")
	manager.queue_free()
	database.free()
	shuffler.free()
	await _check_game_integration()
	print("PROGRESSION_DAILY_CHECKS: %d failures; 1,000 level JSON files and boards checked" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_game_integration() -> void:
	var game := preload("res://scenes/game/Game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	check(CampaignProgressStore.unlocked_level({}, 1050) == 1, "Fresh players only unlock level 1")
	check(CampaignProgressStore.unlocked_level({"1": 2}, 1050) == 2, "Winning level 1 unlocks only level 2")
	check(CampaignProgressStore.unlocked_level({"1": 2, "3": 3, "21": 3}, 1050) == 2, "Out-of-order wins cannot unlock unreached levels")
	check(CampaignProgressStore.unlocked_level({"1": 0}, 1050) == 1, "Failed levels do not unlock the next node")
	var real_completed: Dictionary = game._completed_levels.duplicate(true)
	var saved_progress: String = game._campaign_progress.encode_to_text()
	game._campaign_progress.set_value("campaign", "completed_levels", {})
	game._campaign_progress.set_value("campaign", "highest_unlocked_level", 21)
	check(CampaignProgressStore.write(game._campaign_progress, Game.CAMPAIGN_PROGRESS_PATH) == OK, "Inflated unlock fixture saves in isolated test profile")
	game._load_campaign_progress()
	check(game._highest_unlocked_level == 1, "Loading an inflated unlock value repairs access from actual wins")
	game._campaign_progress.clear()
	game._campaign_progress.parse(saved_progress)
	CampaignProgressStore.write(game._campaign_progress, Game.CAMPAIGN_PROGRESS_PATH)
	game._completed_levels = {}
	game._highest_unlocked_level = 1
	game._campaign_coach_shown = true
	game._show_campaign_map("alone")
	for frame in 8: await get_tree().process_frame
	var fresh_map: CampaignMap = game._campaign_map
	var first: TextureButton = fresh_map.find_child("Level001", true, false)
	var second: TextureButton = fresh_map.find_child("Level002", true, false)
	check(first != null and not first.disabled, "Fresh map allows level 1")
	check(second != null and second.disabled, "Fresh map locks level 2")
	fresh_map.scroll_to_level(21)
	for frame in 8: await get_tree().process_frame
	var twenty_one: TextureButton = fresh_map.find_child("Level021", true, false)
	check(twenty_one != null and twenty_one.disabled, "Level 21 is visible when scrolled to but locked")
	fresh_map.scroll_to_level(1050)
	for frame in 8: await get_tree().process_frame
	var final_node: TextureButton = fresh_map.find_child("Level1050", true, false)
	check(final_node != null and final_node.disabled, "Fresh players can scroll to the locked final level")
	check(game._highest_unlocked_level == 1 and fresh_map._highest_unlocked_level == 1, "Scrolling never unlocks levels")
	var manager: Node = game.get_node("Managers/LevelManager")
	var before_selection: int = manager.current_level()
	game._on_campaign_level_selected(21, "alone")
	check(manager.current_level() == before_selection, "Direct selection also rejects an unreached level")
	game._completed_levels = real_completed
	game._highest_unlocked_level = 1050
	var records := game._load_campaign_level_records()
	check(records.size() == 1050 and int(records[0].level_id) == 1 and int(records.back().level_id) == 1050, "Map exposes the complete trail")
	game._campaign_coach_shown = true
	game._show_campaign_map("alone")
	await get_tree().process_frame
	check(game._campaign_map.find_child("Level1050", true, false) != null, "Final map page rendered")
	game._campaign_progress.set_value("generated_levels", "51", {"name": "Stale runtime snapshot"})
	var file_records := game._load_campaign_level_records()
	check(str(file_records[50].name) == str(JsonLoader.load_file("res://levels/level051.json").name), "Map reads files rather than stale generated snapshots")
	game._campaign_map.scroll_chapters(-1)
	await get_tree().process_frame
	check(game._campaign_map._map_scroll.scroll_vertical < int(game._campaign_map._level_positions[1050].y), "Map scrolls backward without replacing the trail")
	if game._campaign_progress.has_section("daily"):
		game._campaign_progress.erase_section("daily")
	var coins := game._economy_manager.get_coins()
	var lives := game._economy_manager.get_lives()
	game._start_portrait_attempt()
	await get_tree().process_frame
	var attempt: Dictionary = game._campaign_progress.get_value("daily", "attempt", {})
	check(game._portrait_puzzle != null, "Portrait opens from campaign")
	var puzzle := game._portrait_puzzle
	# Solve through the actual tap handler and saved swap signals.
	for index in puzzle._pieces.size():
		if int(puzzle._pieces[index]) != index:
			var other := puzzle._pieces.find(index)
			puzzle._select(index)
			puzzle._select(other)
	check(game._economy_manager.get_coins() == coins + 20, "Actual portrait grants coins and daily stamp")
	check(game._economy_manager.get_lives() == lives, "Portrait does not consume campaign lives")
	game._complete_portrait_puzzle(int(attempt.slot))
	check(game._economy_manager.get_coins() == coins + 20, "Duplicate UI completion cannot pay twice")
	var saved := ConfigFile.new()
	check(CampaignProgressStore.read(saved, Game.CAMPAIGN_PROGRESS_PATH) == OK, "Activity save readable")
	check(int(saved.get_value("campaign", "coins", -1)) == coins + 20 and int(saved.get_value("daily", "streak", 0)) == 1, "Claim marker and economy persist together")
	game.get_node("Managers/LevelManager").load_level(51)
	game._current_level_id = 51
	game._completed_levels.erase("51")
	game._result_stars_earned = 3
	game._clear_bonus_coins = 0
	check(game._record_level_completion(), "File-backed campaign first clear")
	check(game._economy_manager.get_coins() == coins + 50, "File-backed level grants configured rewards without a second daily stamp")
	game._record_level_completion()
	check(game._economy_manager.get_coins() == coins + 50, "Campaign replay cannot repeat first-clear rewards")
	game._close_portrait_puzzle()
	game._show_daily_rewards()
	check(game._daily_rewards_layer != null, "Daily rewards and album opens")
	game._handle_back_request()
	check(game._daily_rewards_layer == null, "Android back dismisses album")
	game.queue_free()
	await get_tree().process_frame
