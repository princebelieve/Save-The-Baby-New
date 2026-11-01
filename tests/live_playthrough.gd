extends Node

var game: Game
var output := "res://.test-data/live-before"
var report: Dictionary = {"screens": [], "clicks": [], "audio": []}
var captures: Dictionary = {}


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Live playthrough requires an isolated .test-data profile.")
		get_tree().quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		if arg == "--short":
			get_window().content_scale_size = Vector2i(720, 960)
			get_window().size = Vector2i(600, 800)
	DirAccess.make_dir_recursive_absolute(output)
	var boot := preload("res://scenes/boot/Boot.tscn").instantiate()
	get_tree().root.add_child.call_deferred(boot)
	await wait(0.5)
	await capture("01_boot")
	await wait(3.3)
	game = get_tree().root.get_node_or_null("Game") as Game
	if game == null:
		push_error("Boot did not create the game")
		get_tree().quit(1)
		return
	await capture("02_loading")
	await wait(1.9)
	_install_audio_captures()
	await wait(1.0)
	await sample_audio("title_music")
	await capture("03_title")
	await click_named(game._launch_layer, "SettingsButton")
	await capture("04_title_settings")
	var music_toggle := game.find_child("MusicEnabled", true, false) as CheckButton
	await click(music_toggle)
	await sample_audio("music_off_with_effect", true)
	await click_named(game.find_child("AudioSettings", true, false), "PreviewMusic")
	await sample_audio("music_preview")
	await dismiss_dialog()
	await click_named(game._launch_layer, "PlayButton")
	await capture("05_story_david")
	for index in range(3):
		if game._is_dialogue_typing:
			await click(game._story_continue_button)
		await capture("06_story_line_%d" % index)
		await click(game._story_continue_button)
	await capture("07_route_choices")
	if game._choice_box.get_child_count() > 0:
		await click(game._choice_box.get_child(0))
	await capture("08_route_response")
	await click(game._story_continue_button)
	await capture("09_campaign_coaching")
	if game._tutorial_overlay != null and game._tutorial_overlay.visible:
		await click(game._tutorial_overlay._acknowledge_button)
	await capture("10_campaign")
	await click_named(game._campaign_map, "Level001")
	await capture("11_chapter_story")
	await click(game._story_skip_button)
	await capture("12_mission_briefing")
	await click_named(game._briefing_layer, "PlayButton")
	await capture("13_tutorial_swipe")
	if game._board._required_swap.size() == 2:
		await swipe(game._board.get_cell_screen_rect(game._board._required_swap[0]).get_center(), game._board.get_cell_screen_rect(game._board._required_swap[1]).get_center())
	await wait(1.4)
	await capture("14_tutorial_goal")
	if game._tutorial_overlay != null and game._tutorial_overlay._acknowledge_button.visible:
		await click(game._tutorial_overlay._acknowledge_button)
	await capture("15_tutorial_pause_prompt")
	await click(game._pause_button)
	await capture("16_pause")
	await sample_audio("pause_music")
	await click_text(game._pause_layer, "SETTINGS")
	await capture("17_pause_settings")
	await dismiss_dialog()
	await click_text(game._pause_layer, "RESUME")
	await capture("18_tutorial_case_prompt")
	await click(game._case_file_button)
	await capture("19_case_file")
	await click_text(game._case_file_layer, "BACK TO SEARCH")
	# Continue exploring even if an earlier cut-off control prevents navigation.
	if game._case_file_layer != null:
		game._close_case_file()
	game._finish_tutorial()
	await capture("20_gameplay")
	await sample_audio("gameplay_music")
	game._show_booster_confirmation("rocket")
	await capture("21_booster_confirmation")
	await click(game._booster_confirm.get_cancel_button())
	game._open_booster_shop("bomb")
	await capture("22_supply_shop")
	await dismiss_dialog(false)
	game._show_life_shop()
	await capture("23_life_shop_or_notice")
	await dismiss_dialog(false)
	game._show_shop_notice("You need more Ethan Coins for this supply.")
	await capture("24_notice")
	await dismiss_dialog()
	game._show_level_result(false)
	await capture("25_failure")
	await click_text(game._result_layer, "RETRY LEVEL")
	if game._story_layer != null and is_instance_valid(game._story_skip_button):
		await click(game._story_skip_button)
	if game._briefing_layer != null:
		await click_named(game._briefing_layer, "PlayButton")
	game._finish_tutorial()
	game._show_level_result(true)
	await capture("26_victory")
	await click_text(game._result_layer, "CAMPAIGN MAP")
	await capture("27_map_progress")
	# Inspect every authored mechanic introduction and representative late HUD.
	for level_id in [8, 9, 16, 23, 31, 41, 42, 43, 46, 48, 49, 50]:
		game.get_node("Managers/LevelManager").load_level(level_id)
		game._show_level_briefing("police")
		await capture("briefing_%03d" % level_id)
		await click_named(game._briefing_layer, "PlayButton")
		await capture("tutorial_%03d" % level_id)
		game._finish_tutorial()
		await capture("gameplay_%03d" % level_id)
	var file := FileAccess.open(output + "/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("LIVE_PLAYTHROUGH_COMPLETE ", output)
	game.queue_free()
	await wait(2.5)
	get_tree().quit()


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func click(button: BaseButton) -> void:
	if not is_instance_valid(button):
		report.clicks.append({"error": "Button missing"})
		return
	var pressed := [false]
	var button_path := str(button.get_path())
	var disabled := button.disabled
	var listener := func(): pressed[0] = true
	button.pressed.connect(listener, CONNECT_ONE_SHOT)
	var point := button.get_global_rect().get_center()
	var viewport := button.get_viewport()
	if viewport is Window and viewport != get_viewport():
		point += Vector2(viewport.position)
	await swipe(point, point)
	report.clicks.append({"button": button_path, "point": str(point), "received": pressed[0], "disabled": disabled})
	if not pressed[0] and is_instance_valid(button):
		if button.pressed.is_connected(listener): button.pressed.disconnect(listener)
		# Record the failed real click, then use its signal to inspect later screens.
		button.pressed.emit()
	await wait(0.4)


func swipe(start: Vector2, end: Vector2, viewport: Viewport = null) -> void:
	if viewport == null: viewport = get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = start
	motion.global_position = start
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = start
	press.global_position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	await wait(0.08)
	var release := InputEventMouseButton.new()
	release.position = end
	release.global_position = end
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	if is_instance_valid(viewport): viewport.push_input(release, true)
	await wait(0.25)


func click_named(parent: Node, node_name: String) -> void:
	if not is_instance_valid(parent):
		report.clicks.append({"error": "Missing parent for " + node_name})
		return
	await click(parent.find_child(node_name, true, false) as BaseButton)


func click_text(parent: Node, text: String) -> void:
	if is_instance_valid(parent):
		for button in parent.find_children("*", "Button", true, false):
			if button.text == text:
				await click(button)
				return
	report.clicks.append({"error": "No button with text: " + text})


func dismiss_dialog(confirm: bool = true) -> void:
	var dialogs := game.find_children("*", "AcceptDialog", true, false)
	for dialog in dialogs:
		if dialog.visible:
			await click(dialog.get_cancel_button() if not confirm and dialog is ConfirmationDialog else dialog.get_ok_button())


func capture(screen_name: String) -> void:
	await wait(0.45)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output + "/" + screen_name + ".png")
	var controls: Array = []
	if is_instance_valid(game):
		for control in game.find_children("*", "Control", true, false):
			if not control.is_visible_in_tree(): continue
			var canvas: CanvasLayer = control.get_canvas_layer_node()
			if canvas != null and not canvas.visible: continue
			if control is Label or control is BaseButton or control is TextureRect:
				var rect: Rect2 = control.get_global_rect()
				controls.append({"path": str(control.get_path()), "type": control.get_class(), "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "text": control.text if control is Label or control is Button else "", "font_size": control.get_theme_font_size("font_size") if control is Label or control is Button else 0})
	report.screens.append({"name": screen_name, "viewport": str(get_viewport().get_visible_rect().size), "controls": controls})
	print("CAPTURE ", screen_name)


func _install_audio_captures() -> void:
	for bus_name in ["Music", "SFX", "Master"]:
		var bus := AudioServer.get_bus_index(bus_name)
		var effect := AudioEffectCapture.new()
		effect.buffer_length = 2.0
		AudioServer.add_bus_effect(bus, effect)
		captures[bus_name] = effect


func sample_audio(stage: String, play_effect: bool = false) -> void:
	for effect in captures.values(): effect.clear_buffer()
	if play_effect: SignalBus.play_sfx.emit("ui_confirm")
	await wait(1.0)
	var audio_manager := game.get_node("Managers/AudioManager")
	var result := {"stage": stage, "driver": AudioServer.get_driver_name(), "device": AudioServer.output_device, "playing": audio_manager._music_player.playing, "paused": audio_manager._music_player.stream_paused, "position": audio_manager._music_player.get_playback_position(), "enabled": audio_manager.is_music_enabled(), "music_volume": audio_manager.get_music_volume(), "buses": {}}
	var stream = audio_manager._music_player.stream
	if stream is AudioStreamWAV:
		result["stream"] = {"length": stream.get_length(), "format": stream.format, "mix_rate": stream.mix_rate, "loop_begin": stream.loop_begin, "loop_end": stream.loop_end, "loop_mode": stream.loop_mode}
	for bus_name in captures:
		var effect: AudioEffectCapture = captures[bus_name]
		var frames := effect.get_frames_available()
		var samples := effect.get_buffer(frames)
		var peak := 0.0
		var energy := 0.0
		for sample in samples:
			peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
			energy += sample.length_squared()
		var bus := AudioServer.get_bus_index(bus_name)
		result.buses[bus_name] = {"frames": frames, "peak": peak, "rms": sqrt(energy / maxf(1.0, frames * 2.0)), "muted": AudioServer.is_bus_mute(bus), "gain_db": AudioServer.get_bus_volume_db(bus)}
	report.audio.append(result)
	var file := FileAccess.open(output + "/audio.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report.audio, "  "))
	file.close()
