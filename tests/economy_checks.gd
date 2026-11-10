extends Node

var failures: Array[String] = []

class OfflineAccount extends "res://scripts/online/CloudAccount.gd":
	func api(_path: String, _method: HTTPClient.Method = HTTPClient.METHOD_GET, _data: Dictionary = {}, _authenticated := true, _timeout_seconds := 25.0) -> Dictionary:
		return {"error": "Could not connect.", "status": 0}
	func _save_session() -> void: pass

class FakeAds extends RefCounted:
	var ready := true
	var earned: Callable
	var closed: Callable
	func is_ad_ready(_kind: String) -> bool:
		return ready
	func show_ad(_kind: String, _placement: String, earned_callback: Callable, closed_callback: Callable) -> void:
		earned = earned_callback
		closed = closed_callback

func check(condition: bool, message: String) -> void:
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
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await get_tree().create_timer(2.0).timeout
	var economy: EconomyManager = game._economy_manager
	var shop: Node = game._coin_shop
	var account := get_node("/root/CloudAccount")
	account.token = ""
	account.user_id = ""
	await _check_background_notices(game)
	economy.set_coins(1000)
	economy.set_lives(0)
	shop.open(game,"lives")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.test-data/economy-shop.png")
	shop._buy("life")
	var confirmation: ConfirmationDialog
	for child in shop._dialog.get_children():
		if child is ConfirmationDialog:
			confirmation = child
	check(is_instance_valid(confirmation) and confirmation.visible,"Coin purchase requires a visible confirmation within the shop")
	confirmation.canceled.emit()
	await get_tree().process_frame
	await shop._complete_buy("life",200)
	check(economy.get_coins() == 800 and economy.get_lives() == 1,"One life deducts 200 earned coins")
	await shop._complete_buy("lives",900)
	check(economy.get_coins() == 800 and economy.get_lives() == 1,"Insufficient funds never grants lives")
	economy.set_coins(2000)
	await shop._complete_buy("lives",900)
	check(economy.get_coins() == 1100 and economy.get_lives() == 5,"Refill caps at five lives and deducts 900")
	await shop._complete_buy("life",200)
	check(economy.get_coins() == 1100,"Full meter cannot spend on another life")
	var rockets := economy.get_booster_count("rocket")
	await shop._complete_buy("rocket",150)
	check(economy.get_coins() == 950 and economy.get_booster_count("rocket") == rockets+1,"Booster purchase deducts configured coins")
	shop._close()
	await get_tree().process_frame
	# Recreate an exhausted result without changing the board's tile layout.
	game._board._remaining_moves = 0
	game._moves_remaining = 0
	game._result_layer = CanvasLayer.new()
	game.add_child(game._result_layer)
	economy.set_lives(4)
	var active_board: Board = game._board
	shop.open(game,"continue")
	await shop._complete_buy("continue",500)
	check(economy.get_coins() == 450,"Five-move continuation costs 500 coins")
	check(game._board == active_board and active_board.get_remaining_moves() == 5,"Continuation preserves the active board and grants exactly five moves")
	check(economy.get_lives() == 5 and game._paid_revived,"Continuation restores the life lost on this failure once")
	check(int(game._campaign_progress.get_value("campaign","continue_credits",0)) == 0,"Continuation ticket consumed exactly once")
	game._use_coin_continue()
	check(active_board.get_remaining_moves() == 5 and economy.get_coins() == 450,"Repeated continuation callback does not grant or charge twice")
	var config := ConfigFile.new()
	check(CampaignProgressStore.read(config,Game.CAMPAIGN_PROGRESS_PATH) == OK and int(config.get_value("campaign","coins",-1)) == 450,"Final purchase balance survives disk persistence")
	check(FileAccess.file_exists("user://balance_events.jsonl"),"Local balance diagnostics are recorded")
	await get_tree().process_frame
	game._paid_revived = false
	active_board._remaining_moves = 0
	game._moves_remaining = 0
	game._result_layer = CanvasLayer.new()
	game.add_child(game._result_layer)
	game._campaign_progress.set_value("campaign","continue_credits",1)
	shop.open(game,"continue")
	await shop._complete_buy("continue",500)
	check(economy.get_coins() == 450 and active_board.get_remaining_moves() == 5,"A recovered continuation ticket grants moves without charging again")
	_check_ads(economy)
	game.queue_free()
	await get_tree().process_frame
	print("ECONOMY_CHECKS: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_background_notices(game: Game) -> void:
	var billing := preload("res://scripts/online/CoinPurchases.gd").new()
	var modal := [0]
	var background := [0]
	billing.message.connect(func(_text): modal[0] += 1)
	billing.background_message.connect(func(_text): background[0] += 1)
	for attempt in 3:
		billing._on_purchases({"response_code": -1})
	check(modal[0] == 0 and background[0] == 3, "Repeated background billing failures never request popups")
	billing.busy = true
	billing._on_purchases({"response_code": -1})
	check(modal[0] == 1, "An initiated purchase still reports its failure")
	billing.free()
	var cloud := OfflineAccount.new()
	modal[0] = 0
	background[0] = 0
	cloud.message.connect(func(_text): modal[0] += 1)
	cloud.background_message.connect(func(_text): background[0] += 1)
	for attempt in 3: await cloud.upload({"campaign": {}}, false)
	check(modal[0] == 0 and background[0] == 3, "Background cloud failures never request popups")
	await cloud.upload({"campaign": {}})
	check(modal[0] == 1, "Manual cloud save still reports its failure")
	cloud.free()
	var dialogs_before := game.find_children("*", "AcceptDialog", true, false).size()
	game._account_panel._background_notice("Offline. Local progress is safe.")
	check(game.find_children("*", "AcceptDialog", true, false).size() == dialogs_before, "Background status never creates a game dialog")
	game._coin_shop.open(game)
	game._account_panel._background_notice("Purchase verification will retry.")
	check(game._coin_shop._status == "Purchase verification will retry.", "Background status is readable in an open shop")
	game._coin_shop._close()
	await get_tree().process_frame

func _check_ads(economy: EconomyManager) -> void:
	var ads := AdManager.new()
	add_child(ads)
	var provider := FakeAds.new()
	ads.configure(provider)
	economy.set_lives(3)
	ads.finished.connect(func(earned: bool):
		if earned:
			economy.add_life(1))
	check(ads.show_ad("rewarded","life_test"),"A loaded rewarded ad can start")
	provider.closed.call()
	check(economy.get_lives() == 3 and not ads.claimed("life_test"),"Closing without the SDK reward never grants a life")
	check(ads.show_ad("rewarded","life_test"),"An unearned placement can be retried")
	provider.earned.call()
	provider.closed.call()
	check(economy.get_lives() == 4 and ads.claimed("life_test"),"Completed reward grants exactly one life")
	provider.earned.call()
	provider.closed.call()
	check(economy.get_lives() == 4 and not ads.show_ad("rewarded","life_test"),"Duplicate reward and close callbacks cannot grant twice")
	provider.ready = false
	check(not ads.show_ad("rewarded","unavailable_test") and economy.get_lives() == 4,"Unavailable ad never grants a reward")
	provider.earned = Callable()
	provider.closed = Callable()
	ads.provider = null
	ads.queue_free()
