extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	assert(OS.get_user_data_dir().replace("\\","/").contains("/.test-data/"))
	var account := get_node("/root/CloudAccount")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-api="):
			account.base_url = arg.trim_prefix("--test-api=")
	account.token = "game-client-test-token-00000000000000000000"
	account.user_id = "test-user"
	account.revision = 0
	account.conflict = false
	account._pending_save = {}
	var save := {"campaign":{"coins":100,"lives":3,"boosters":{"rocket":1},"completed_levels":{},"highest_unlocked_level":1},"story_choices":{"history":[]}}
	var first: Dictionary = await account.upload(save)
	assert(not first.has("error") and account.revision == 1)
	assert(account.wallet == 500)
	var cloud: Dictionary = await account.download()
	assert(cloud.save.campaign.coins == 100)
	var spend: Dictionary = await account.api("/v1/wallet/spend",HTTPClient.METHOD_POST,{"kind":"rocket","expectedPrice":150,"revision":1,"requestId":"abcdef1234567890"})
	assert(spend.wallet == 350 and spend.save.campaign.boosters.rocket == 2)
	var stale: Dictionary = await account.upload(save)
	assert(stale.status == 409 and account.conflict)
	account.applied_download(spend)
	assert(not account.conflict and account.revision == 2)
	# Exercise real Game profile backup/apply code and cloud account screen.
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	await get_tree().create_timer(2.0).timeout
	game._account_panel._set_owner("test-user")
	await game._account_panel.show_account()
	await get_tree().process_frame
	var dialog = game._account_panel._login_dialog
	var found: bool = is_instance_valid(dialog) and dialog.visible
	if found:
		dialog.queue_free()
	assert(found)
	var catalog: Dictionary = await account.api("/v1/catalog")
	assert(catalog.packs.coins_500 == 500)
	# Spend from the normal in-game shop. The test server commits this debit,
	# drops its response, and accepts an idempotent retry of the same request.
	game._economy_manager.set_coins(100)
	game._economy_manager.set_lives(0)
	var previous_board: Board = game._board
	game._coin_shop.open(game,"life")
	await game._coin_shop._load_catalog()
	await game._coin_shop._complete_buy("life",200)
	assert(game._economy_manager.get_coins() == 0 and game._economy_manager.get_lives() == 1)
	assert(account.wallet == 250 and not account.conflict)
	assert(game._board == previous_board)
	game._coin_shop._close()
	game.queue_free()
	await get_tree().process_frame
	account._pending_save = {}
	account._sync_timer.stop()
	await account.sign_out()
	assert(not account.signed_in())
	print("Cloud account checks passed: combined shop spending, lost-response retry without double charge, board preservation, account UI and logout")
	get_tree().quit()
