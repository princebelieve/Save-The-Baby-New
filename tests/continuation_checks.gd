extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var game: Game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	Engine.time_scale = 4.0
	game._skip_opening_story()
	game._highest_unlocked_level = 100
	for level in range(1,67): game._completed_levels[str(level)] = true
	var data := JsonLoader.load_file("res://levels/level068.json")
	game._campaign_progress.set_value("chapter_introductions",str(int(data.metadata.chapter_id)),true)
	game._campaign_progress.set_value("story_seen",str(data.get("story",{}).get("before_level","")),true)
	game._campaign_progress.set_value("daily","portrait_offer_presented",DailyActivities.slot_at(TimeHelper.current_unix_time()))
	game.get_node("Managers/LevelManager").load_level(67)
	game._begin_level("alone")
	game._finish_tutorial()
	game._current_level_id = 67
	await game._show_level_result(true)
	game._portrait_continuation = game._next_level_after_win
	game._show_portrait_attempt({"portrait":str(DailyActivities.settings().portraits[0]),"slot":1,"pieces":[0,1,2,3,4,5,6,7,8],"deadline":TimeHelper.current_unix_time()+120})
	game._portrait_puzzle.show_reward(15,1)
	game._close_portrait_puzzle()
	await get_tree().create_timer(.3).timeout
	print("CONTINUE STATE ads=",game._ads.busy," portrait=",game._portrait_layer," result=",game._result_layer," pending=",game._pending_story_id," chapter=",game._chapter_layer)
	check(is_instance_valid(game._briefing_layer),"restoration continues to next briefing")
	if is_instance_valid(game._briefing_layer):
		game._show_level_briefing("alone")
		await get_tree().create_timer(.5).timeout
		for button in game._briefing_layer.find_children("*","Button",true,false):
			if button.text == "PLAY":
				var rect: Rect2 = button.get_global_rect()
				print("PLAY_RECT: ", rect, " viewport=", get_viewport().get_visible_rect(), " disabled=",button.disabled)
				for down in [true, false]:
					var event := InputEventMouseButton.new()
					event.position = rect.get_center()
					event.button_index = MOUSE_BUTTON_LEFT
					event.pressed = down
					get_viewport().push_input(event, true)
					await get_tree().process_frame
				break
		await get_tree().create_timer(.3).timeout
		check(game._current_level_id == 68 and game._briefing_layer == null,"Play enters level 68")
		check(not get_tree().paused,"Play restores gameplay processing")
		var lingering_play := 0
		for action in game.find_children("*","Button",true,false):
			if action.text == "PLAY" and action.is_visible_in_tree(): lingering_play += 1
		check(lingering_play == 0,"repeated briefing cannot leave a stale Play screen over gameplay")
		check(game._briefing_layer == null and game._pause_layer == null,"old briefing and pause surfaces are cleared")
		var move: Array[Vector2i] = game._board.find_valid_swap_for_type(-1)
		check(move.size() == 2,"level 68 offers a playable move")
		if move.size() == 2:
			check(game._board.swap_tiles(move[0],move[1]),"level 68 accepts input after restoration")
			var deadline := Time.get_ticks_msec() + 10000
			while game._board.is_locked() and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(not game._board.is_locked(),"first move finishes after restored Play")
	game.queue_free()
	await get_tree().process_frame
	print("CONTINUATION_CHECKS: %d failures" % failures)
	get_tree().quit(0 if failures==0 else 1)
