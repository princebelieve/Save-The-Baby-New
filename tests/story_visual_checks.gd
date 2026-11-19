extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var game: Game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._start_opening_story()
	await get_tree().create_timer(1).timeout
	game._finish_dialogue_typing()
	check(is_instance_valid(game._story_layer), "conversation screen exists")
	check(game._story_scroll_top_roll == null, "decorative line is absent")
	check(game._story_layer.find_child("StoryBrand",true,false) == null, "conversation omits the logo")
	check(game._dialogue_label.get_theme_font_size("font_size") >= 32, "conversation text remains readable")
	check(game._story_portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "portrait is not cropped")
	check(game._story_dialogue_panel.get_global_rect().encloses(game._dialogue_label.get_global_rect()), "dialogue fits inside the card")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.test-data/story-conversation-review.png")
	game.queue_free()
	await get_tree().process_frame
	print("STORY_VISUAL_CHECKS: %d failures" % failures)
	get_tree().quit(0 if failures==0 else 1)
