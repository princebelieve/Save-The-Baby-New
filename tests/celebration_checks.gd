extends Node
var failures := 0
var checks := 0
var sounds: Array[String] = []

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 12: await get_tree().process_frame

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	SignalBus.play_sfx.connect(func(sound): sounds.append(str(sound)))
	get_window().size = Vector2i(360,640)
	call_deferred("run")

func pointer(viewport: SubViewport, point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = point
	viewport.push_input(event, true)
	await get_tree().process_frame

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720,1100)
	add_child(viewport)
	var puzzle := PortraitPuzzle.new()
	puzzle.configure({"portrait":str(DailyActivities.settings().portraits[0]), "slot":1, "pieces":[1,0,2,3,4,5,6,7,8], "deadline":TimeHelper.current_unix_time()+120})
	viewport.add_child(puzzle)
	await settle()
	var completions := [0]
	puzzle.completed.connect(func(_slot): completions[0] += 1)
	var first := puzzle._buttons[0].get_global_rect().get_center()
	var second := puzzle._buttons[1].get_global_rect().get_center()
	await pointer(viewport, first, true)
	var motion := InputEventMouseMotion.new()
	motion.position = second
	motion.relative = second-first
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(motion, true)
	await pointer(viewport, second, false)
	await settle()
	check(puzzle._pieces == range(9), "real drag input swaps fragments")
	check(completions[0] == 1, "swipe completes the puzzle exactly once")
	check(sounds.has("tile_swap") and sounds.has("win_sting"), "restoration requests swap and success sounds")
	puzzle.queue_free()
	await settle()
	puzzle = PortraitPuzzle.new()
	puzzle.configure({"portrait":str(DailyActivities.settings().portraits[0]), "slot":2, "pieces":[1,0,2,3,4,5,6,7,8], "deadline":TimeHelper.current_unix_time()+120})
	viewport.add_child(puzzle)
	await settle()
	first = puzzle._buttons[0].get_global_rect().get_center()
	second = puzzle._buttons[1].get_global_rect().get_center()
	await pointer(viewport, first, true)
	await pointer(viewport, first, false)
	await pointer(viewport, second, true)
	await pointer(viewport, second, false)
	check(puzzle._pieces == range(9), "two taps remain compatible with swipe input")
	puzzle.queue_free()
	await settle()
	puzzle = PortraitPuzzle.new()
	puzzle.configure({"portrait":str(DailyActivities.settings().portraits[0]), "slot":3, "pieces":[1,0,2,3,4,5,6,7,8], "deadline":TimeHelper.current_unix_time()+120})
	viewport.add_child(puzzle)
	await settle()
	first = puzzle._buttons[0].get_global_rect().get_center()
	second = puzzle._buttons[1].get_global_rect().get_center()
	for down in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.pressed = down
		touch.position = first if down else second
		viewport.push_input(touch, true)
		await get_tree().process_frame
	check(puzzle._pieces == range(9), "native touch swipe swaps fragments")
	viewport.queue_free()
	await settle()
	var game: Game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._start_opening_story()
	game._skip_opening_story()
	game._finish_tutorial()
	game.get_node("Managers/LevelManager").load_level(1)
	game._begin_level("alone")
	game._finish_tutorial()
	game._completed_levels.erase("1")
	game._campaign_progress.set_value("campaign", "level_points", {})
	game._current_level_points = 0
	game._board.lock()
	game._board._remaining_moves = 3
	var board := game._board
	for tile in board.get_all_tiles():
		tile.get_tile_state().clear_powerup()
	var kinds := ["rocket", "bomb", "thunder"]
	for index in 3:
		var tile: Tile = board.get_tile(Vector2i(index,0))
		tile.get_tile_state().set_powerup(Constants.PowerupType.ROCKET)
		tile.set_meta("powerup_kind", kinds[index])
	var sequence: Array[String] = []
	game.victory_bonus_step.connect(func(kind, _points): sequence.append(kind))
	if "--capture" in OS.get_cmdline_user_args():
		game.victory_bonus_step.connect(func(kind, _points):
			if kind != "move": capture(kind))
	var before_lives := game._economy_manager.get_lives()
	await game._play_board_clear_celebration()
	check(sequence == ["move","move","move","rocket","bomb","thunder"], "moves count down before boosters fire individually in board order")
	check(game._current_level_points >= 1050, "remaining moves and boosters contribute bonus points")
	check(game._clear_bonus_coins == 15, "three remaining boosters earn the established coin bonus")
	check(board.get_all_tiles().is_empty(), "board clears only after the bonus sequence")
	check(game._economy_manager.get_lives() == before_lives, "victory effects never consume a life")
	var awarded := game._current_level_points
	await game._play_board_clear_celebration()
	check(game._current_level_points == awarded, "victory settlement cannot award twice")
	game._result_stars_earned = 3
	game._record_level_completion()
	check(int(game._campaign_progress.get_value("campaign", "level_points", {}).get("1", 0)) == awarded, "victory bonus persists in the level score")
	if game._campaign_progress.has_section("daily"): game._campaign_progress.erase_section("daily")
	DailyActivities.offer_for_clear(game._campaign_progress, 3, true, TimeHelper.current_unix_time())
	var score_before := int(game._campaign_progress.get_value("campaign", "total_points", 0))
	var coins_before := game._economy_manager.get_coins()
	game._start_portrait_attempt()
	puzzle = game._portrait_puzzle
	for index in puzzle._pieces.size():
		if int(puzzle._pieces[index]) != index:
			puzzle._select(index)
			puzzle._select(puzzle._pieces.find(index))
	var earned_points := puzzle._pieces.size() * 25
	check(int(game._campaign_progress.get_value("campaign", "total_points", 0)) == score_before + earned_points, "restoration completion increases total player points")
	check(game._economy_manager.get_coins() == coins_before + 20, "restoration still pays coins and first daily stamp")
	game._complete_portrait_puzzle(int(puzzle._attempt.slot))
	check(int(game._campaign_progress.get_value("campaign", "total_points", 0)) == score_before + earned_points, "restoration duplicate signals cannot repeat points")
	game._record_level_completion()
	check(int(game._campaign_progress.get_value("campaign", "total_points", 0)) == score_before + earned_points, "later case score recalculation retains restoration points")
	if "--capture" in OS.get_cmdline_user_args(): await capture("restoration-reward")
	game.queue_free()
	await settle()
	print("CELEBRATION_CHECKS: %d checks; %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().create_timer(0.18).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.test-data/celebration-" + label + ".png")
