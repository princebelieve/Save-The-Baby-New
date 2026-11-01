extends Node

var reports: Array = []


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	Engine.time_scale = 35.0
	var first_turn_wins := 0
	for level_id in [1, 8, 16, 24, 32, 41, 50]:
		for seed_id in range(3):
			RandomGenerator.initialize(20261102 + level_id * 100 + seed_id)
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/level%03d.json" % level_id))
			var board := Board.new()
			add_child(board)
			if not board.initialize(data):
				get_tree().quit(1)
				return
			var count := [0]
			var target := int(Constants.TileType.get(data["objectives"][0]["target"]))
			board.match_collected.connect(func(types: Array):
				for type in types:
					if int(type) == target: count[0] += 1)
			var turns := 0
			while board.get_remaining_moves() > 0:
				var move: Array[Vector2i] = []
				var powerup := board.find_powerup_cell()
				if powerup.x >= 0:
					for neighbor in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
						if board.is_inside(powerup + neighbor):
							move = [powerup, powerup + neighbor]
							break
				if move.is_empty(): move = board.find_valid_swap_for_type(target)
				if move.is_empty(): move = board.find_valid_swap_near_obstacle()
				if move.is_empty(): move = board.find_valid_swap()
				if move.size() != 2: break
				if not board.swap_tiles(move[0], move[1]): break
				var deadline := Time.get_ticks_msec() + 10000
				while board.is_locked() and Time.get_ticks_msec() < deadline:
					await get_tree().process_frame
				if board.is_locked():
					push_error("Balance run did not settle")
					get_tree().quit(1)
					return
				turns += 1
				if count[0] >= int(data["objectives"][0]["amount"]) and board._obstacles.is_empty():
					break
			var won: bool = count[0] >= int(data["objectives"][0]["amount"]) and board._obstacles.is_empty()
			if won and turns <= 1: first_turn_wins += 1
			reports.append({"level": level_id, "seed": seed_id, "won": won, "turns": turns, "collected": count[0], "goal": data["objectives"][0]["amount"], "blockers_left": board._obstacles.size()})
			board.queue_free()
			await get_tree().process_frame
	var file := FileAccess.open("res://.test-data/academy-balance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"runs": reports, "first_turn_wins": first_turn_wins, "policy": "Goal-first legal moves, activate available specials, no tray boosters. Diagnostic sample, not human difficulty certification."}, "  "))
	print("ACADEMY_BALANCE: ", reports.size(), " runs; ", first_turn_wins, " first-turn wins")
	get_tree().quit(0 if first_turn_wins == 0 else 1)
