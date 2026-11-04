extends Node

var output := "res://.test-data"

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Visual review requires an isolated .test-data profile.")
		get_tree().quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2.2).timeout
	await capture("title")
	game._launch_layer.queue_free()
	game._launch_layer = null
	game._campaign_coach_shown = true
	game._show_campaign_map("alone")
	await get_tree().create_timer(0.5).timeout
	await capture("campaign")
	game._campaign_layer.queue_free()
	game._campaign_layer = null
	game.get_node("Managers/LevelManager").load_level(8)
	game._begin_level("alone")
	game._finish_tutorial()
	await get_tree().create_timer(0.8).timeout
	await capture("gameplay")
	game._show_pause_menu(true)
	await get_tree().create_timer(0.3).timeout
	await capture("pause")
	game._close_pause_menu()
	game.get_node("Managers/LevelManager").load_level(50)
	game._begin_level("alone")
	game._finish_tutorial()
	game._current_level_points = 1200
	var leftover_special := game._board.get_tile(Vector2i.ZERO) as Tile
	if leftover_special != null:
		leftover_special.set_powerup(Constants.PowerupType.ROCKET)
	await game._show_level_result(true)
	await get_tree().create_timer(0.6).timeout
	await capture("victory")
	await game._next_level_after_win()
	await get_tree().create_timer(0.6).timeout
	await capture("continuing_campaign")
	for _line in 4:
		if game._is_dialogue_typing:
			game._finish_dialogue_typing()
		game._story_manager.next_dialogue()
		await get_tree().process_frame
	print("SEASON10_PROGRESS ", game._story_manager.get_story_progress(), " CHOICES ", game._choice_box.get_child_count())
	if game._choice_box.get_child_count() != 3:
		push_error("Season 10 must present three story choices; progress=%s choice_count=%d" % [str(game._story_manager.get_story_progress()), game._choice_box.get_child_count()])
		get_tree().quit(1)
		return
	(game._choice_box.get_child(1) as Button).pressed.emit()
	await get_tree().process_frame
	for _page in 8:
		if not is_instance_valid(game._detail_layer):
			break
		var popup := game._detail_layer.get_node_or_null("IllustratedDetailCard") as IllustratedPopup
		if popup == null:
			break
		popup._acknowledge_button.pressed.emit()
		await get_tree().process_frame
	if game._current_route_id != "signal":
		push_error("Season 10 choice must update the selected story route")
		get_tree().quit(1)
		return
	var choice_history: Dictionary = game._campaign_progress.get_value("story_choices", "history", {})
	if not choice_history.has("season10"):
		push_error("Season 10 choice must be saved in campaign history")
		get_tree().quit(1)
		return
	await capture("seasonal_choice_response")
	if game._is_dialogue_typing:
		game._finish_dialogue_typing()
	game._advance_selected_story_choice("signal")
	await get_tree().process_frame
	if game._story_layer != null:
		push_error("Season 10 story must close after its selected response")
		get_tree().quit(1)
		return
	print("SEASONAL_STORY_CHOICE_PASS season10 signal")
	get_tree().quit()


func capture(screen_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [output, screen_name])
