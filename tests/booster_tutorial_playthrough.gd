extends Node

var failures: Array[String] = []
var game: Game
var output := "res://.test-data/level41"


func _ready() -> void:
	if "--fast" in OS.get_cmdline_user_args(): Engine.time_scale = 3.0
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Use an isolated .test-data profile for this test.")
		get_tree().quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument == "--short":
			get_window().content_scale_size = Vector2i(720, 960)
			get_window().size = Vector2i(600, 800)
			output += "-short"
	DirAccess.make_dir_recursive_absolute(output)
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await wait(2.2)
	game._launch_layer.queue_free()
	game._launch_layer = null
	for level_id in [4, 6, 8]:
		await exercise_tutorial(level_id)
	print("BOOSTER_TUTORIAL_CHECKS: ", failures.size(), " failures")
	var report := FileAccess.open(output + "/result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures, "viewport": str(get_viewport().get_visible_rect().size)}, "  "))
	report.close()
	game.queue_free()
	await wait(2.5)
	get_tree().quit(0 if failures.is_empty() else 1)


func exercise_tutorial(level_id: int) -> void:
	var level_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level%03d.json" % level_id))
	var steps: Array = level_data.get("tutorial", {}).get("steps", [])
	if steps.is_empty():
		return
	var kind := str(steps[0].get("booster", ""))
	if kind.is_empty(): return
	game._dismiss_level_result()
	game._campaign_progress.set_value("tutorials", str(level_id), false)
	for lesson in game._academy_lessons():
		game._campaign_progress.set_value("academy", str(lesson["id"]), true)
		game._campaign_progress.set_value("academy_completed", str(lesson["id"]), true)
	game._economy_manager.set_booster_count(kind, 0)
	game.get_node("Managers/LevelManager").load_level(level_id)
	game._begin_level("alone")
	# Keep this test focused on tutorial completion, even if the practice clear
	# would otherwise win this small collection goal immediately.
	game._evidence_goal = 100000
	var uses := [0]
	var inventory_after_use := [-1]
	game._board.booster_used.connect(func(used_kind: String):
		if used_kind == kind:
			uses[0] += 1
			inventory_after_use[0] = game._economy_manager.get_booster_count(kind)
	)
	await wait(0.5)
	check(game._tutorial_action == "explain_booster", "Level %d must start with a Continue step" % level_id)
	var overlay := game._tutorial_overlay
	check(overlay._acknowledge_button.visible, "Intro Continue must be visible")
	check(overlay._bubble.get_global_rect().encloses(overlay._acknowledge_button.get_global_rect()), "Continue must be inside the bubble")
	await capture("%03d_1_intro" % level_id)
	await complete_pages(overlay)
	check(game._tutorial_action == "booster_select", "Continue must advance to selecting the booster")
	check(game._economy_manager.get_booster_count(kind) == 1, "Empty supplies must receive one practice booster")
	var booster: BaseButton = game._booster_buttons[kind]["button"]
	check(not overlay._bubble.get_global_rect().intersects(booster.get_global_rect()), "Tutorial bubble must not cover the booster")
	check(overlay._bubble.get_global_rect().encloses(overlay._body_scroll.get_global_rect()), "Action text must shrink to fit its card after a large popup")
	check(overlay._gesture_hand.visible and overlay._gesture_tween.is_running(), "Animated finger must guide booster selection")
	await capture("%03d_2_select" % level_id)
	await click_button(booster)
	check(game._tutorial_action == "booster_target", "Clicking the booster must advance to targeting")
	check(game._board._booster_mode == kind, "Booster targeting must actually be armed on the board")
	check(overlay._gesture_hand.visible, "Animated finger must identify the board target")
	await capture("%03d_3_target" % level_id)
	var point := game._board.get_cell_screen_rect(game._tutorial_target_cell).get_center()
	await pointer_click(point)
	var deadline := Time.get_ticks_msec() + 12000
	while game._tutorial_action != "explain_booster_result" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(game._tutorial_action == "explain_booster_result", "Booster activation must reach its result explanation")
	check(overlay._acknowledge_button.visible, "Result Continue must be visible")
	await capture("%03d_4_result" % level_id)
	await complete_pages(overlay)
	check(not game._tutorial_active, "Continue must finish booster training")
	check(not game._board.is_locked(), "Board must be playable after training")
	check(uses[0] == 1 and inventory_after_use[0] == 0, "Practice booster must be spent once before any cascade rewards")
	var move := game._board.find_valid_swap()
	var previous_moves := game._board.get_remaining_moves()
	check(move.size() == 2, "A regular move must be available after training")
	if move.size() == 2:
		await pointer_click(game._board.get_cell_screen_rect(move[0]).get_center())
		await pointer_click(game._board.get_cell_screen_rect(move[1]).get_center())
		await wait(0.5)
		check(game._board.get_remaining_moves() == previous_moves - 1, "A real board move must work after tutorial completion")
	await capture("%03d_5_playing" % level_id)
	print("PLAYED BOOSTER TUTORIAL ", level_id)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func click_button(button: BaseButton) -> void:
	var clicked := [false]
	var listener := func(): clicked[0] = true
	button.pressed.connect(listener, CONNECT_ONE_SHOT)
	await pointer_click(button.get_global_rect().get_center())
	check(clicked[0], "Tutorial control must receive the real pointer click")
	if not clicked[0] and button.pressed.is_connected(listener): button.pressed.disconnect(listener)


func pointer_click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	get_viewport().push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await wait(0.12)
	await wait(0.35)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func capture(screen_name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await wait(0.3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output + "/" + screen_name + ".png")


func complete_pages(overlay) -> void:
	while overlay.visible and overlay._acknowledge_button.visible:
		if overlay is TutorialOverlay:
			check(overlay._body_label.get_line_count() <= 2, "Gameplay tutorial pages must render at most two lines")
		var last: bool = overlay._page == overlay._pages.size() - 1
		await click_button(overlay._acknowledge_button)
		if last: break
