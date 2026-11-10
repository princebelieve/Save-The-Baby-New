extends Node

var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	var config := JsonLoader.load_file("res://configs/audio.json")
	var generated := 0
	for id in config.sfx:
		var path: String = config.sfx[id]
		if not path.contains("/actions/"): continue
		generated += 1
		var clip := ResourceManager.load_audio(path)
		check(clip is AudioStreamWAV, "action cue imports as WAV: " + id)
		if clip != null: check(clip.get_length() > 0.02 and clip.get_length() < 1, "action cue stays short: " + id)
	check(generated >= 34, "action mappings cover the complete palette")
	check(config.sfx.powerup_rocket.ends_with("/rocket_launch.wav"), "rocket uses launch sound")
	check(config.sfx.powerup_bomb.ends_with("/powerup_bomb.wav"), "bomb has its own impact")
	check(config.sfx.powerup_thunder != config.sfx.powerup_bomb, "bomb and Thunder are distinct")
	var game := preload("res://scenes/game/Game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._skip_opening_story()
	game.get_node("Managers/LevelManager").load_level(1)
	game._begin_level("alone")
	game._finish_tutorial()
	game._evidence_goal = 9999
	var board: Board = game._board
	var data := JsonLoader.load_file("res://levels/level001.json").duplicate(true)
	data.moves.total = 40
	data.obstacles = {"items": []}
	data.board = {"columns":5,"rows":5,"tile_size":64}
	data.tile_pool = {"tiles":["key","phone","recorder"],"weights":[1,1,1]}
	board.initialize(data)
	var events: Array[String] = []
	var capture := func(id): events.append(str(id))
	SignalBus.play_sfx.connect(capture)
	var audio: Node = game.get_node("Managers/AudioManager")
	audio.set_sfx_enabled(true)
	audio._stop_all_sfx()
	for attempt in 12: audio.play_sfx("powerup_bomb")
	check(audio._sfx_players.size() == 1, "rapid repeated bomb cues are limited to one instance")
	audio._stop_all_sfx()
	events.clear()
	check(board.use_booster_at("bomb", Vector2i(2,2)), "real tray bomb activates")
	var deadline := Time.get_ticks_msec() + 15000
	while board.is_locked() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	check(not board.is_locked(), "audio-enabled bomb turn settles")
	check(events.count("powerup_bomb") == 1, "one bomb emits one impact cue")
	check(events.find("tile_fall") >= 0 and events.find("tile_drop") > events.find("tile_fall"), "landing cue follows falling cue")
	check(not events.has("gunfire_burst") and not events.has("kung_fu_shout"), "puzzle actions do not emit unrelated combat sounds")
	events.clear()
	for cell in [Vector2i(1,1), Vector2i(2,1)]:
		board.remove_tile(cell)
		var rocket: Tile = board._tile_factory.create_tile_at(Constants.TileType.KEY, cell)
		rocket.set_powerup(Constants.PowerupType.ROCKET)
		rocket.set_meta("powerup_kind", "rocket")
		board.set_tile(cell, rocket, false)
	check(board.swap_tiles(Vector2i(1,1), Vector2i(2,1)), "real rocket combo activates")
	check(not events.is_empty() and events[0] == "tile_swap", "swap sound begins with movement")
	deadline = Time.get_ticks_msec() + 15000
	while board.is_locked() and Time.get_ticks_msec() < deadline: await get_tree().process_frame
	check(not board.is_locked() and events.count("rocket_combo") == 1, "rocket combo plays its own launch cue once")
	check(not events.has("gunfire_burst") and not events.has("kung_fu_shout"), "rocket combo has no gunfire or unrelated shout")
	SignalBus.play_sfx.disconnect(capture)
	game.queue_free()
	await get_tree().process_frame
	print("ACTION_AUDIO_CHECKS: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
