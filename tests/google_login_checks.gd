extends Node

var account: Node

func check(condition: bool, text: String) -> void:
	if not condition:
		push_error(text)
		get_tree().quit(1)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	account = get_node("/root/CloudAccount")
	var phase := "prepare"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-api="):
			account.base_url = arg.trim_prefix("--test-api=")
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	if phase == "prepare":
		call_deferred("_prepare")
	else:
		call_deferred("_resume")

func _prepare() -> void:
	account.cancel_login()
	account.token = ""
	account.user_id = ""
	account._save_session()
	var game := preload("res://scenes/game/Game.tscn").instantiate() as Game
	add_child(game)
	var menu_deadline := Time.get_ticks_msec()+6000
	while game._launch_layer == null and Time.get_ticks_msec() < menu_deadline:
		await get_tree().create_timer(0.1).timeout
	game._account_panel.show_account()
	var found := false
	for button in game.find_children("*", "Button", true, false):
		if button.text == "SIGN IN WITH GOOGLE":
			found = true
	check(found, "Account screen must offer Sign in with Google")
	game._account_panel._on_login_starting()
	game._account_panel._on_login_browser_opened()
	check(is_instance_valid(game._account_panel._login_dialog), "Browser handoff keeps return status available")
	var verifier := Crypto.new().generate_random_bytes(32).hex_encode()
	var started: Dictionary = await account.api("/auth/start", HTTPClient.METHOD_POST, {"challenge":verifier.sha256_text()}, false)
	check(not started.has("error"), "Login flow starts")
	account._login_state = {"flow":started.flow,"verifier":verifier,"deadline":TimeHelper.current_unix_time()+900}
	account._login_active = true
	check(account._save_pending_login(), "Login proof persists before leaving the game")
	var done: Dictionary = await account.api("/test/complete", HTTPClient.METHOD_POST, {"flow":started.flow}, false)
	check(not done.has("error"), "Fake Google finishes browser flow")
	game.queue_free()
	await get_tree().process_frame
	print("GOOGLE_LOGIN_PREPARE_PASSED")
	get_tree().quit()

func _resume() -> void:
	check(account.login_in_progress(), "A real new Godot process restores the pending login")
	var state: Dictionary = account._login_state.duplicate(true)
	var failures: Array[String] = []
	account.login_start_failed.connect(func(text: String): failures.append(text))
	var reconnects := [0]
	account.login_status_changed.connect(func(text: String):
		if text.begins_with("Reconnecting"):
			reconnects[0] += 1)
	account.resume_login()
	var deadline := Time.get_ticks_msec()+20000
	while not account.signed_in() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.1).timeout
	check(account.signed_in(), "Sign-in recovers after a completed response is lost")
	check(account.user_id == "login-test-user", "Correct account restored")
	check(failures.is_empty(), "Transient network failure must not report failed sign-in")
	check(reconnects[0] == 2, "Dropped response triggers reconnection instead of cancellation")
	check(not FileAccess.file_exists(account.LOGIN_PATH), "Completed flow proof is removed")
	var repeated: Dictionary = await account.api("/auth/poll", HTTPClient.METHOD_POST, {"flow":state.flow,"verifier":state.verifier}, false)
	check(repeated.get("token", "") == account.token, "A retried proof gets the same session")
	var saved := ConfigFile.new()
	check(saved.load(account.SESSION_PATH) == OK and saved.get_value("account", "user_id", "") == account.user_id, "Successful account session persists")
	var stats: Dictionary = await account.api("/test/stats", HTTPClient.METHOD_GET, {}, false)
	check(int(stats.dropped) == 2 and int(stats.polls) >= 3, "Test actually loses a response and injects a service failure")
	await account.sign_out()
	check(not account.signed_in(), "Logout ends the recovered session")
	var after_logout: Dictionary = await account.api("/auth/poll", HTTPClient.METHOD_POST, {"flow":state.flow,"verifier":state.verifier}, false)
	check(int(after_logout.status) == 401, "Old login proof cannot sign in again after logout")
	print("GOOGLE_LOGIN_RESUME_PASSED")
	get_tree().quit()
