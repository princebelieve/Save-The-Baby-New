extends Node

const Tools = preload("res://scripts/debug/DeveloperTools.gd")
var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	if not Tools.enabled():
		push_error("Use tools/run_checks.ps1 -Suite developer_checks")
		get_tree().quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(Game.CAMPAIGN_PROGRESS_PATH+suffix):
			DirAccess.remove_absolute(Game.CAMPAIGN_PROGRESS_PATH+suffix)
	if FileAccess.file_exists(Tools.CLOCK_PATH):
		DirAccess.remove_absolute(Tools.CLOCK_PATH)
	Engine.remove_meta(Tools.OFFSET_KEY)
	var real_start := int(Time.get_unix_time_from_system())
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	var tools: Node = game.get_node_or_null("DeveloperTools")
	check(tools != null,"isolated developer session exposes the controls")
	if tools == null:
		get_tree().quit(1)
		return
	tools.toggle()
	check(tools._panel.visible,"developer panel opens")
	for pair in [[435,"signal"],[100,"police"],[1050,"alone"],[1,"alone"]]:
		check(tools.jump_to(int(pair[0]),str(pair[1])),"jump accepted: %d" % int(pair[0]))
		check(game._current_level_id == int(pair[0]),"chosen board is active")
		check(game._current_route_id == str(pair[1]),"chosen approach is active")
		check(not game._board.is_locked(),"direct jump leaves a playable board")
		check(game._completed_levels.is_empty(),"jump does not fabricate victories")
		await get_tree().process_frame
	check(not tools.jump_to(1051),"nonexistent level rejected")
	check(not tools.jump_to(0),"zero level rejected")
	check(not tools.jump_to(435,"invalid"),"invalid route rejected")
	tools.refill_supplies()
	check(game._economy_manager.get_lives() == 5,"test life refill")
	check(game._economy_manager.get_booster_count("rocket") == 20,"test inventory refill")
	check(not get_node("/root/CloudAccount").login_completed.is_connected(game._account_panel._on_login_completed),"developer account panel cannot apply cloud saves")
	game._account_panel.show_account()
	check(not is_instance_valid(game._account_panel._login_dialog),"developer account action does not start sign-in")
	for dialog in game.find_children("*","AcceptDialog",true,false):
		dialog.hide()
	await get_tree().process_frame
	game._coin_shop.open(game)
	check(not is_instance_valid(game._coin_shop._layer),"developer shop does not start a purchase")
	for dialog in game.find_children("*","AcceptDialog",true,false):
		dialog.hide()
	tools.reset_daily()
	var config := DailyActivities.settings()
	for day in range(1,8):
		var coins_before: int = game._economy_manager.get_coins()
		var expected := int(config.streak_coins[day-1])
		var today := DailyActivities.day_at(TimeHelper.current_unix_time())
		var week := int(floor(float(today+3)/7))
		var weekly := int(game._campaign_progress.get_value("daily","weekly_count",0)) if int(game._campaign_progress.get_value("daily","week",-1)) == week else 0
		if weekly+1 == int(config.weekly_days):
			expected += int(config.weekly_coins)
		var stamp: Dictionary = tools.claim_stamp()
		check(int(stamp.get("streak",0)) == day,"daily streak advances day %d" % day)
		check(game._economy_manager.get_coins()-coins_before == expected,"real stamp reward credited day %d" % day)
		check(tools.claim_stamp().is_empty(),"duplicate daily stamp rejected")
		tools.advance_time("day")
	tools.reset_daily()
	tools.claim_stamp()
	tools.advance_time("miss")
	var protected: Dictionary = tools.claim_stamp()
	check(protected.get("protected",false),"skip one day exercises real streak grace")
	tools.advance_time("miss")
	check(int(tools.claim_stamp().get("streak",0)) == 1,"second missed day within cooldown resets streak")
	tools.reset_daily()
	var now := TimeHelper.current_unix_time()
	game._start_portrait_attempt()
	var attempt := DailyActivities.active_attempt(game._campaign_progress,now)
	check(not attempt.is_empty(),"portrait slot can start")
	check(game._portrait_layer != null,"real portrait screen opens in developer mode")
	var puzzle := PortraitPuzzle.new()
	puzzle.configure(attempt)
	check(puzzle._remaining_on_open <= int(DailyActivities.puzzle_for_slot(int(attempt.slot)).seconds) and puzzle._remaining_on_open > 0,"portrait timer uses test clock")
	puzzle.free()
	check(not DailyActivities.available(game._campaign_progress,now),"slot cannot start twice")
	tools.advance_time("slot")
	check(DailyActivities.available(game._campaign_progress,TimeHelper.current_unix_time()),"next slot becomes available without waiting")
	check(DailyActivities.active_attempt(game._campaign_progress,TimeHelper.current_unix_time()).is_empty(),"previous slot expires")
	check(game._portrait_layer == null,"advancing slot closes the expired portrait screen")
	game._start_portrait_attempt()
	var current := DailyActivities.active_attempt(game._campaign_progress,TimeHelper.current_unix_time())
	game._save_portrait_pieces(int(current.slot),range(current.pieces.size()))
	var portrait_coins_before: int = game._economy_manager.get_coins()
	game._complete_portrait_puzzle(int(current.slot))
	check(game._economy_manager.get_coins()-portrait_coins_before >= int(config.portrait_coins),"real portrait completion grants test coins")
	var saved_offset := int(Engine.get_meta(Tools.OFFSET_KEY,0))
	Engine.remove_meta(Tools.OFFSET_KEY)
	Tools.restore_clock()
	check(int(Engine.get_meta(Tools.OFFSET_KEY,0)) == saved_offset,"test clock survives relaunch")
	check(abs(int(Time.get_unix_time_from_system())-real_start) < 60,"real system time was not changed")
	tools.reset_daily()
	check(not game._campaign_progress.has_section("daily"),"daily reset clears only test daily state")
	check(tools.jump_to(51,"police",true),"story-inclusive jump accepted")
	check(game._pending_story_id == "serial001_intro","story-inclusive jump opens chosen episode")
	game.queue_free()
	await get_tree().create_timer(2.3).timeout
	print("DEVELOPER_CHECKS: %d checks; %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
