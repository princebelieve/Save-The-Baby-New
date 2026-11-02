extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		push_error("Use an isolated .test-data APPDATA profile")
		get_tree().quit(1)
		return
	_run()

func _run() -> void:
	var game := preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(3.0).timeout
	game._start_opening_story()
	game._skip_opening_story()
	game.get_node("Managers/LevelManager").load_level(50)
	game._begin_level("alone")
	game._finish_tutorial()
	var provider := get_node("/root/AdProvider")
	assert(provider.is_ad_ready("rewarded"))
	var factory = load("res://addons/admob/internal/mock/mock_admob_factory.gd")
	var mock = factory.get_mock_plugin("PoingGodotAdMobRewardedAd")
	var coins: int = game._economy_manager.get_coins()
	game._request_reward("editor_cancel", func(): game._economy_manager.add_coins(25))
	assert(get_tree().paused)
	await get_tree().create_timer(1.0).timeout
	mock._on_close_video_confirmed()
	await get_tree().create_timer(1.0).timeout
	assert(game._economy_manager.get_coins() == coins)
	assert(not game._ads.busy and not get_tree().paused)
	game._request_reward("editor_complete", func(): game._economy_manager.add_coins(25))
	await get_tree().create_timer(8.5).timeout
	assert(mock._reward_earned)
	mock._on_close_pressed()
	await get_tree().create_timer(1.0).timeout
	assert(game._economy_manager.get_coins() == coins + 25)
	assert(game._ads.claimed(game._ad_key("editor_complete")))
	assert(not game._ads.busy and not get_tree().paused)
	# Exercise the actual failure result and continue offer.
	game._economy_manager.lose_life(1)
	var lives: int = game._economy_manager.get_lives()
	var moves: int = game._board.get_remaining_moves()
	game._show_level_result(false)
	game._request_reward("continue", game._reward_continue)
	await get_tree().create_timer(8.5).timeout
	assert(mock._reward_earned)
	mock._on_close_pressed()
	await get_tree().create_timer(1.0).timeout
	assert(game._result_layer == null and not game._board.is_locked())
	assert(game._board.get_remaining_moves() == moves + 5)
	assert(game._economy_manager.get_lives() == lives + 1)
	# Verify interstitial gating at result exit.
	game._show_level_result(false)
	game._result_ad_shown = false
	game._return_to_campaign_map()
	assert(game._ads.busy)
	await get_tree().create_timer(1.0).timeout
	var interstitial = factory.get_mock_plugin("PoingGodotAdMobInterstitialAd")
	interstitial.on_interstitial_ad_dismissed_full_screen_content.emit(provider._active_ad._uid)
	await get_tree().create_timer(1.0).timeout
	assert(game._campaign_layer != null and game._result_layer == null)
	assert(not game._ads.busy and not get_tree().paused)
	print("Editor ad playthrough passed: cancel, reward, +5 moves, life restore, level-end ad and map return")
	get_tree().quit()
