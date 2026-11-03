extends Node

var game: Game
var account: Node
var purchases: Node
var _owner := ""
var _pending_login: Dictionary = {}
const OWNER_PATH := "user://progress_owner.cfg"

func initialize(current_game: Game) -> void:
	game = current_game
	account = get_node("/root/CloudAccount")
	purchases = get_node("/root/CoinPurchases")
	var owner := ConfigFile.new()
	if owner.load(OWNER_PATH) == OK:
		_owner = str(owner.get_value("profile","owner",""))
	account.login_completed.connect(_on_login_completed)
	account.logged_out.connect(_on_logout)
	account.message.connect(_notice)
	purchases.message.connect(_notice)
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
	if account.signed_in() and _owner == account.user_id:
		account.queue_save(_snapshot())

func _safe_menu() -> bool:
	return game._launch_layer != null or game._campaign_layer != null

func show_account() -> void:
	if not _safe_menu():
		_notice("Open Account & Coins from the title screen or campaign map after finishing your case.")
		return
	if not _pending_login.is_empty():
		var pending := _pending_login
		_pending_login = {}
		_on_login_completed(pending)
		return
	if purchases.busy or account.busy:
		_notice("Please wait for the current purchase or sync to finish.")
		return
	var dialog := AcceptDialog.new()
	game._prepare_dialog(dialog)
	dialog.title = "ACCOUNT & COINS"
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(minf(480,game.get_viewport_rect().size.x*0.78),0)
	content.add_theme_constant_override("separation",8)
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = ("%s | Purchased coins: %d" % [account.player_name,account.wallet]) if account.signed_in() else "Playing as guest. Sign in with Google to save progress across devices."
	content.add_child(status)
	if not account.configured():
		status.text += "\nOnline services await server setup. Guest play remains available."
	if not account.signed_in():
		if account.needs_parent_account():
			status.text = "Playing as guest. Ask a parent or guardian to manage cloud saves and coin purchases with their own Google account."
		_button(content,"PARENT / GUARDIAN SIGN IN" if account.needs_parent_account() else "SIGN IN WITH GOOGLE",_sign_in,not account.configured())
	else:
		var player_id := Label.new()
		player_id.text = "Player ID: " + account.user_id
		player_id.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		player_id.add_theme_font_size_override("font_size",12)
		content.add_child(player_id)
		_button(content,"SAVE TO CLOUD",_upload)
		_button(content,"LOAD CLOUD PROGRESS",_confirm_download)
		if account.conflict:
			status.text += "\nAnother device has newer progress. Load the cloud save to resolve the conflict."
		var pack_label := Label.new()
		pack_label.text = "BUY COINS (GOOGLE PLAY)"
		content.add_child(pack_label)
		for product in purchases.PRODUCTS:
			var offer: Dictionary = purchases.products.get(product,{})
			var price := str(offer.get("formatted_price","Unavailable"))
			_button(content,"%d COINS - %s" % [purchases.PRODUCTS[product],price],_confirm_purchase.bind(product,price),not purchases.available(product))
		var supply_label := Label.new()
		supply_label.text = "USE PURCHASED COINS"
		content.add_child(supply_label)
		for supply in [["rocket",35],["bomb",50],["thunder",70],["ethan",90],["lives",100]]:
			var kind := str(supply[0])
			var ethan_full := kind == "ethan" and game._economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS
			_button(content,"%s - %d coins" % ["5 lives" if kind == "lives" else "+1 " + kind.capitalize(),supply[1]],_spend.bind(kind),account.wallet<int(supply[1]) or account.conflict or ethan_full)
		_button(content,"CHECK PENDING PURCHASES",func(): purchases.restore())
		_button(content,"SIGN OUT",func(): account.sign_out())
		_button(content,"DELETE ONLINE ACCOUNT",_confirm_delete)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(content.custom_minimum_size.x,mini(740,int(game.get_viewport_rect().size.y*0.65)))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	dialog.add_child(scroll)
	game.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_clamped(Vector2i(int(content.custom_minimum_size.x+36),int(scroll.custom_minimum_size.y+80)))

func _sign_in() -> void:
	if not account.needs_parent_account():
		account.sign_in()
		return
	var confirm := ConfirmationDialog.new()
	game._prepare_dialog(confirm)
	confirm.title = "ASK A PARENT OR GUARDIAN"
	confirm.dialog_text = "Please hand this device to your parent or guardian.\n\nParent: use your own Google account to manage this save and purchased coins. Read the account notice in the browser before continuing.\n\nYou can cancel and keep playing."
	confirm.ok_button_text = "OPEN ACCOUNT NOTICE"
	confirm.confirmed.connect(func(): account.sign_in())
	confirm.confirmed.connect(confirm.queue_free)
	confirm.canceled.connect(confirm.queue_free)
	game.add_child(confirm)
	confirm.popup_centered_clamped(Vector2i(520,320))

func _confirm_purchase(product: String, price: String) -> void:
	var confirm := ConfirmationDialog.new()
	game._prepare_dialog(confirm)
	confirm.title = "GOOGLE PLAY PURCHASE"
	confirm.dialog_text = "%d coins for %s.\n\n%sGoogle Play will handle payment and any purchase approval required by your family settings. Coins are added only after payment is confirmed.\n\nCoins belong to the signed-in game account: %s." % [purchases.PRODUCTS[product],price,"Ask your parent or guardian to continue.\n\n" if account.needs_parent_account() else "",account.player_name]
	confirm.ok_button_text = "CONTINUE TO GOOGLE PLAY"
	confirm.confirmed.connect(func(): purchases.buy(product))
	confirm.confirmed.connect(confirm.queue_free)
	confirm.canceled.connect(confirm.queue_free)
	game.add_child(confirm)
	confirm.popup_centered_clamped(Vector2i(520,340))

func _button(parent: Control,title: String,action: Callable,disabled := false) -> void:
	var button := game._make_menu_button(title)
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size",17)
	button.disabled = disabled
	button.pressed.connect(func():
		var window := button.get_window()
		window.hide()
		window.queue_free()
		action.call()
	)
	parent.add_child(button)

func _notice(text: String) -> void:
	if is_instance_valid(game) and _safe_menu():
		game._show_shop_notice(text)

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
	if _owner != account.user_id or account.conflict:
		_notice("Load your account's cloud save before using purchased coins.")
		return
	var uploaded: Dictionary = await account.upload(_snapshot())
	if uploaded.has("error"):
		return
	account.busy = true
	var request_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var result: Dictionary = await account.api("/v1/wallet/spend",HTTPClient.METHOD_POST,{"kind":kind,"revision":account.revision,"requestId":request_id})
	account.busy = false
	if result.has("error"):
		# A lost response may hide a successful debit. Stop uploads until a download reconciles it.
		account.conflict = true
		account._save_session()
		_notice(str(result.error) + " Load cloud progress before trying again.")
	else:
		_apply(result)

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
