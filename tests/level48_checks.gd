extends Node

class FastBoard extends Board:
	# Skip presentation delays; retain production swap, blast, collection,
	# blocker damage, cascade, gravity and refill logic.
	func animate_match_tiles(_tiles: Array, _emit_bursts: bool = true) -> void: pass
	func animate_falling_tiles(_movements: Array) -> void: pass

var failures: Array[String] = []
var checks := 0
var reports: Array = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	Engine.time_scale = 60
	call_deferred("_run")

func settled(board: Board) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while board.is_locked() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not board.is_locked(), "turn settles")

func fixture() -> Board:
	var data := JsonLoader.load_file("res://levels/level001.json").duplicate(true)
	data.board = {"columns":5, "rows":5, "tile_size":64}
	data.obstacles = {"items":[]}
	data.tile_pool = {"tiles":["key","phone","recorder"], "weights":[1,1,1]}
	data.moves.total = 40
	data.powerups = {"enabled":true, "available":["ROCKET","BOMB","THUNDER"]}
	var board := FastBoard.new()
	add_child(board)
	board.initialize(data)
	for y in 5:
		for x in 5:
			put(board, Vector2i(x,y), [0,1,3][(x+y*2)%3])
	return board

func put(board: Board, cell: Vector2i, type: int) -> Tile:
	board.remove_tile(cell)
	var tile := board._tile_factory.create_tile_at(type, cell)
	board.set_tile(cell, tile, false)
	return tile

func _run() -> void:
	await _rocket_counts()
	await _move_inputs()
	await _hud_counts()
	await _level48_survey()
	check(reports.any(func(run): return run.won), "level 48 is winnable without inventory boosters")
	var file := FileAccess.open("res://.test-data/level48-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"runs":reports}, "  "))
	print("LEVEL48_CHECKS: %d checks; %d failures; %d/%d unaided wins" % [checks, failures.size(), reports.filter(func(run): return run.won).size(), reports.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _rocket_counts() -> void:
	var board := fixture()
	for x in 5: put(board, Vector2i(x,2), Constants.TileType.CLOCK)
	for y in 5: put(board, Vector2i(2,y), Constants.TileType.CLOCK)
	var rocket := put(board, Vector2i(1,2), Constants.TileType.KEY)
	rocket.set_powerup(Constants.PowerupType.ROCKET)
	rocket.set_meta("powerup_kind", "rocket")
	var collected := [0]
	var first_batch: Array = []
	board.match_collected.connect(func(types: Array):
		if first_batch.is_empty(): first_batch.append(types.duplicate())
		for type in types:
			if int(type) == Constants.TileType.CLOCK: collected[0] += 1
	)
	check(board._move_validator.is_valid_swipe(rocket,board.get_tile(Vector2i(2,2))), "validator agrees that rocket swaps are legal")
	check(board.swap_tiles(Vector2i(1,2),Vector2i(2,2)), "rocket swaps with ordinary tile without requiring a match")
	await settled(board)
	check(collected[0] == 8, "rocket collects all eight timestamps in its cross, not one")
	check(first_batch[0].count(Constants.TileType.CLOCK) == 8, "collection signal contains every affected objective tile")
	board.queue_free()
	await get_tree().process_frame

func _move_inputs() -> void:
	var board := fixture()
	# Row 2 becomes three clocks when (1,1) moves down one cell.
	put(board,Vector2i(0,2),Constants.TileType.CLOCK)
	put(board,Vector2i(2,2),Constants.TileType.CLOCK)
	put(board,Vector2i(1,1),Constants.TileType.CLOCK)
	check(board._move_validator.is_valid_swipe(board.get_tile(Vector2i(1,1)),board.get_tile(Vector2i(1,2))), "known adjacent clock match is legal")
	var tile: Tile = board.get_tile(Vector2i(1,1))
	tile.position += Vector2(7,0)
	var before := tile.position
	board._move_validator.is_valid_swipe(tile,board.get_tile(Vector2i(1,2)))
	check(tile.position == before, "move searches do not move live sprites")
	board._set_tile_visual_position(tile, tile.get_grid_position())
	var moves := board.get_remaining_moves()
	board._drag_start = board.get_tile(Vector2i(1,1))
	board._finish_swipe(board.get_tile(Vector2i(1,4)),Vector2(0,board.get_tile_size()*3))
	await settled(board)
	check(board.get_remaining_moves() == moves - 1, "long phone swipe performs one adjacent move instead of being rejected")
	board.queue_free()
	await get_tree().process_frame
	board = FastBoard.new()
	add_child(board)
	board.initialize(JsonLoader.load_file("res://levels/level048.json"))
	var cell := Vector2i(2,2)
	var replacement := put(board,cell,Constants.TileType.CLOCK)
	check(board._obstacles[cell].z_index > replacement.z_index, "refill cannot cover an existing blocker")
	check(not board.swap_tiles(cell, cell + Vector2i.UP), "blocker prevents swapping until cleared")
	check(board.get_move_rejection_reason() == "blocked", "blocked cells report the correct rejection reason")
	board.queue_free()
	await get_tree().process_frame

func _hud_counts() -> void:
	var game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game._skip_opening_story()
	game.get_node("Managers/LevelManager").load_level(48)
	game._begin_level("alone")
	game._finish_tutorial()
	for id in range(40, 51):
		game.get_node("Managers/LevelManager").load_level(id)
		game._begin_level("alone")
		game._finish_tutorial()
		for frame in 8: await get_tree().process_frame
		check(game._mission_panel.get_global_rect().encloses(game._objective_label.get_global_rect()), "level %d objective counts fit header: %s within %s" % [id, game._objective_label.get_global_rect(), game._mission_panel.get_global_rect()])
	for id in [51, 100, 511, 1050]:
		game.get_node("Managers/LevelManager").load_level(id)
		game._show_level_briefing("alone")
		for frame in 8: await get_tree().process_frame
		var play: Button
		for button in game._briefing_layer.find_children("*", "Button", true, false):
			if button.text == "PLAY": play = button
		check(play != null, "level %d has Play" % id)
		if play != null:
			check(game.get_viewport_rect().encloses(play.get_global_rect()), "level %d Play fits viewport" % id)
			check(not play.get_parent() is ScrollContainer and play.get_parent().get_parent().name == "MissionCard", "Play stays outside briefing scroll")
		game._briefing_layer.queue_free()
		game._briefing_layer = null
	game.get_node("Managers/LevelManager").load_level(48)
	game._begin_level("alone")
	game._finish_tutorial()
	for clock_count in [8, 1]:
		var board: Board = game._board
		board.clear()
		var data := JsonLoader.load_file("res://levels/level001.json").duplicate(true)
		data.board = {"columns":5,"rows":5,"tile_size":64}
		data.obstacles = {"items":[]}
		data.tile_pool = {"tiles":["key","phone","recorder"],"weights":[1,1,1]}
		data.moves.total = 40
		board.initialize(data)
		for y in 5:
			for x in 5: put(board,Vector2i(x,y),[0,1,3][(x+y*2)%3])
		var positions := [Vector2i(2,2),Vector2i(0,2),Vector2i(3,2),Vector2i(4,2),Vector2i(2,0),Vector2i(2,1),Vector2i(2,3),Vector2i(2,4)]
		for index in clock_count: put(board, positions[index], Constants.TileType.CLOCK)
		var rocket := put(board,Vector2i(1,2),Constants.TileType.KEY)
		rocket.set_powerup(Constants.PowerupType.ROCKET)
		rocket.set_meta("powerup_kind","rocket")
		game._objective_type = "COLLECT_ITEMS"
		game._objective_target = "CLOCK"
		game._evidence_goal = 30
		game._evidence_count = 0
		game._idle_hint_timer.stop()
		check(board.swap_tiles(Vector2i(1,2),Vector2i(2,2)), "real game accepts rocket swap")
		await settled(board)
		check(game._evidence_count == clock_count, "HUD counts exactly %d timestamps in rocket cross" % clock_count)
		check(game._objective_label.text.begins_with("%d / 30" % clock_count), "HUD text matches collection count")
		check(not game._hint_label.visible, "feedback does not spill into the board header")
	game.queue_free()
	await get_tree().process_frame

func choose(board: Board, collected: int) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var best_score := -1.0
	for y in board.get_height():
		for x in board.get_width():
			var a := Vector2i(x,y)
			if board.is_swap_blocked(a): continue
			for delta in [Vector2i.RIGHT, Vector2i.DOWN]:
				var b: Vector2i = a + delta
				if not board.is_inside(b) or board.is_swap_blocked(b): continue
				var first: Tile = board.get_tile(a)
				var second: Tile = board.get_tile(b)
				var special: Tile = first if first.has_powerup() else (second if second.has_powerup() else null)
				if special == null and not board._move_validator.is_valid_swipe(first,second): continue
				board._grid[a] = second
				board._grid[b] = first
				first.set_grid_position(b)
				second.set_grid_position(a)
				var tiles: Array = []
				var score := 0.0
				if special != null:
					var partner: Tile = second if special == first else first
					tiles = board._special_targets(str(special.get_meta("powerup_kind","rocket")),special.get_grid_position(),int(partner.get_tile_type()))
					if not tiles.has(partner): tiles.append(partner)
				else:
					for found in board.get_match_finder().find_all_matches(board):
						if found.size() >= 4: score += 7
						for tile in found.get_tiles():
							if not tiles.has(tile): tiles.append(tile)
				for tile in tiles:
					if int(tile.get_tile_type()) == Constants.TileType.CLOCK and collected < 30: score += 3
				for cell in board._obstacles:
					for tile in tiles:
						var offset: Vector2i = tile.get_grid_position() - cell
						if absi(offset.x)+absi(offset.y) <= 1:
							score += 6 if board._obstacles[cell].get_obstacle_state().get_health() == 1 else 3
							break
				score += tiles.size() * 0.05
				board._grid[a] = first
				board._grid[b] = second
				first.set_grid_position(a)
				second.set_grid_position(b)
				if score > best_score:
					best_score = score
					best = [a,b]
	return best

func _level48_survey() -> void:
	for seed_id in 12:
		RandomGenerator.initialize(48000 + seed_id)
		var data := JsonLoader.load_file("res://levels/level048.json").duplicate(true)
		data.metadata.seed = 48000 + seed_id
		var board := FastBoard.new()
		add_child(board)
		check(board.initialize(data), "level 48 initializes")
		var count := [0]
		board.match_collected.connect(func(types: Array):
			for type in types:
				if int(type) == Constants.TileType.CLOCK: count[0] += 1)
		var trace: Array = []
		while board.get_remaining_moves() > 0 and (count[0] < 30 or not board._obstacles.is_empty()):
			var move := choose(board,count[0])
			if move.size() != 2: break
			if not board.swap_tiles(move[0],move[1]):
				check(false,"a solver-verified legal move was rejected")
				break
			trace.append([[move[0].x,move[0].y],[move[1].x,move[1].y]])
			await settled(board)
		var won: bool = count[0] >= 30 and board._obstacles.is_empty()
		reports.append({"seed":48000+seed_id,"won":won,"collected":count[0],"blockers_left":board._obstacles.size(),"turns":trace.size(),"moves":trace})
		board.queue_free()
		await get_tree().process_frame
