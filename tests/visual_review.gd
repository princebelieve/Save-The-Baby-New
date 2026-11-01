extends Node

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Visual review requires an isolated .test-data profile.")
		get_tree().quit(1)
		return
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
	game._show_level_result(true)
	await get_tree().create_timer(0.6).timeout
	await capture("victory")
	game._next_level_after_win()
	await get_tree().create_timer(0.6).timeout
	await capture("continuing_campaign")
	get_tree().quit()


func capture(screen_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.test-data/%s.png" % screen_name)
