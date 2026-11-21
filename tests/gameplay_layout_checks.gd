extends Node

var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	for height in [1100, 1280, 1600]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, height)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var game := preload("res://scenes/game/Game.tscn").instantiate()
		viewport.add_child(game)
		await get_tree().create_timer(2.0).timeout
		game._layout_play_area()
		check(is_instance_valid(game._launch_layer.find_child("CloseGameButton", true, false)), "Title has a visible Close button at %d" % height)
		game._request_exit()
		var exit_prompt := game.get_node("CloseGameConfirmation") as ConfirmationDialog
		check(exit_prompt.visible, "Exit asks for confirmation at %d" % height)
		exit_prompt.canceled.emit()
		for frame in 3: await get_tree().process_frame
		check(not is_instance_valid(exit_prompt), "Cancel exit keeps game running at %d" % height)
		await capture(viewport, "title-%d" % height)
		var board: Board = game._board
		var board_bottom := board.position.y + board.get_height() * board.get_tile_size()
		var dock: Control = game._booster_dock
		check(board.position.y >= 244, "Board clears HUD at %d" % height)
		check(board_bottom <= dock.offset_top - 10, "Board clears tray at %d" % height)
		check(absf((board.position.y + board_bottom) * 0.5 - (244 + height - 216) * 0.5) < 1, "Board centered in play region at %d" % height)
		check(absf(dock.offset_bottom - (height - 24)) < 1, "Tray anchored near bottom at %d" % height)
		check(dock.get_global_rect().end.y <= height - 16, "Actual tray including counts clears bottom at %d" % height)
		if is_instance_valid(game._launch_layer): game._launch_layer.hide()
		if is_instance_valid(game._tutorial_overlay): game._tutorial_overlay.hide()
		await capture(viewport, "board-%d" % height)
		game._show_campaign_map("alone")
		for frame in 12: await get_tree().process_frame
		if is_instance_valid(game._tutorial_overlay): game._tutorial_overlay.hide()
		var bar: Control = game._campaign_map.get_node("BottomNavigation")
		check(bar.get_children()[0].get_child_count() == 4, "Four navigation tabs at %d" % height)
		check(Rect2(Vector2.ZERO, Vector2(720, height)).encloses(bar.get_global_rect()), "Tabs fit phone at %d" % height)
		for tab in bar.get_children()[0].get_children():
			check(tab.size.y >= 92, "Navigation touch target at %d" % height)
		await capture(viewport, "map-%d" % height)
		viewport.queue_free()
		for frame in 8: await get_tree().process_frame
	print("GAMEPLAY_LAYOUT_CHECKS: %d checks; %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func capture(viewport: SubViewport, filename: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.test-data/" + filename + ".png")
