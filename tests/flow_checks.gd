extends Node
var failures := 0
func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var data := JsonLoader.load_file("res://levels/level051.json").duplicate(true)
	data.board.columns = 5
	data.board.rows = 5
	data.board.blocked_cells = []
	data.obstacles.items = []
	for x in 5: data.obstacles.items.append({"type":"chain", "x":x,"y":2,"health":2})
	var board := Board.new()
	add_child(board)
	check(board.initialize(data), "flow fixture initializes")
	var captive: Tile = board.get_tile(Vector2i(2,2))
	for y in range(3,5):
		for x in 5: board.remove_tile(Vector2i(x,y))
	board._gravity_solver.apply_gravity(board)
	board._refill_system.refill(board)
	check(board.get_tile(Vector2i(2,2)) == captive, "captive tile remains fixed")
	check(board.get_tile(Vector2i(2,4)) == null, "sealed pocket cannot refill through blockers")
	var obstacle: Obstacle = board._obstacles[Vector2i(2,2)]
	obstacle.damage(1)
	check(not obstacle.is_destroyed(), "two-hit blocker survives first hit")
	board._obstacles.erase(Vector2i(2,2))
	obstacle.queue_free()
	board._gravity_solver.apply_gravity(board)
	board._refill_system.refill(board)
	check(board.get_tile(Vector2i(2,4)) != null, "opening barrier restores supply")
	check(board.get_tile(Vector2i(1,4)) != null, "tiles flow diagonally into reachable pocket")
	board.queue_free()
	await get_tree().process_frame
	data.obstacles.items = [{"type":"missile", "x":2,"y":2,"health":2}, {"type":"tape", "x":1,"y":2,"health":1}]
	board = Board.new()
	add_child(board)
	check(board.initialize(data), "solid/coating fixture initializes")
	check(board.get_tile(Vector2i(2,2)) == null and not board.is_flow_cell(Vector2i(2,2)), "solid hazard occupies its cell without a hidden tile")
	check(board.get_tile(Vector2i(1,2)) != null and board.is_flow_cell(Vector2i(1,2)), "tape coating permits tile flow")
	board._refill_system.refill(board)
	check(board.get_tile(Vector2i(2,2)) == null, "refill never spawns inside a solid hazard")
	board.queue_free()
	await get_tree().process_frame
	data.obstacles.items = []
	board = Board.new()
	add_child(board)
	check(board.initialize(data), "empty refill fixture initializes")
	for tile in board.get_all_tiles(): board.remove_tile(tile.get_grid_position())
	board._refill_system.refill(board)
	check(board.get_all_tiles().size() == 25, "open empty board refills from supply")
	check(not board.get_match_finder().has_matches(board), "new tiles avoid accidental matches at their final cells")
	board.queue_free()
	await get_tree().process_frame
	print("FLOW_CHECKS: %d failures" % failures)
	get_tree().quit(0 if failures == 0 else 1)
