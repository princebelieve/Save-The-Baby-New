extends Node

var failures: Array[String] = []
var surfaces: Array[String] = []
var checks := 0
var game: Game

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func contrast(a: Color, b: Color) -> float:
	var x := a.srgb_to_linear().get_luminance()
	var y := b.srgb_to_linear().get_luminance()
	return (maxf(x,y)+.05)/(minf(x,y)+.05)

func settle() -> void:
	for frame in 8: await get_tree().process_frame

func inspect(window: AcceptDialog, context: String) -> void:
	await settle()
	check(is_instance_valid(window) and window.visible, context + " opens")
	if not is_instance_valid(window): return
	surfaces.append(context)
	check(game.get_viewport_rect().grow(2).encloses(Rect2(Vector2(window.position), Vector2(window.size))), context + " window and footer fit the screen: %s / %s" % [Rect2(Vector2(window.position), Vector2(window.size)), game.get_viewport_rect()])
	for node in window.find_children("*", "Control", true, false):
		if not node.is_visible_in_tree(): continue
		if node is RichTextLabel and not node.text.is_empty():
			check(contrast(node.get_theme_color("default_color"), Color("#fff8e8")) >= 4.5, context + " rich text contrasts with paper")
			check(node.get_theme_font_size("normal_font_size") >= 24, context + " legal body has readable size")
		elif node is Label and not node.text.is_empty():
			check(contrast(node.get_theme_color("font_color"), Color("#fff8e8")) >= 4.5, context + " label readable: " + node.text.left(40))
		elif node is Button and not node.text.is_empty():
			var state := "pressed" if node.button_pressed else "normal"
			var style: StyleBox = node.get_theme_stylebox(state)
			if style is StyleBoxFlat:
				var ink: Color = node.get_theme_color("font_pressed_color" if node.button_pressed else "font_color")
				check(contrast(ink, style.bg_color) >= 3.0, context + " button text readable: " + node.text)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.test-data/dialog-%s.png" % context)

func close(window: AcceptDialog) -> void:
	if is_instance_valid(window):
		window.hide()
		window.queue_free()
	await settle()

func last_dialog() -> AcceptDialog:
	var windows := game.find_children("*", "AcceptDialog", true, false)
	return windows.back() if not windows.is_empty() else null

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("run")

func run() -> void:
	game = preload("res://scenes/game/Game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().create_timer(2).timeout
	game._skip_opening_story()
	game._finish_tutorial()
	get_node("/root/CloudAccount").token = ""
	get_node("/root/CloudAccount").user_id = ""
	game._show_audio_settings(game.get_node("HUD"))
	var settings: AcceptDialog = game.find_child("AudioSettings", true, false)
	await inspect(settings, "settings")
	for document in [{"title":"PRIVACY POLICY", "path":"privacy_policy.md", "name":"PrivacyPolicyDialog", "key":"privacy"}, {"title":"TERMS AND CONDITIONS", "path":"terms_and_conditions.md", "name":"TermsDialog", "key":"terms"}]:
		game._show_legal_document(settings, document.title, "res://legal/"+document.path)
		var viewer: AcceptDialog = game.find_child(document.name, true, false)
		await inspect(viewer, document.key)
		var body: RichTextLabel = viewer.find_child("LegalDocumentBody", true, false)
		check(body != null and body.text.length() > 300, document.key + " contains the actual document")
		await close(viewer)
	await close(settings)
	game._account_panel.show_account()
	await inspect(game._account_panel._login_dialog, "account")
	await close(game._account_panel._login_dialog)
	game._coin_shop.open(game)
	await inspect(game._coin_shop._dialog, "shop")
	game._coin_shop._buy("rocket")
	await inspect(last_dialog(), "supply-confirmation")
	await close(last_dialog())
	game._coin_shop._close()
	await settle()
	game._account_panel._confirm_purchase("coins_500", "Test price")
	await inspect(last_dialog(), "purchase-confirmation")
	await close(last_dialog())
	game._account_panel._confirm_delete()
	await inspect(last_dialog(), "delete-confirmation")
	await close(last_dialog())
	game._show_shop_notice("Your local progress is safe.")
	await inspect(last_dialog(), "notice")
	await close(last_dialog())
	var report := FileAccess.open("res://.test-data/dialog-readability-report.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"surfaces":surfaces,"failures":failures}, "  "))
	game.queue_free()
	await settle()
	print("DIALOG_READABILITY_CHECKS: %d surfaces; %d checks; %d failures" % [surfaces.size(),checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
