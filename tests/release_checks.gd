extends Node

var failures: Array[String] = []

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Release checks require an isolated profile. Run tools/run_checks.ps1.")
		get_tree().quit(1)
		return
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	RandomGenerator.initialize(20261101)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(Game.CAMPAIGN_PROGRESS_PATH + suffix):
			DirAccess.remove_absolute(Game.CAMPAIGN_PROGRESS_PATH + suffix)
	var path := "user://release_check_progress.cfg"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	var config := ConfigFile.new()
	config.set_value("campaign", "coins", 123)
	check(CampaignProgressStore.write(config, path) == OK, "First save must succeed")
	config.set_value("campaign", "coins", 456)
	check(CampaignProgressStore.write(config, path) == OK, "Replacement save must succeed")
	var loaded := ConfigFile.new()
	check(CampaignProgressStore.read(loaded, path) == OK, "Primary must load")
	check(loaded.get_value("campaign", "coins") == 456, "Latest progress must survive")
	var broken := FileAccess.open(path, FileAccess.WRITE)
	broken.store_string("[broken")
	broken.close()
	check(CampaignProgressStore.read(loaded, path) == OK, "Backup must recover a corrupt primary")
	check(loaded.get_value("campaign", "coins") == 123, "Recovery must use previous successful save")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)

	var lives := LifeSystem.new()
	lives.initialize()
	lives.restore_full_lives()
	lives.restore_regeneration_time(TimeHelper.current_unix_time() - 86400)
	lives.lose_life(1)
	lives.restore_regenerated_lives()
	check(lives.get_lives() == 4, "Spending a life after a full day must start a new refill timer")
	lives.set_lives(0)
	lives.restore_regeneration_time(TimeHelper.current_unix_time() - 86400)
	lives.restore_regenerated_lives()
	check(lives.is_full(), "Offline time must refill lives up to the cap")
	lives.free()
	var audio_script := preload("res://scripts/managers/AudioManager.gd")
	var audio := audio_script.new()
	add_child(audio)
	audio.set_music_volume(0.37)
	audio.set_sfx_volume(0.64)
	audio.set_music_enabled(false)
	audio.queue_free()
	await get_tree().process_frame
	var restored_audio := audio_script.new()
	add_child(restored_audio)
	check(is_equal_approx(restored_audio.get_music_volume(), 0.37), "Music volume must persist")
	check(is_equal_approx(restored_audio.get_sfx_volume(), 0.64), "Sound volume must persist independently")
	check(not restored_audio.is_music_enabled(), "Muted music must stay muted after restart")
	restored_audio.set_music_enabled(true)
	restored_audio.queue_free()

	for level_id in range(1, 51):
		var level_path := "res://levels/level%03d.json" % level_id
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(level_path))
		check(data is Dictionary, "Level %d must parse" % level_id)
		if data is not Dictionary:
			continue
		check(int(data.get("level_id", 0)) == level_id, "Level identity must match filename")
		check(not data.get("objectives", []).is_empty(), "Level %d needs objectives" % level_id)
		check(int(data.get("moves", {}).get("total", 0)) > 0, "Level %d needs moves" % level_id)
		check(data.get("tutorial", {}).get("steps", []) is Array, "Level %d tutorial steps must be a list" % level_id)
		var map := CampaignMap.new()
		var metadata: Dictionary = data.get("metadata", {})
		for field in ["map_background", "map_landmark"]:
			var directory := CampaignMap.BACKGROUND_DIR if field == "map_background" else CampaignMap.PROP_DIR
			check(ResourceLoader.exists(map._asset_path(directory, str(metadata.get(field, "")))), "Level %d map art must exist" % level_id)
		map.free()
		var board := Board.new()
		add_child(board)
		check(board.initialize(data), "Level %d must generate a board" % level_id)
		check(board.is_stable(), "Level %d must start without matches" % level_id)
		var shuffler := BoardShuffler.new()
		shuffler.initialize()
		check(not shuffler.needs_shuffle(board), "Level %d must have a legal opening move" % level_id)
		var first: Tile = board.get_tile(Vector2i.ZERO)
		first.set_powerup(Constants.PowerupType.ROCKET)
		check(not board.swap_tiles(Vector2i.ZERO, Vector2i(3, 3)), "Specials must reject distant swaps")
		check(board.get_remaining_moves() == int(data["moves"]["total"]), "Rejected swaps must not spend moves")
		first.clear_powerup()
		if level_id in [1, 8, 22, 40, 50]:
			var validator := MoveValidator.new()
			var accepted := false
			for tile in board.get_all_tiles():
				if accepted:
					break
				for neighbor in board.get_neighbors(tile.get_grid_position()):
					if validator.is_valid_swipe(tile, neighbor):
						accepted = board.swap_tiles(tile.get_grid_position(), neighbor.get_grid_position())
						break
			check(accepted, "Level %d must accept a legal move" % level_id)
			var deadline := Time.get_ticks_msec() + 15000
			while board.is_locked() and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(not board.is_locked(), "Level %d must finish its cascades" % level_id)
			check(board.is_stable(), "Level %d must resolve to a stable board" % level_id)
			check(board.get_all_tiles().size() == board.get_width() * board.get_height(), "Gravity must refill every cell")
			check(board.get_remaining_moves() == int(data["moves"]["total"]) - 1, "One legal swap must cost exactly one move")
			validator.free()
		shuffler.free()
		board.queue_free()
		await get_tree().process_frame
	await _check_special_combinations()
	await _check_dead_board()
	await _check_phone_layouts()
	await _check_story_flow()
	print("Release checks: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_dead_board() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level001.json"))
	var board := Board.new()
	add_child(board)
	check(board.initialize(data), "Dead-board test must initialize")
	for y in range(8):
		for x in range(8):
			board.get_tile(Vector2i(x, y)).set_tile_type((x + y * 2) % 5)
	var shuffler := BoardShuffler.new()
	shuffler.initialize()
	check(board.is_stable() and shuffler.needs_shuffle(board), "The dead-board fixture must have no matches or legal moves")
	shuffler.shuffle(board)
	check(board.is_stable() and not shuffler.needs_shuffle(board), "Shuffling must restore a stable playable board")
	check(board.get_all_tiles().size() == 64 and board.get_remaining_moves() == int(data["moves"]["total"]), "Shuffle must preserve a full board and not spend moves")
	var identities := {}
	for tile in board.get_all_tiles():
		identities[tile.get_instance_id()] = true
	check(identities.size() == 64, "Shuffle must not duplicate tile references")
	shuffler.free()
	board.queue_free()
	await get_tree().process_frame


func _check_story_flow() -> void:
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2.0).timeout
	var audio := game.get_node("Managers/AudioManager")
	check(audio._music_player.playing and not audio._music_player.stream_paused, "Title music must start without entering the story")
	game._start_opening_story()
	game._skip_opening_story()
	await get_tree().process_frame
	check(game._launch_layer == null, "Starting play must clear the launch-screen reference")
	check(game._campaign_layer != null, "Skipping opening must reach the campaign map")
	game.get_node("Managers/LevelManager").load_level(50)
	game._begin_level("alone")
	game._finish_tutorial()
	game._show_booster_confirmation("rocket")
	check(game._board.is_locked(), "Booster confirmation must block board input")
	game._booster_confirm.canceled.emit()
	check(not game._board.is_locked(), "Canceling confirmation must restore play")
	game._selected_booster = "rocket"
	game._board.set_booster_mode("rocket")
	game._cancel_booster_targeting()
	check(not game._board.is_locked(), "Canceling a booster target must not freeze the board")
	game._show_level_result(true)
	check(game._completed_levels.has("50"), "Final case completion must persist")
	game._next_level_after_win()
	await get_tree().process_frame
	check(game._pending_level_id == 0 and game._campaign_layer != null, "The last available case must return to the continuing campaign map")
	check(audio._music_player.stream != null and audio._current_music_track == "suspense_opening", "Resuming the campaign must request background music")
	var music_bus := AudioServer.get_bus_index("Music")
	check(music_bus >= 0, "Audio initialization must provide a Music bus")
	check(audio._music_player.playing and music_bus >= 0 and not AudioServer.is_bus_mute(music_bus), "Campaign music must remain enabled during progression")
	var extension: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level001.json"))
	extension["level_id"] = 51
	extension["metadata"]["chapter_id"] = 7
	extension["metadata"]["chapter_start_level"] = 51
	extension["metadata"]["chapter_end_level"] = 60
	var future_map := CampaignMap.new()
	var records: Array[Dictionary] = [extension]
	future_map.configure("Continuing the search", records, 51)
	add_child(future_map)
	var next_case := future_map.get_node_or_null("CampaignScroll/CampaignTrail/Level051") as BaseButton
	check(next_case != null and not next_case.disabled, "New content beyond 50 must appear as playable campaign content")
	future_map.queue_free()
	for level_id in range(1, 51):
		game.get_node("Managers/LevelManager").load_level(level_id)
		game._begin_level("alone")
		check(game._current_level_id == level_id, "Every authored level must enter gameplay")
		game._finish_tutorial()
		await get_tree().process_frame
	game.queue_free()
	# Let outstanding story/audio timers retire before checking process shutdown.
	await get_tree().create_timer(2.3).timeout


func _check_phone_layouts() -> void:
	for dimensions in [Vector2i(720, 960), Vector2i(720, 1280), Vector2i(720, 1600)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		add_child(viewport)
		var board := Board.new()
		viewport.add_child(board)
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level001.json"))
		check(board.initialize(data), "Phone layout board must initialize")
		var first_cell := board.get_cell_screen_rect(Vector2i.ZERO)
		var last_cell := board.get_cell_screen_rect(Vector2i(7, 7))
		check(first_cell.position.y >= dimensions.y * 0.20, "Board must stay below the HUD")
		check(last_cell.end.y < dimensions.y * 0.80, "Board must stay above the booster tray")
		check(first_cell.position.x >= 0 and last_cell.end.x <= dimensions.x, "Board must fit phone width")
		var tutorial := TutorialOverlay.new()
		viewport.add_child(tutorial)
		tutorial.show_tip("That match used one move and refilled the board. MOVES shows 29 turns left; GOAL tracks 3 of 7 keys. Other symbols clear space but do not add key evidence.", Rect2(100, 40, 400, 160), "David", "res://assets/sprites/characters/david_portrait_v2.png", true)
		await get_tree().process_frame
		await get_tree().process_frame
		check(tutorial._bubble.get_global_rect().encloses(tutorial._acknowledge_button.get_global_rect()), "Tutorial continue button must fit inside its panel")
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(tutorial._bubble.get_global_rect()), "Tutorial panel must fit the phone viewport")
		viewport.queue_free()
		await get_tree().process_frame


func _check_special_combinations() -> void:
	var combinations := [["rocket", "rocket"], ["rocket", "bomb"], ["bomb", "bomb"], ["bomb", "thunder"], ["thunder", "thunder"]]
	for combination in combinations:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level001.json"))
		var board := Board.new()
		add_child(board)
		check(board.initialize(data), "Combination board must initialize")
		var first: Tile = board.get_tile(Vector2i(3, 3))
		var second: Tile = board.get_tile(Vector2i(4, 3))
		for index in range(2):
			var tile: Tile = first if index == 0 else second
			tile.set_powerup(Constants.PowerupType.get(str(combination[index]).to_upper()))
			tile.set_meta("powerup_kind", combination[index])
		var turns := [0]
		var clears: Array = []
		board.turn_resolved.connect(func(): turns[0] += 1)
		board.tiles_matched_with_cells.connect(func(_types: Array, cells: Array):
			if clears.is_empty(): clears.append(cells.duplicate())
		)
		check(board.swap_tiles(Vector2i(3, 3), Vector2i(4, 3)), "Adjacent special combination must be accepted")
		await get_tree().process_frame
		check(board.is_locked(), "Special turn must remain locked during animation")
		var deadline := Time.get_ticks_msec() + 15000
		while board.is_locked() and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		check(not board.is_locked(), "Special combination must finish")
		check(turns[0] == 1, "Special combination must emit exactly one completed turn")
		check(board.get_remaining_moves() == int(data["moves"]["total"]) - 1, "Combination must spend one move")
		check(board.is_stable(), "Combination must leave a stable board")
		if combination == ["bomb", "bomb"]:
			check(not clears.is_empty() and clears[0].size() == 25, "Two bombs must clear a 5 by 5 area")
		if combination == ["rocket", "bomb"]:
			check(not clears.is_empty() and clears[0].size() == 39, "Rocket and bomb must clear three rows and three columns")
		if combination == ["thunder", "thunder"]:
			check(not clears.is_empty() and clears[0].size() == 64, "Two thunder pieces must clear the whole board")
		board.queue_free()
		await get_tree().process_frame
