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
	var spend: Dictionary = await account.api("/v1/wallet/spend",HTTPClient.METHOD_POST,{"kind":"rocket","revision":1,"requestId":"abcdef1234567890"})
	assert(spend.wallet == 465 and spend.save.campaign.boosters.rocket == 2)
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
	game._account_panel.show_account()
	await get_tree().process_frame
	var found := false
	for child in game.get_children():
		if child is AcceptDialog and child.title == "ACCOUNT & COINS":
			found = true
			child.queue_free()
	assert(found)
	var catalog: Dictionary = await account.api("/v1/catalog")
	assert(catalog.packs.coins_500 == 500)
	game.queue_free()
	await get_tree().process_frame
	account._pending_save = {}
	account._sync_timer.stop()
	await account.sign_out()
	assert(not account.signed_in())
	print("Cloud account checks passed: API, revision conflict, wallet spending, account UI and logout")
	get_tree().quit()
