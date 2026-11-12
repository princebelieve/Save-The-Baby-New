extends "res://tests/marketing_capture.gd"

func run() -> void:
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await hold(2.3)
	clear_layer("_launch_layer")
	# Use a contiguous demonstration campaign so the receipt correctly opens 9.
	for id in range(1,8): game._completed_levels[str(id)] = 3
	game._highest_unlocked_level = 8
	game._campaign_progress.set_value("campaign","completed_levels",game._completed_levels)
	for kind in ["rocket","bomb","thunder"]:
		game._campaign_progress.set_value("tool_unlocks",kind,true)
	await enter_level(8)
	game._board._remaining_moves = 5
	game._on_moves_changed(5)
	for index in 3:
		var tile: Tile = game._board.get_tile(Vector2i(index,0))
		tile.set_powerup([Constants.PowerupType.ROCKET,Constants.PowerupType.BOMB,Constants.PowerupType.THUNDER][index])
		tile.set_meta("powerup_kind",["rocket","bomb","thunder"][index])
	game._board.lock()
	begin_segment()
	game.victory_bonus_step.connect(func(kind,_points):
		if kind != "move": capture.call_deferred("14-victory-"+kind,"Make every move count"))
	await game._show_level_result(true)
	end_segment("victory-bonus","Make every move count")
	await hold(0.7)
	begin_segment()
	await capture("15-victory","Celebrate the rescue")
	await hold(3.0)
	end_segment("victory","Celebrate every victory")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output+"/capture-manifest.json"))
	for scene in scenes:
		scene.source = "raw/victory.avi"
		for index in manifest.segments.size():
			if manifest.segments[index].name == scene.name: manifest.segments[index] = scene
	for shot in shots:
		for index in manifest.shots.size():
			if manifest.shots[index].name == shot.name: manifest.shots[index] = shot
	manifest.capture_pixel_size = [1080,1920]
	var file := FileAccess.open(output+"/capture-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "))
	file.close()
	print("VICTORY CAPTURE COMPLETE: campaign continuity verified")
	get_tree().quit()
