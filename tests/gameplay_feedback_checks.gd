extends "res://tests/booster_tutorial_playthrough.gd"


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	output = "res://.test-data/feedback"
	if "--short" in OS.get_cmdline_user_args():
		get_window().content_scale_size = Vector2i(720,960)
		get_window().size = Vector2i(600,800)
		output += "-short"
	DirAccess.make_dir_recursive_absolute(output)
	RandomGenerator.initialize(20261103)
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await wait(2.2)
	game._launch_layer.queue_free()
	game._launch_layer = null
	for lesson in game._academy_lessons():
		game._campaign_progress.set_value("academy_completed",str(lesson["id"]),true)
	game.get_node("Managers/LevelManager").load_level(41)
	game._begin_level("alone")
	game._finish_tutorial()
	game._evidence_goal = 100000 # fixture: inspect effects without an early result
	await wait(0.3)
	var board := game._board
	var rest := board.position
	board.play_celebration_shake(1.5)
	await wait(0.06)
	board.play_celebration_shake(1.6)
	await wait(0.45)
	check(board.position.distance_to(rest) < 0.01,"Repeated exaggerated shakes must return to the exact board origin")
	var cell: Vector2i = board._obstacles.keys()[0]
	board._obstacles[cell].get_obstacle_state().set_health(1)
	game._economy_manager.set_booster_count("bomb",5)
	check(board.use_booster_at("bomb",cell),"Bomb must activate on the obstacle")
	await wait(0.11)
	var debris := 0
	for child in game._gameplay_effects.get_children():
		if child is Sprite2D: debris += 1
	check(debris >= 9,"Destroyed obstacle must visibly throw textured fragments")
	await capture("01_obstacle_blast")
	await settle()
	check(board.position.distance_to(rest) < 0.01,"Booster shakes must not move the board permanently")
	var target_type := int(Constants.TileType.get(game._objective_target))
	var target_cell := Vector2i(-1,-1)
	for tile in board.get_all_tiles():
		if int(tile.get_tile_type()) == target_type:
			target_cell = tile.get_grid_position()
			break
	game._economy_manager.set_booster_count("thunder",5)
	check(target_cell.x >= 0 and board.use_booster_at("thunder",target_cell),"Thunder must collect the current objective type")
	await wait(0.16)
	check(game._gameplay_effects.pending_collections > 0,"Visible objective flights must survive the initial impact")
	var large_opaque := false
	for child in game._gameplay_effects.get_children():
		if str(child.name).begins_with("CollectedObjective"):
			large_opaque = child.size.x >= 50 and child.modulate.a > 0.95
	check(large_opaque,"Objective pieces must stay large and opaque until HUD arrival")
	await capture("02_objectives_in_flight")
	await settle()
	await wait(1.0)
	check(game._gameplay_effects.pending_collections == 0,"All collection flights must finish")
	await capture("03_hud_arrivals")
	# Clear mid-flight: no stale completion callback may affect the next level.
	var origins: Array[Vector2] = [Vector2(200,600),Vector2(400,650)]
	game._effects().collect(game._objective_target_icon.texture,origins,game._objective_target_icon)
	game._effects().clear()
	await wait(1.0)
	check(game._effects().pending_collections == 0,"Clearing effects must cancel pending flights safely")
	await check_voice_lane()
	game._economy_manager.set_ethan_count(99)
	check(game._economy_manager.get_ethan_count() == EthanInventory.MAX_ASSISTS, "Ethan assists must stop at the two-assist cap")
	game._economy_manager.set_ethan_count(1)
	# Isolate gifted placement from any Ethan already earned by the earlier cascade.
	for tile in board.get_all_tiles():
		if int(tile.get_tile_type()) == Constants.TileType.ETHAN:
			var cell: Vector2i = tile.get_grid_position()
			board.remove_tile(cell)
			board.set_tile(cell, board._tile_factory.create_tile_at(Constants.TileType.KEY, cell), false)
	var placement := Vector2i(-1,-1)
	for tile in board.get_all_tiles():
		if not board.is_swap_blocked(tile.get_grid_position()) and not tile.has_powerup() and int(tile.get_tile_type()) not in [Constants.TileType.ETHAN,Constants.TileType.VICTOR]:
			placement = tile.get_grid_position()
			break
	var moves_before := board.get_remaining_moves()
	check(placement.x >= 0 and board.use_booster_at("ethan", placement), "Ethan gift places the wildcard")
	await settle()
	check(board.get_remaining_moves() == moves_before, "Ethan placement and its matches preserve moves")
	check(game._economy_manager.get_ethan_count() == 0, "Tiles cleared by Ethan must not generate another assist")
	game._effects().praise("WONDERFUL!",Game.DISPLAY_FONT)
	await capture("04_celebration")
	# End-of-level result must wait for the visible HUD delivery and lock input.
	game._evidence_goal = game._evidence_count
	game._obstacles_goal = game._obstacles_cleared
	game._effects().collect(game._objective_target_icon.texture,origins,game._objective_target_icon)
	game._evaluate_level_end()
	check(game._result_layer == null and board.is_locked(),"Result must wait for the last HUD arrival without allowing another move")
	await wait(1.5)
	check(game._result_layer != null,"Result must appear after the HUD delivery finishes")
	print("GAMEPLAY_FEEDBACK_CHECKS: ",failures.size()," failures")
	var file := FileAccess.open(output+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures},"  "))
	game.queue_free()
	await wait(2.5)
	get_tree().quit(0 if failures.is_empty() else 1)


func settle() -> void:
	var deadline := Time.get_ticks_msec()+15000
	while game._board.is_locked() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	check(not game._board.is_locked(),"Animated move must settle and restore input")


func check_voice_lane() -> void:
	var audio = game.get_node("Managers/AudioManager")
	audio._stop_all_sfx()
	audio._last_praise_tick = -10000
	for id in ["match_nice", "match_great", "match_wonderful", "match_thank_you"]:
		var path: String = audio._resolve_audio_id("sfx", id)
		check(ResourceLoader.exists(path), "%s must resolve to its praise clip" % id)
		check(ResourceManager.load_audio(path) is AudioStreamMP3, "%s must load as spoken MP3 audio" % id)
	var heard: Array[String] = []
	var overlap := [false]
	audio.sound_played.connect(func(id):
		if audio._audio_config.get("voice_cues",{}).has(str(id)):
			heard.append(str(id))
			for player in audio._sfx_players:
				if player.playing: overlap[0] = true)
	audio.play_sfx("powerup_bomb")
	audio.play_sfx("match_nice")
	audio.play_sfx("match_wonderful")
	await wait(0.1)
	check(not audio._voice_player.playing and audio._pending_voice.get("id","")=="match_wonderful","Only the highest praise may wait behind the impact")
	var deadline := Time.get_ticks_msec()+6000
	while heard.is_empty() and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
	check(heard==["match_wonderful"] and not overlap[0],"Exactly one praise must start after the powerup audio has ended")
	check(audio._music_player.volume_db <= -8.0, "Music must duck while a praise clip plays")
	audio.play_sfx("match_nice")
	check(audio._pending_voice.is_empty(),"Praise cooldown must reject repeated chatter")
	audio.play_sfx("tile_match")
	check(audio._sfx_players.is_empty(), "Gameplay effects must not overlap a spoken praise clip")
	audio.play_sfx("level_victory")
	check(audio._pending_voice.get("id","")=="level_victory","Mission announcement must supersede optional praise")
	var music_stream = audio._music_player.stream
	audio.set_sfx_enabled(false)
	check(not audio._voice_player.playing and audio._pending_voice.is_empty(),"Effects mute must clear current and queued voices")
	check(is_zero_approx(audio._music_player.volume_db), "Music volume must return to normal when voice playback stops")
	check(audio._music_player.stream==music_stream and audio._music_player.playing,"Voice scheduling must preserve the working music player")
	audio.set_sfx_enabled(true)
