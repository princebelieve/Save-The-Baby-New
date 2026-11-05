extends Node

const SAMPLE_SEED := 20261104
var failures: Array[String] = []
var runs: Array[Dictionary] = []
var _selection := RandomNumberGenerator.new()
var _output := "res://.test-data/random-release-report.json"
var _focused := false
var _baseline := false
var _probe_continue := false
var _inventory_start := false
var _return_assist := false


func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	Engine.time_scale = 50.0
	_selection.seed = SAMPLE_SEED
	var sample: Array[int] = [51, 435, 1050]
	# Six random levels per difficulty, plus the first/last additions and IDE case.
	for difficulty in ["EASY", "MEDIUM", "HARD"]:
		var pool: Array[int] = []
		for level_id in range(51, 1051):
			var data := JsonLoader.load_file("res://levels/level%03d.json" % level_id)
			if str(data.difficulty) == difficulty and not sample.has(level_id):
				pool.append(level_id)
		for _index in 6:
			var chosen := _selection.randi_range(0, pool.size() - 1)
			sample.append(pool[chosen])
			pool.remove_at(chosen)
	sample.sort()
	for argument in OS.get_cmdline_user_args():
		if argument == "--inventory-start":
			_inventory_start = true
		if argument == "--return-assist":
			_return_assist = true
		if argument == "--baseline":
			_baseline = true
		if argument == "--probe-continue":
			_probe_continue = true
		if argument.begins_with("--levels="):
			sample.clear()
			for entry in argument.trim_prefix("--levels=").split(","):
				sample.append(int(entry))
			_focused = true
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
	print("RANDOM_RELEASE_SAMPLE: ", sample)
	for level_id in sample:
		for policy in ["evidence_first", "blockers_first", "varied_legal"]:
			await _play_level(level_id, policy)
		var won := false
		for run in runs:
			if int(run.level) == level_id and bool(run.won):
				won = true
		print("LEVEL_SAMPLE %d: %s" % [level_id, ("at least one win using a tray booster" if _inventory_start else "at least one free win") if won else "no win under the three tested policies"])
	var wins := 0
	var by_difficulty: Dictionary = {}
	for run in runs:
		if bool(run.won):
			wins += 1
		var group: Dictionary = by_difficulty.get(str(run.difficulty), {"runs": 0, "wins": 0})
		group.runs += 1
		group.wins += 1 if bool(run.won) else 0
		by_difficulty[str(run.difficulty)] = group
	var report := {
		"complete":true, "baseline":_baseline, "continuation_probe":_probe_continue,
		"sample_seed": SAMPLE_SEED, "sample_levels": sample, "runs": runs,
		"technical_failures": failures, "wins": wins, "attempts": runs.size(),
		"by_difficulty": by_difficulty, "time_scale": 50.0,
		"method": "Actual Board swaps, match collection, obstacle damage, refill, cascades and move budgets. Three deterministic policies per case; no purchased/tray boosters, extra moves or retries with altered level seeds. Bot losses do not prove impossibility and bot win rates are not human retention metrics."
	}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	file.close()
	print("RANDOM_RELEASE_CHECKS: %d technical failures; %d / %d wins" % [failures.size(), wins, runs.size()])
	get_tree().quit(0 if failures.is_empty() else 1)


func _play_level(level_id: int, policy: String) -> void:
	RandomGenerator.initialize(SAMPLE_SEED + level_id)
	var path := "res://.test-data/balance-baseline-levels/level%03d.json" % level_id if _baseline else "res://levels/level%03d.json" % level_id
	var data := JsonLoader.load_file(path)
	if _return_assist:
		var recovery = preload("res://scripts/game/LevelRecovery.gd")
		var progress := ConfigFile.new()
		var now := 1800000000
		for _failure in 3:
			recovery.record_result(progress,level_id,false,now-21601)
		recovery.begin_session(progress,now)
		data = recovery.preview(progress,data,now)
	var board := Board.new()
	add_child(board)
	if not board.initialize(data):
		check(false, "Level %d failed initialization" % level_id)
		board.queue_free()
		return
	var collected := [0]
	var resolved := [0]
	var clears := [0]
	var target := int(Constants.TileType.get(str(data.objectives[0].target)))
	var goal := int(data.objectives[0].amount)
	board.match_collected.connect(func(types: Array):
		for type in types:
			if int(type) == target:
				collected[0] += 1)
	board.turn_resolved.connect(func(): resolved[0] += 1)
	board.obstacles_cleared.connect(func(amount: int): clears[0] += amount)
	var turns := 0
	var rejection := false
	var maximum_turn_ms := 0
	var move_rng := RandomNumberGenerator.new()
	move_rng.seed = SAMPLE_SEED + level_id * 97
	var boosters_used := 0
	if _inventory_start:
		for obstacle in data.obstacles.items:
			if bool(obstacle.get("inventory_only",false)):
				var position := Vector2i(int(obstacle.x),int(obstacle.y))
				check(board.use_booster_at("rocket",position),"Tray booster starts the challenge: %d" % level_id)
				var deadline := Time.get_ticks_msec()+15000
				while board.is_locked() and Time.get_ticks_msec() < deadline:
					await get_tree().process_frame
				check(not board.is_locked(),"Tray booster resolves before ordinary play")
				turns += 1
				boosters_used += 1
				break
	while board.get_remaining_moves() > 0:
		var move := _choose_move(board, target, policy, move_rng, _focused and collected[0] >= goal)
		if move.size() != 2:
			check(false, "No legal move during level %d (%s), turn %d" % [level_id, policy, turns])
			break
		var previous_moves := board.get_remaining_moves()
		var started := Time.get_ticks_msec()
		if not board.swap_tiles(move[0], move[1]):
			rejection = true
			check(false, "Legal move rejected in level %d (%s)" % [level_id, policy])
			break
		while board.is_locked() and Time.get_ticks_msec() - started < 10000:
			await get_tree().process_frame
		maximum_turn_ms = maxi(maximum_turn_ms, Time.get_ticks_msec() - started)
		if board.is_locked():
			check(false, "Turn froze in level %d (%s)" % [level_id, policy])
			break
		turns += 1
		check(board.get_remaining_moves() == previous_moves - 1, "Exactly one move spent per turn: %d" % level_id)
		check(resolved[0] == turns, "Exactly one completion signal per turn: %d" % level_id)
		check(board.is_stable(), "Cascades settle: %d" % level_id)
		check(board.get_all_tiles().size() == board.get_width() * board.get_height() - board._blocked_cells.size(), "Every playable cell refills: %d" % level_id)
		if collected[0] >= goal and board._obstacles.is_empty():
			break
	var won: bool = collected[0] >= goal and board._obstacles.is_empty()
	var initial_collected: int = collected[0]
	var initial_blockers: int = board._obstacles.size()
	var continued_win := false
	if not won and _probe_continue:
		board.add_reward_moves(5)
		for _extra in 5:
			var extra_move := _choose_move(board,target,policy,move_rng,collected[0] >= goal)
			if extra_move.size() != 2 or not board.swap_tiles(extra_move[0],extra_move[1]):
				check(false,"Continuation accepts a legal move: %d" % level_id)
				break
			var deadline := Time.get_ticks_msec() + 10000
			while board.is_locked() and Time.get_ticks_msec() < deadline:
				await get_tree().process_frame
			check(not board.is_locked(),"Continuation settles: %d" % level_id)
			continued_win = collected[0] >= goal and board._obstacles.is_empty()
			if continued_win:
				break
	check(not won or turns > 1, "Non-tutorial case does not win itself immediately: %d" % level_id)
	runs.append({
		"level": level_id, "policy": policy, "difficulty": data.difficulty,
		"won": won, "turns": turns, "budget": int(data.moves.total),
		"collected": initial_collected, "goal": goal,
		"blockers_left": initial_blockers, "blockers_cleared": clears[0],
		"won_with_five_extra_moves":continued_win,
		"tray_boosters_used":boosters_used, "return_assistance":bool(data.settings.get("return_assistance",false)),
		"rejected_move": rejection, "maximum_turn_wall_ms": maximum_turn_ms
	})
	# Keep completed attempts if an external timeout interrupts a long batch.
	var checkpoint := FileAccess.open(_output,FileAccess.WRITE)
	checkpoint.store_string(JSON.stringify({"complete":false,"runs":runs,"technical_failures":failures},"  ") + "\n")
	checkpoint.close()
	board.queue_free()
	await get_tree().process_frame


func _choose_move(board: Board, target: int, policy: String, rng: RandomNumberGenerator, evidence_done: bool = false) -> Array[Vector2i]:
	var specials: Array[Array] = []
	var all_moves: Array[Array] = []
	for tile in board.get_all_tiles():
		var first: Vector2i = tile.get_grid_position()
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var second: Vector2i = first + offset
			var partner: Tile = board.get_tile(second)
			if partner == null or board.is_swap_blocked(first) or board.is_swap_blocked(second):
				continue
			# Specials activate on any free adjacent swap, even without a match.
			var activates_special: bool = tile.has_powerup() or partner.has_powerup()
			if activates_special or board._move_validator.is_valid_swipe(tile, partner):
				all_moves.append([first, second])
				if activates_special:
					specials.append([first, second])
	if not specials.is_empty():
		var selected: Array = specials[rng.randi_range(0, specials.size() - 1)]
		return [selected[0], selected[1]]
	var move: Array[Vector2i] = []
	if evidence_done and not board._obstacles.is_empty():
		move = board.find_valid_swap_near_obstacle()
	if policy == "blockers_first" and not board._obstacles.is_empty():
		move = board.find_valid_swap_near_obstacle()
	if move.is_empty() and policy != "varied_legal":
		move = board.find_valid_swap_for_type(target)
	if move.is_empty() and policy == "evidence_first":
		move = board.find_valid_swap_near_obstacle()
	if not move.is_empty():
		return move
	if all_moves.is_empty():
		return []
	var selected: Array = all_moves[rng.randi_range(0, all_moves.size() - 1)]
	return [selected[0], selected[1]]
