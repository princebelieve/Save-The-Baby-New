extends Node

class FastBoard extends Board:
	func animate_match_tiles(_tiles: Array, _emit_bursts: bool = true) -> void: pass
	func animate_falling_tiles(_movements: Array) -> void: pass

class CascadeRefill extends RefillSystem:
	var waves := 0
	func refill(board, animate: bool = false) -> Array:
		var movements := super.refill(board, animate)
		if waves < 2:
			for x in 3:
				board.remove_tile(Vector2i(x,0))
				board.set_tile(Vector2i(x,0), board._tile_factory.create_tile_at(Constants.TileType.CLOCK, Vector2i(x,0)), false)
		waves += 1
		return movements

var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func put(board: Board, cell: Vector2i, kind: int) -> Tile:
	board.remove_tile(cell)
	var tile := board._tile_factory.create_tile_at(kind, cell)
	board.set_tile(cell, tile, false)
	return tile

func fixture(level_id := 1, with_blocker := false) -> Board:
	var data := JsonLoader.load_file("res://levels/level024.json").duplicate(true)
	data.level_id = level_id
	data.board = {"columns": 6, "rows": 6, "tile_size": 64}
	data.moves.total = 40
	data.obstacles = {"items": []}
	if with_blocker: data.obstacles.items = [{"x":0, "y":5, "type":"chain", "health":2}]
	data.tile_pool = {"tiles": ["key", "phone", "recorder", "ethan", "victor"], "weights": [1, 1, 1, 100, 100]}
	data.powerups = {"enabled": true, "available": ["ROCKET", "BOMB", "THUNDER"]}
	var board := FastBoard.new()
	add_child(board)
	check(board.initialize(data), "board initializes")
	for tile in board.get_all_tiles():
		check(int(tile.get_tile_type()) not in [Constants.TileType.ETHAN, Constants.TileType.VICTOR], "characters never spawn from weighted pool")
	for y in 6:
		for x in 6: put(board, Vector2i(x,y), [0,1,3][(x+2*y)%3])
	return board

func settle(board: Board) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while board.is_locked() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	check(not board.is_locked(), "turn settles")

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	Engine.time_scale = 40
	call_deferred("run")

func run() -> void:
	for kind in ["rocket", "bomb", "thunder", "ethan", "hammer"]:
		var tray_board := fixture()
		var moves_before := tray_board.get_remaining_moves()
		check(not tray_board.use_booster_at(kind, Vector2i(-1,-1)), "invalid tray target is rejected")
		check(tray_board.get_remaining_moves() == moves_before, "rejected booster leaves moves unchanged")
		check(tray_board.use_booster_at(kind, Vector2i(2,2)), "tray booster activates: " + kind)
		await settle(tray_board)
		check(tray_board.get_remaining_moves() == moves_before, "tray booster and its cascades preserve every move: " + kind)
		tray_board.queue_free()
		await get_tree().process_frame
	# The partner completes a vertical match OFF the rocket's column after swapping.
	for reversed_swap in [false, true]:
		var board := fixture()
		var rocket := put(board, Vector2i(1,1), Constants.TileType.PHONE)
		rocket.set_powerup(Constants.PowerupType.ROCKET)
		rocket.set_meta("powerup_kind", "rocket")
		for cell in [Vector2i(2,1), Vector2i(1,0), Vector2i(1,2)]: put(board, cell, Constants.TileType.CLOCK)
		var batches: Array = []
		board.match_collected.connect(func(types): batches.append(types.duplicate()))
		check(board.swap_tiles(Vector2i(2,1) if reversed_swap else Vector2i(1,1), Vector2i(1,1) if reversed_swap else Vector2i(2,1)), "rocket swap accepted in both directions")
		await settle(board)
		check(not batches.is_empty() and batches[0].count(Constants.TileType.CLOCK) == 3, "rocket and immediate three-match count every objective exactly once")
		board.queue_free()
		await get_tree().process_frame
	var combo_board := fixture()
	var combo_rocket := put(combo_board, Vector2i(1,2), Constants.TileType.PHONE)
	combo_rocket.set_powerup(Constants.PowerupType.ROCKET)
	combo_rocket.set_meta("powerup_kind", "rocket")
	for cell in [Vector2i(2,2), Vector2i(1,0), Vector2i(1,1), Vector2i(1,3), Vector2i(1,4)]: put(combo_board, cell, Constants.TileType.CLOCK)
	var combo_batches: Array = []
	combo_board.match_collected.connect(func(types): combo_batches.append(types.duplicate()))
	check(combo_board.swap_tiles(Vector2i(1,2), Vector2i(2,2)), "rocket plus five-match swap accepted")
	await settle(combo_board)
	check(combo_batches[0].count(Constants.TileType.CLOCK) == 5, "overlapping rocket and five-match objectives are counted once")
	check(combo_board.get_all_tiles().any(func(tile): return str(tile.get_meta("powerup_kind", "")) == "thunder"), "five-match made during a booster swap retains its thunder reward")
	combo_board.queue_free()
	await get_tree().process_frame
	var board := fixture()
	for x in 5: put(board, Vector2i(x,0), Constants.TileType.CLOCK)
	var counts := [0]
	board.match_collected.connect(func(types): counts[0] += types.count(Constants.TileType.CLOCK))
	await board._cascade_processor.process_animated(board)
	var thunder: Tile
	for tile in board.get_all_tiles():
		if str(tile.get_meta("powerup_kind", "")) == "thunder": thunder = tile
	check(thunder != null, "five in a line leaves a usable thunder reward")
	check(counts[0] == 5, "five-match collects all five objectives")
	if thunder != null:
		var before: int = counts[0]
		await board._resolve_external_clear([thunder], "hammer")
		check(counts[0] == before, "retained thunder does not count its original objective twice")
	board.queue_free()
	await get_tree().process_frame
	board = fixture()
	put(board, Vector2i(0,0), Constants.TileType.CLOCK)
	put(board, Vector2i(1,0), Constants.TileType.ETHAN)
	put(board, Vector2i(2,0), Constants.TileType.CLOCK)
	counts[0] = 0
	board.match_collected.connect(func(types): counts[0] += types.count(Constants.TileType.CLOCK))
	await board._cascade_processor.process_animated(board)
	check(counts[0] == 3, "Ethan plus two clues automatically matches and credits all three")
	put(board, Vector2i(0,0), Constants.TileType.CLOCK)
	put(board, Vector2i(1,0), Constants.TileType.CLOCK)
	put(board, Vector2i(2,1), Constants.TileType.ETHAN)
	check(board._move_validator.would_create_match(board, board.get_tile(Vector2i(2,1)), board.get_tile(Vector2i(2,0))), "move validator accepts a wildcard-completed match")
	board.queue_free()
	await get_tree().process_frame
	board = fixture(24)
	var refill := CascadeRefill.new()
	refill.initialize(board._board_generator)
	board.add_child(refill)
	board._cascade_processor._refill_system = refill
	for x in 3: put(board, Vector2i(x,0), Constants.TileType.CLOCK)
	var earned: Array = []
	board.character_arrived.connect(func(kind): earned.append(kind))
	await board._cascade_processor.process_animated(board)
	check(board._match_waves >= 3, "three real cascade waves are recorded")
	await board._finish_character_turn()
	check(earned.count("ethan") == 1, "a real three-wave cascade earns exactly one Ethan")
	board.queue_free()
	await get_tree().process_frame
	board = fixture(24, true)
	board._match_waves = 2
	await board._finish_character_turn()
	check(not board.get_all_tiles().any(func(tile): return int(tile.get_tile_type()) == Constants.TileType.ETHAN), "two waves do not earn Ethan")
	var arrivals: Array = []
	board.character_arrived.connect(func(kind): arrivals.append(kind))
	board._match_waves = 3
	await board._finish_character_turn()
	check(arrivals.count("ethan") == 1, "three waves earn one Ethan")
	board._match_waves = 0
	board._remaining_moves = 11
	await board._finish_character_turn()
	check(arrivals.count("victor") == 0, "Victor does not appear before 75 percent of moves used")
	board._remaining_moves = 10
	await board._finish_character_turn()
	check(arrivals.count("victor") == 1, "Victor appears at the configured threshold")
	var victor: Tile
	for tile in board.get_all_tiles():
		if int(tile.get_tile_type()) == Constants.TileType.VICTOR: victor = tile
	var old_tiles := board.get_all_tiles().duplicate()
	var blocker_cells := board._obstacles.keys()
	var blocker_health: Array = []
	for cell in blocker_cells: blocker_health.append(board._obstacles[cell].get_obstacle_state().get_health())
	var collections := [0]
	board.match_collected.connect(func(types): collections[0] += types.size())
	if victor != null:
		var cell := victor.get_grid_position()
		var neighbor := cell + (Vector2i.RIGHT if cell.x < 5 else Vector2i.LEFT)
		check(board.swap_tiles(cell, neighbor), "Victor can swap without making a match")
		await settle(board)
		check(collections[0] == 0, "Victor refresh grants no objective or character rewards")
		check(not board.get_all_tiles().any(func(tile): return old_tiles.has(tile)), "Victor replaces every board tile")
		check(board.get_remaining_moves() == 9, "Victor costs exactly one move")
		check(board._obstacles.keys() == blocker_cells, "Victor leaves every blocker in place")
		for index in blocker_cells.size(): check(board._obstacles[blocker_cells[index]].get_obstacle_state().get_health() == blocker_health[index], "Victor does not damage blockers")
		await board._finish_character_turn()
		check(arrivals.count("victor") == 1, "Victor cannot reappear in the same attempt")
	board.queue_free()
	print("CHARACTER_BOOSTER_CHECKS: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
