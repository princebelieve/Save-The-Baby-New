extends Node
const Tools = preload("res://scripts/game/PlayerTools.gd")
var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	var original := JsonLoader.load_file("res://levels/level001.json")
	var before := JSON.stringify(original)
	var fresh := ConfigFile.new()
	var beginner := Tools.apply(original, fresh)
	check(not beginner.powerups.enabled and beginner.settings.available_boosters.is_empty(), "new players retain gradual introduction")
	var progress := ConfigFile.new()
	progress.set_value("campaign", "completed_levels", {"24": 1})
	var replay := Tools.apply(original, progress)
	for kind in ["rocket", "bomb", "thunder", "ethan"]:
		check(replay.settings.available_boosters.has(kind), "replay retains learned tool: " + kind)
		check(bool(progress.get_value("tool_unlocks", kind, false)), "legacy progression migrates: " + kind)
	check(JSON.stringify(original) == before, "player unlock overlay never mutates authored level")
	check(replay.moves == original.moves and replay.objectives == original.objectives, "replay retains authored goals and move budget")
	var earned := ConfigFile.new()
	earned.set_value("tool_unlocks", "bomb", true)
	check(Tools.apply(original, earned).settings.available_boosters == ["bomb"], "earned tool unlocks independently of campaign level")
	for kind in ["rocket", "bomb", "thunder"]:
		var learned := ConfigFile.new()
		learned.set_value("academy_completed", kind, true)
		check(Tools.apply(original, learned).settings.available_boosters.has(kind), "completed lesson unlocks " + kind)
	var board := Board.new()
	add_child(board)
	check(board.initialize(replay), "early replay initializes with player rules")
	for size in [4, 5]:
		var match_group := Match.new()
		for x in size: match_group.add_tile(board.get_tile(Vector2i(x, 0)))
		var special := board.create_powerup_for_match([match_group])
		check(special != null and special.get_meta("powerup_kind") == ("rocket" if size == 4 else "thunder"), "replayed level one creates special for match size %d" % size)
		if special != null: special.clear_powerup()
	var horizontal := Match.new()
	var vertical := Match.new()
	for x in 3: horizontal.add_tile(board.get_tile(Vector2i(x, 1)))
	for y in 3: vertical.add_tile(board.get_tile(Vector2i(1, y)))
	var bomb := board.create_powerup_for_match([horizontal, vertical])
	check(bomb != null and bomb.get_meta("powerup_kind") == "bomb", "intersecting replay match earns bomb")
	board.queue_free()
	await get_tree().process_frame
	var game: Game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._start_opening_story()
	game._skip_opening_story()
	game._finish_tutorial()
	game._campaign_progress = ConfigFile.new()
	game._configure_player_tools()
	for kind in ["rocket", "bomb", "thunder"]:
		var count: int = game._economy_manager.get_booster_count(kind)
		game._economy_manager.set_booster_count(kind, count + 2)
		check(game._campaign_progress.get_value("tool_unlocks", kind, false), "earning stock unlocks tool immediately: " + kind)
	var stock: Dictionary = game._booster_inventory.duplicate()
	game.get_node("Managers/LevelManager").load_level(1)
	game._begin_level("alone")
	game._finish_tutorial()
	for kind in ["rocket", "bomb", "thunder"]:
		check(game._booster_buttons[kind].button.get_parent().visible, "replay tray shows learned tool: " + kind)
		check(game._economy_manager.get_booster_count(kind) == int(stock[kind]), "replay preserves inventory: " + kind)
	check(game._board._level_data.powerups.enabled, "live replay board enables special creation")
	for kind in ["rocket", "bomb", "thunder"]: game._economy_manager.set_booster_count(kind, 0)
	game.get_node("Managers/LevelManager").load_level(1)
	game._begin_level("alone")
	game._finish_tutorial()
	check(game._board._level_data.powerups.available.size() == 3, "using up inventory never removes learned special matches")
	var restored := ConfigFile.new()
	check(game._campaign_progress.save("user://replay-unlocks-check.cfg") == OK and restored.load("user://replay-unlocks-check.cfg") == OK, "unlock progress saves and reloads")
	check(Tools.apply(original, restored).settings.available_boosters.size() == 3, "learned tools survive returning session with empty inventory")
	game.queue_free()
	await get_tree().process_frame
	print("Replay tools checks: %d; failures: %d" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
