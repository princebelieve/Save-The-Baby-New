extends Node

const Recovery = preload("res://scripts/game/LevelRecovery.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.get_user_data_dir().replace("\\","/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 30
	_check_recovery()
	for id in range(100,1051,50):
		var data := JsonLoader.load_file("res://levels/level%03d.json" % id)
		check(bool(data.obstacles.items[0].get("inventory_only",false)),"Authored challenge %d requires an inventory booster" % id)
		check(str(data.difficulty) == "CRITICAL_CASE","Challenge uses the investigation's own Critical Case label")
	for kind in ["rocket","bomb","thunder"]:
		await _check_seal(kind)
	await _check_game()
	print("DIFFICULTY_CHECKS: %d checks; %d failures" % [checks,failures.size()])
	var report := FileAccess.open("res://.test-data/difficulty-checks.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	report.close()
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_recovery() -> void:
	var progress := ConfigFile.new()
	var data := JsonLoader.load_file("res://levels/level105.json")
	var original := JSON.stringify(data)
	var last := 1800000000
	Recovery.begin_session(progress,last)
	for index in 3:
		Recovery.record_result(progress,105,false,last+index)
	Recovery.begin_session(progress,last+21601)
	check(not Recovery.eligible(progress,data,last+21601),"Six hours means six hours since the last activity, not since the first failure")
	var now := last+43203
	Recovery.begin_session(progress,now)
	check(Recovery.eligible(progress,data,now),"A genuinely absent returning player with three failures qualifies")
	var variant := Recovery.preview(progress,data,now)
	check(int(variant.moves.total) == int(data.moves.total)+4,"Return assistance grants four moves")
	check(int(variant.metadata.seed) != int(data.metadata.seed),"Return assistance refreshes the initial spawn sequence")
	var index: int = data.tile_pool.tiles.find(str(data.objectives[0].target).to_lower())
	check(float(variant.tile_pool.weights[index]) > float(data.tile_pool.weights[index]),"Return assistance increases mission-evidence spawn weight")
	check(float(variant.settings.lucky_refill_chance) == 0.20,"Return assistance permits bounded lucky refill cascades")
	check(JSON.stringify(data) == original,"Authored level definition remains unchanged")
	check(JSON.stringify(Recovery.preview(progress,data,now+1)) == JSON.stringify(variant),"Reopening a briefing cannot reroll the return layout")
	check(CampaignProgressStore.write(progress,"user://return_fixture.cfg") == OK,"Return eligibility persists")
	var restored := ConfigFile.new()
	check(CampaignProgressStore.read(restored,"user://return_fixture.cfg") == OK,"Restart restores return eligibility")
	check(Recovery.eligible(restored,data,now+1),"Restart does not lose a pending return bonus")
	Recovery.start_attempt(restored,variant,now+2)
	check(not Recovery.eligible(restored,data,now+3),"Starting consumes the bonus once")
	Recovery.record_result(restored,105,false,now+4)
	Recovery.begin_session(restored,now+43200)
	check(not Recovery.eligible(restored,data,now+43200),"The same case cannot repeatedly claim return assistance")
	check(not Recovery.eligible(progress,data,last),"Clock rollback cannot claim an assistance window")
	var fresh := ConfigFile.new()
	Recovery.begin_session(fresh,last)
	for _attempt in 2:
		Recovery.record_result(fresh,105,false,last)
	Recovery.begin_session(fresh,last+21601)
	check(not Recovery.eligible(fresh,data,last+21601),"Two failures do not trigger the three-failure bonus")
	check(not Recovery.eligible(progress,JsonLoader.load_file("res://levels/level051.json"),now),"Easy recovery cases are not silently retuned")
	var completed := ConfigFile.new()
	for id in range(1,1051):
		Recovery.record_result(completed,id,true,now)
	check((completed.get_value("recovery","cases",{}) as Dictionary).is_empty(),"Completed cases without assistance do not grow the cloud save with redundant history")
	Recovery.record_result(restored,105,true,now+43201)
	check(bool(restored.get_value("recovery","cases",{}).get("105",{}).get("assistance_used",false)),"Completing an assisted case retains its one-time claim marker")

func _check_seal(kind: String) -> void:
	var data := JsonLoader.load_file("res://levels/level100.json")
	var seal: Dictionary = data.obstacles.items[0]
	var cell := Vector2i(int(seal.x),int(seal.y))
	var board := Board.new()
	add_child(board)
	check(board.initialize(data),"Challenge board initializes for " + kind)
	var obstacle: Obstacle = board._obstacles[cell]
	for _hit in 20:
		board._damage_nearby_obstacles(board.get_all_tiles())
	check(board._obstacles.has(cell) and obstacle.get_obstacle_state().get_health() == 1,"Ordinary matches cannot open the inventory seal")
	await board._resolve_external_clear(board.get_all_tiles(),"rocket",true,[],false)
	check(board._obstacles.has(cell),"Board-created special blasts and their cascades cannot open the inventory seal")
	check(board.use_booster_at("ethan",cell),"Ethan assist remains usable")
	await _settle(board)
	check(board._obstacles.has(cell),"A freely matched character assist does not bypass the tray requirement")
	check(board.use_booster_at(kind,cell),"Inventory " + kind + " can target the marked seal")
	await _settle(board)
	check(not board._obstacles.has(cell),"Inventory " + kind + " opens the marked seal")
	board.queue_free()
	await get_tree().process_frame

func _settle(board: Board) -> void:
	var deadline := Time.get_ticks_msec()+15000
	while board.is_locked() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(not board.is_locked(),"Booster resolution settles")

func _check_game() -> void:
	Engine.time_scale = 1.0
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await get_tree().create_timer(2.0).timeout
	Engine.time_scale = 30
	game._highest_unlocked_level = 1050
	for kind in ["rocket","bomb","thunder"]:
		game._economy_manager.set_booster_count(kind,0)
	game._on_campaign_level_selected(100,"alone")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.6,true,false,true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.test-data/critical-case-briefing.png")
	var lives: int = game._economy_manager.get_lives()
	game._begin_level("alone")
	check(game._briefing_layer == null and game._economy_manager.get_lives() == lives,"The recommendation does not block Play or charge a life merely for starting")
	for dialog in game.find_children("*","AcceptDialog",true,false):
		dialog.hide()
		dialog.queue_free()
	if game._pause_layer != null:
		game._close_pause_menu()
	get_tree().paused = false
	var data: Dictionary = game.get_node("Managers/LevelManager").get_level_data()
	game._campaign_progress.set_value("scout_supplies","100",false)
	check(game._claim_scout_supply(data),"An occasional matching scout supply can be claimed")
	check(not game._claim_scout_supply(data),"Reopening cannot claim the same supply twice")
	check(game._economy_manager.get_booster_count("rocket") == 1,"The recommended supply is placed in the real inventory")
	var seal: Dictionary = game.get_node("Managers/LevelManager").get_level_data().obstacles.items[0]
	var cell := Vector2i(int(seal.x),int(seal.y))
	check(game._board.use_booster_at("rocket",cell),"Real game can fire the owned tray booster")
	await _settle(game._board)
	check(game._economy_manager.get_booster_count("rocket") == 0,"Real game consumes exactly one inventory booster")
	check(not game._board._obstacles.has(cell),"Real game opens the seal after consuming the booster")
	Engine.time_scale = 1.0
	await get_tree().create_timer(1.0).timeout
	game.queue_free()
	await get_tree().process_frame
