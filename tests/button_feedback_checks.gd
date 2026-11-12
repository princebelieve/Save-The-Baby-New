extends Node
signal finish
var calls := 0
var failures := 0
var checks := 0

class SlowAccount extends Node:
	signal finish
	var user_id := "test"
	func upload(_snapshot: Dictionary) -> Dictionary:
		await finish
		return {"error": "Offline"}
	func download() -> Dictionary:
		await finish
		return {"error": "Offline"}
	func sign_out(_delete := false) -> void:
		await finish

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func delayed() -> void:
	calls += 1
	await finish

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	var button := MobileGameUI.button(self, "SAVE", delayed, MobileGameUI.TEAL, "Please wait…")
	button.pressed.emit()
	check(button.disabled and button.text.contains("wait"), "async button immediately shows pending feedback")
	button.pressed.emit()
	check(calls == 1, "repeated activation never repeats pending action")
	finish.emit()
	check(not button.disabled and button.text == "SAVE", "completion restores caption and retry access")
	button.pressed.emit()
	button.queue_free()
	await get_tree().process_frame
	finish.emit()
	check(calls == 2, "closing screen during request is safe")
	var synchronous := MobileGameUI.button(self, "Practice", Callable())
	synchronous.pressed.connect(func():
		synchronous.text = "Complete practice first"
		synchronous.disabled = true)
	synchronous.pressed.emit()
	check(synchronous.disabled and synchronous.text == "Complete practice first", "instant actions preserve their own tutorial state")
	var game: Game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(2).timeout
	var account := SlowAccount.new()
	add_child(account)
	var panel := preload("res://scripts/online/AccountPanel.gd").new()
	panel.game = game
	panel.account = account
	panel._owner = "test"
	add_child(panel)
	panel._login_dialog = AcceptDialog.new()
	game.add_child(panel._login_dialog)
	panel._login_spinner = ProgressBar.new()
	panel._login_status = Label.new()
	panel._login_dialog.add_child(panel._login_spinner)
	panel._login_dialog.add_child(panel._login_status)
	var login := Button.new()
	login.text = "SIGN IN WITH GOOGLE"
	panel._login_dialog.add_child(login)
	panel._login_buttons.append(login)
	panel._on_login_starting()
	check(login.disabled and login.text == "Signing in…" and panel._login_spinner.visible, "Google login shows pending caption and progress")
	panel._on_login_start_failed("Canceled")
	check(not login.disabled and login.text == "SIGN IN WITH GOOGLE" and not panel._login_spinner.visible, "login cancellation restores retry")
	for method in ["_upload", "_download", "_sign_out"]:
		panel.call(method)
		check(panel._operation_busy and panel._operation_dialog.visible, "visible progress for " + method)
		check(panel._operation_dialog.get_ok_button().disabled, "pending operation cannot be dismissed as complete")
		check(not panel._begin_operation("Duplicate"), "duplicate account operation blocked")
		account.finish.emit()
		await get_tree().process_frame
		check(not panel._operation_busy and panel._operation_dialog == null, "error/completion releases operation and enables retry")
		for dialog in game.find_children("*", "AcceptDialog", true, false):
			if dialog.visible:
				dialog.hide()
				dialog.confirmed.emit()
		await get_tree().process_frame
	game.queue_free()
	panel.queue_free()
	account.queue_free()
	await get_tree().process_frame
	print("BUTTON_FEEDBACK_CHECKS: %d checks; %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
