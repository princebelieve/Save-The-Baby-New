extends Node

var game: Game
var account: Node
var purchases: Node
var _supplies: Dictionary = {}
var _owner := ""
var _pending_login: Dictionary = {}
var _login_dialog: AcceptDialog
var _login_spinner: ProgressBar
var _login_status: Label
var _login_buttons: Array[Button] = []
var _background_status := ""
const OWNER_PATH := "user://progress_owner.cfg"

func initialize(current_game: Game) -> void:
	game = current_game
	account = get_node("/root/CloudAccount")
	purchases = get_node("/root/CoinPurchases")
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	var owner := ConfigFile.new()
	if owner.load(OWNER_PATH) == OK:
		_owner = str(owner.get_value("profile","owner",""))
	account.login_completed.connect(_on_login_completed)
	account.login_starting.connect(_on_login_starting)
	account.login_browser_opened.connect(_on_login_browser_opened)
	account.login_start_failed.connect(_on_login_start_failed)
	account.login_status_changed.connect(_on_login_status_changed)
	account.logged_out.connect(_on_logout)
	account.message.connect(_notice)
	purchases.message.connect(_notice)
	account.background_message.connect(_background_notice)
	purchases.background_message.connect(_background_notice)
	if account.signed_in() and _owner == account.user_id:
		account.resume_sync()
	elif account.signed_in():
		_recover_login.call_deferred()

func _recover_login() -> void:
	var profile: Dictionary = await account.download()
	if not profile.has("error"):
		_on_login_completed(profile)

func _snapshot() -> Dictionary:
	var result: Dictionary = {}
	for section in game._campaign_progress.get_sections():
		var values: Dictionary = {}
		for key in game._campaign_progress.get_section_keys(section):
			values[key] = game._campaign_progress.get_value(section,key)
		result[section] = values
	return result

func local_changed() -> void:
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	if account.signed_in() and _owner == account.user_id:
		account.queue_save(_snapshot())

func _safe_menu() -> bool:
	return game._launch_layer != null or game._campaign_layer != null or game._result_layer != null or game._briefing_layer != null

func show_account() -> void:
	if is_instance_valid(_login_dialog) and not _login_dialog.is_queued_for_deletion() and _login_dialog.visible:
		return
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		_notice("Accounts and purchases are disabled in Developer Play. This session uses a separate test save.")
		return
	if not _safe_menu():
		_notice("You can sign in from the title screen, campaign map, or level result. Finish this attempt first; your board stays here.")
		return
	if not _pending_login.is_empty():
		var pending := _pending_login
		_pending_login = {}
		_on_login_completed(pending)
		return
	if purchases.busy or account.busy:
		_notice("A purchase or sync is still running. Try again when it finishes.")
		return
	var dialog := AcceptDialog.new()
	_login_dialog = dialog
	_login_buttons.clear()
	dialog.set_meta("custom_heading", true)
	game._prepare_dialog(dialog)
	dialog.title = ""
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(minf(600,game.get_viewport_rect().size.x*0.9),0)
	content.add_theme_constant_override("separation",16)
	var heading := Label.new()
	heading.text = "ACCOUNT & COINS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font",Game.DISPLAY_FONT)
	heading.add_theme_font_size_override("font_size",30)
	heading.add_theme_color_override("font_color",Color("#80502b"))
	content.add_child(heading)
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_override("font",Game.DISPLAY_FONT)
	status.add_theme_font_size_override("font_size",23)
	status.add_theme_color_override("font_color",Color("#4b3424"))
	status.text = ("%s · %d purchased coins" % [account.player_name,account.wallet]) if account.signed_in() else "Sign in with your existing Google account to sync progress, or continue playing as a guest."
	if not _background_status.is_empty():
		status.text += "\n" + _background_status
	content.add_child(status)
	if not account.configured():
		status.text = "Google account sign-in is unavailable right now. You can continue playing as a guest."
	if not account.signed_in():
		_button(content,"SIGN IN WITH GOOGLE",_sign_in.bind("adult"),not account.configured(),true)
		_button(content,"PARENT / GUARDIAN SIGN-IN",_sign_in.bind("guardian"),not account.configured(),true)
		_login_spinner = ProgressBar.new()
		_login_spinner.indeterminate = true
		_login_spinner.custom_minimum_size = Vector2(0,20)
		_login_spinner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var spinner_track := StyleBoxFlat.new()
		spinner_track.bg_color = Color("#e8dcc2")
		spinner_track.set_corner_radius_all(8)
		_login_spinner.add_theme_stylebox_override("background",spinner_track)
		var spinner_fill := StyleBoxFlat.new()
		spinner_fill.bg_color = Color("#946333")
		spinner_fill.set_corner_radius_all(8)
		_login_spinner.add_theme_stylebox_override("fill",spinner_fill)
		_login_spinner.hide()
		content.add_child(_login_spinner)
		_login_status = Label.new()
		_login_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_login_status.add_theme_font_override("font",Game.DISPLAY_FONT)
		_login_status.add_theme_font_size_override("font_size",21)
		_login_status.add_theme_color_override("font_color",Color("#4b3424"))
		_login_status.hide()
		content.add_child(_login_status)
		if account.login_in_progress():
			_on_login_starting()
			_on_login_status_changed("Waiting for Google sign-in. Finish in your browser, then tap Return to game.")
			_button(content,"CHECK SIGN-IN STATUS",account.resume_login,false,true)
			_button(content,"CANCEL SIGN-IN",_cancel_sign_in,false,true)
	else:
		_button(content,"SAVE TO CLOUD",_upload)
		_button(content,"LOAD CLOUD PROGRESS",_confirm_download)
		if account.conflict:
			status.text += "\nAnother device has newer progress. Load the cloud save to resolve the conflict."
		var pack_label := Label.new()
		pack_label.text = "BUY COINS (GOOGLE PLAY)"
		_style_section_label(pack_label)
		content.add_child(pack_label)
		for product in purchases.PRODUCTS:
			var offer: Dictionary = purchases.products.get(product,{})
			var price := str(offer.get("formatted_price","Unavailable"))
			_button(content,"%d COINS - %s" % [purchases.PRODUCTS[product],price],_confirm_purchase.bind(product,price),not purchases.available(product))
		var supply_label := Label.new()
		supply_label.text = "USE PURCHASED COINS"
		_style_section_label(supply_label)
		content.add_child(supply_label)
		var supply_entries := VBoxContainer.new()
		supply_entries.name = "AccountSupplyEntries"
		content.add_child(supply_entries)
		var loading := Label.new()
		loading.text = "Loading online prices..."
		loading.add_theme_color_override("font_color", Color("#4b3424"))
		supply_entries.add_child(loading)
		_button(content,"CHECK PENDING PURCHASES",func(): purchases.restore())
		_button(content,"SIGN OUT",func(): account.sign_out())
		_button(content,"DELETE ONLINE ACCOUNT",_confirm_delete)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(content.custom_minimum_size.x,mini(940,int(game.get_viewport_rect().size.y*0.76)))
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	_style_account_scrollbar(scroll.get_v_scroll_bar())
	dialog.add_child(scroll)
	game.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.get_ok_button().text = "CLOSE"
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_clamped(Vector2i(int(content.custom_minimum_size.x+56),int(scroll.custom_minimum_size.y+112)))
	if account.signed_in():
		_load_account_supplies.call_deferred(dialog, content.find_child("AccountSupplyEntries", true, false), str(account.user_id))


func _load_account_supplies(dialog: AcceptDialog, entries: VBoxContainer, owner: String) -> void:
	if not is_instance_valid(dialog) or not is_instance_valid(entries): return
	for child in entries.get_children():
		if child is BaseButton: child.disabled = true
	var catalog: Dictionary = await account.api("/v1/catalog", HTTPClient.METHOD_GET, {}, true, 8.0)
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion() or dialog != _login_dialog or not is_instance_valid(entries) or not account.signed_in() or str(account.user_id) != owner:
		return
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	_supplies = catalog.get("supplies", {}) if not catalog.has("error") and int(catalog.get("shopVersion", 0)) >= 2 else {}
	if _supplies.is_empty():
		var unavailable := Label.new()
		unavailable.text = "Online prices are unavailable. You can close this screen and keep playing."
		unavailable.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unavailable.add_theme_color_override("font_color", Color("#4b3424"))
		entries.add_child(unavailable)
		_button(entries, "RETRY ONLINE PRICES", _load_account_supplies.bind(dialog, entries, owner), false, true)
		return
	for kind in _supplies:
		if kind == "continue": continue
		var supply: Dictionary = _supplies[kind]
		var ethan_full: bool = kind == "ethan" and game._economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS
		_button(entries, "%s - %d purchased coins" % ["Refill to 5 lives" if kind == "lives" else "+1 " + kind.capitalize(), int(supply.price)], _spend.bind(kind), account.wallet < int(supply.price) or account.conflict or ethan_full or (kind in ["life", "lives"] and game._economy_manager.get_lives() >= 5))

func _style_section_label(label: Label) -> void:
	label.add_theme_font_override("font",Game.DISPLAY_FONT)
	label.add_theme_font_size_override("font_size",32)
	label.add_theme_color_override("font_color",Color("#80502b"))

func _style_account_scrollbar(scrollbar: VScrollBar) -> void:
	for style_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_content_margin_all(3)
		style.bg_color = Color("#e8dcc2") if style_name == "scroll" else Color("#b58a52")
		if style_name == "grabber_highlight":
			style.bg_color = Color("#946333")
		scrollbar.add_theme_stylebox_override(style_name,style)

func _sign_in(owner_mode: String) -> void:
	account.set_account_owner_mode(owner_mode)
	account.sign_in("self" if owner_mode == "adult" else "guardian")

func _on_login_starting() -> void:
	if not is_instance_valid(_login_dialog): return
	for button in _login_buttons: button.disabled = true
	_login_dialog.get_ok_button().disabled = false
	_login_spinner.show()
	_login_status.text = "Preparing Google sign-in..."
	_login_status.show()

func _on_login_browser_opened() -> void:
	_on_login_status_changed("Finish signing in with Google, then tap Return to game in the browser.")
	if is_instance_valid(_login_dialog) and _login_dialog.find_child("CancelGoogleLogin", true, false) == null:
		var cancel := _login_dialog.add_button("CANCEL SIGN-IN", false, "cancel_login")
		cancel.name = "CancelGoogleLogin"
		cancel.pressed.connect(_cancel_sign_in)

func _on_login_status_changed(text: String) -> void:
	if is_instance_valid(_login_dialog) and is_instance_valid(_login_status):
		_login_status.text = text
		_login_status.show()

func _cancel_sign_in() -> void:
	account.cancel_login()
	_on_login_start_failed("Sign-in canceled. You can sign in again or continue as a guest.")

func _on_login_start_failed(text: String) -> void:
	if not is_instance_valid(_login_dialog):
		_notice(text)
		return
	_login_spinner.hide()
	_login_status.text = text
	_login_status.show()
	for button in _login_buttons: button.disabled = false
	_login_dialog.get_ok_button().disabled = false

func _confirm_purchase(product: String, price: String) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.set_meta("custom_heading", true)
	game._prepare_dialog(confirm)
	confirm.title = "GOOGLE PLAY PURCHASE"
	confirm.get_label().hide()
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var heading := Label.new()
	heading.text = "GOOGLE PLAY PURCHASE"
	heading.add_theme_font_size_override("font_size", 28)
	content.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(minf(520, game.get_viewport_rect().size.x * .75), minf(480, game.get_viewport_rect().size.y * .45))
	content.add_child(scroll)
	var body := Label.new()
	body.text = "%d coins for %s.\n\n%sGoogle Play will handle payment and any purchase approval required by your family settings. Coins are added only after payment is confirmed.\n\nCoins belong to the signed-in game account: %s." % [purchases.PRODUCTS[product],price,"Ask your parent or guardian to continue.\n\n" if account.needs_parent_account() else "",account.player_name]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 26)
	scroll.add_child(body)
	confirm.add_child(content)
	confirm.ok_button_text = "CONTINUE TO GOOGLE PLAY"
	confirm.confirmed.connect(func(): purchases.buy(product))
	confirm.confirmed.connect(confirm.queue_free)
	confirm.canceled.connect(confirm.queue_free)
	if is_instance_valid(game._coin_shop) and is_instance_valid(game._coin_shop._dialog) and game._coin_shop._dialog.visible:
		game._coin_shop._dialog.add_child(confirm)
	else:
		game.add_child(confirm)
	confirm.popup_centered_clamped(Vector2i(600,760))

func _button(parent: Control,title: String,action: Callable,disabled := false,keep_open := false) -> void:
	var button := game._make_menu_button(title)
	button.custom_minimum_size = Vector2(0,92)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",34)
	button.disabled = disabled
	if keep_open: _login_buttons.append(button)
	button.pressed.connect(func():
		if keep_open:
			action.call()
			return
		var window := button.get_window()
		window.hide()
		window.queue_free()
		action.call()
	)
	parent.add_child(button)

func _notice(text: String) -> void:
	if is_instance_valid(game):
		game._show_shop_notice(text, "ACCOUNT & COINS")

func _background_notice(text: String) -> void:
	_background_status = text
	if is_instance_valid(game) and is_instance_valid(game._coin_shop) and is_instance_valid(game._coin_shop._layer) and not game._coin_shop._layer.is_queued_for_deletion():
		game._coin_shop.show_message(text)

func _archive_current() -> void:
	DirAccess.make_dir_recursive_absolute("user://profiles")
	var name := "guest" if _owner.is_empty() else _owner
	CampaignProgressStore.write(game._campaign_progress,"user://profiles/%s.cfg" % name)

func _set_owner(owner: String) -> void:
	_owner = owner
	var saved := ConfigFile.new()
	saved.set_value("profile","owner",owner)
	CampaignProgressStore.write(saved,OWNER_PATH)

func _on_login_completed(profile: Dictionary) -> void:
	if is_instance_valid(_login_dialog):
		_login_dialog.hide()
		_login_dialog.queue_free()
	_login_dialog = null
	if not _safe_menu():
		_pending_login = profile
		_notice("Signed in. Open Account & Coins from the map to load cloud progress.")
		return
	if profile.get("save") is Dictionary:
		var confirm := ConfirmationDialog.new()
		game._prepare_dialog(confirm)
		confirm.title = "CLOUD PROGRESS FOUND"
		confirm.dialog_text = "Load the progress for this Google account? This device's current progress will be backed up separately."
		confirm.ok_button_text = "LOAD CLOUD SAVE"
		confirm.confirmed.connect(func(): _apply(profile))
		confirm.confirmed.connect(confirm.queue_free)
		confirm.canceled.connect(confirm.queue_free)
		game.add_child(confirm)
		confirm.popup_centered_clamped(Vector2i(520,260))
	else:
		_archive_current()
		_set_owner(account.user_id)
		account.resume_sync()
		_upload()

func _upload() -> void:
	if _owner != account.user_id:
		_notice("Load your Google account's cloud progress first. Your guest progress is backed up separately.")
		return
	var result: Dictionary = await account.upload(_snapshot())
	if not result.has("error"):
		_notice("Progress saved to your Google account.")

func _confirm_download() -> void:
	var confirm := ConfirmationDialog.new()
	game._prepare_dialog(confirm)
	confirm.title = "LOAD CLOUD PROGRESS"
	confirm.dialog_text = "Replace this device's progress with the latest cloud save? Your current save will be backed up locally."
	confirm.ok_button_text = "LOAD CLOUD SAVE"
	confirm.confirmed.connect(_download)
	confirm.confirmed.connect(confirm.queue_free)
	confirm.canceled.connect(confirm.queue_free)
	game.add_child(confirm)
	confirm.popup_centered_clamped(Vector2i(520,260))

func _download() -> void:
	var result: Dictionary = await account.download()
	if result.has("error"):
		_notice(str(result.error))
	elif result.get("save") is Dictionary:
		_apply(result)
	else:
		_notice("This account has no cloud progress yet.")

func _apply(profile: Dictionary) -> void:
	_archive_current()
	var save := ConfigFile.new()
	var snapshot: Dictionary = profile.save
	for section in snapshot:
		if snapshot[section] is Dictionary:
			for key in snapshot[section]:
				save.set_value(str(section),str(key),snapshot[section][key])
	if CampaignProgressStore.write(save,Game.CAMPAIGN_PROGRESS_PATH) != OK:
		_notice("Could not load cloud progress. Your existing save is backed up.")
		return
	_set_owner(account.user_id)
	account.applied_download(profile)
	get_tree().reload_current_scene()

func _spend(kind: String) -> void:
	await spend_supply(kind,int(_supplies.get(kind,{}).get("price",-1)),false)

func spend_supply(kind: String, expected_price: int, use_earned: bool) -> bool:
	if purchases.busy or account.busy:
		_notice("A purchase or sync is still running. Try again when it finishes.")
		return false
	if _owner != account.user_id or account.conflict:
		_notice("Load your account's cloud save before using purchased coins.")
		return false
	var uploaded: Dictionary = await account.upload(_snapshot())
	if uploaded.has("error"):
		return false
	account.busy = true
	var request_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var result: Dictionary = {}
	# Reuse the request ID after a lost response: the server may have committed
	# the debit already. Retrying must never purchase the same supply twice.
	var request := {"kind":kind,"revision":account.revision,"requestId":request_id,"expectedPrice":expected_price,"useEarned":use_earned}
	for _attempt in 3:
		result = await account.api("/v1/wallet/spend",HTTPClient.METHOD_POST,request,true,12.0)
		if not result.has("error") or int(result.get("status",0)) not in [0,408,425,429,500,502,503,504]:
			break
	account.busy = false
	if result.has("error"):
		# A lost response may hide a successful debit. Stop uploads until a download reconciles it.
		account.conflict = true
		account._save_session()
		_notice(str(result.error) + " Load cloud progress before trying again.")
		return false
	# Persist the authoritative snapshot before acknowledging it. Keep the active
	# board intact: buying a supply must not restart a level or throw away moves.
	var save := ConfigFile.new()
	for section in result.save:
		for key in result.save[section]:
			save.set_value(section,key,result.save[section][key])
	if CampaignProgressStore.write(save,Game.CAMPAIGN_PROGRESS_PATH) != OK:
		account.conflict = true
		account._save_session()
		_notice("Purchase confirmed online. Load cloud progress to recover your supply.")
		return false
	game._progress_transaction = true
	game._campaign_progress = save
	var campaign: Dictionary = result.save.campaign
	game._economy_manager.set_coins(int(campaign.get("coins",0)))
	game._economy_manager.set_lives(int(campaign.get("lives",0)))
	game._economy_manager.set_ethan_count(int(campaign.get("ethan",0)))
	for booster in ["rocket","bomb","thunder"]:
		game._economy_manager.set_booster_count(booster,int(campaign.get("boosters",{}).get(booster,0)))
	game._progress_transaction = false
	account.applied_download(result)
	game._save_inventory_progress()
	return true

func _on_logout() -> void:
	_archive_current()
	var guest := ConfigFile.new()
	if CampaignProgressStore.read(guest,"user://profiles/guest.cfg") != OK:
		guest.clear()
	CampaignProgressStore.write(guest,Game.CAMPAIGN_PROGRESS_PATH)
	_set_owner("")
	get_tree().reload_current_scene()

func _confirm_delete() -> void:
	var confirm := ConfirmationDialog.new()
	game._prepare_dialog(confirm)
	confirm.title = "DELETE ONLINE ACCOUNT?"
	confirm.dialog_text = "Delete your cloud progress and purchased coin balance? Purchase records needed to prevent duplicate credits may be retained. This cannot be undone."
	confirm.ok_button_text = "DELETE ACCOUNT"
	confirm.confirmed.connect(func(): account.sign_out(true))
	confirm.confirmed.connect(confirm.queue_free)
	confirm.canceled.connect(confirm.queue_free)
	game.add_child(confirm)
	confirm.popup_centered_clamped(Vector2i(520,300))
