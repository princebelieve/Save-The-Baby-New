extends Node

var game: Game
var _layer: CanvasLayer
var _dialog: AcceptDialog
var _content: VBoxContainer
var _catalog: Dictionary = {}
var _busy := false
var _board: Board
var _was_locked := true
var _focus := ""
var _status := ""
var _packs_only := false
var _catalog_loading := false

const ITEMS := {"life":"life", "lives":"life_refill", "rocket":"rocket_booster", "bomb":"bomb_booster", "thunder":"thunder_booster", "ethan":"ethan_assist", "continue":"continue"}

func open(current_game: Game, focus := "") -> void:
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		current_game._show_shop_notice("Use DEV TOOLS to refill test lives and boosters. Purchases are disabled in Developer Play.")
		return
	if is_instance_valid(_layer):
		return
	game = current_game
	_focus = focus
	_status = ""
	_catalog = {}
	_packs_only = false
	_board = game._board
	if is_instance_valid(_board) and not _board.is_stable():
		game._show_shop_notice("Let the current move finish before opening the shop.")
		return
	_was_locked = not is_instance_valid(_board) or _board.is_locked()
	if is_instance_valid(_board):
		_board.lock()
	_layer = CanvasLayer.new()
	_layer.layer = 24
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	game.add_child(_layer)
	_layer.tree_exiting.connect(func():
		if is_instance_valid(_board) and not _was_locked:
			_board.unlock())
	_dialog = AcceptDialog.new()
	_dialog.set_meta("custom_heading",true)
	game._prepare_dialog(_dialog)
	_dialog.title = ""
	_dialog.dialog_hide_on_ok = false
	_dialog.ok_button_text = "BACK TO GAME"
	_dialog.confirmed.connect(_close)
	_dialog.canceled.connect(_close)
	_layer.add_child(_dialog)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(minf(600,game.get_viewport_rect().size.x * 0.83), minf(650,game.get_viewport_rect().size.y * 0.60))
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	_dialog.add_child(scroll)
	get_node("/root/CoinPurchases").changed.connect(_refresh)
	get_node("/root/CloudAccount").changed.connect(_refresh)
	_layer.tree_exiting.connect(func():
		for node in [get_node("/root/CoinPurchases"),get_node("/root/CloudAccount")]:
			if node.changed.is_connected(_refresh):
				node.changed.disconnect(_refresh))
	_refresh()
	_dialog.popup_centered_clamped(Vector2i(mini(650,int(game.get_viewport_rect().size.x * 0.94)),mini(800,int(game.get_viewport_rect().size.y * 0.88))))
	_load_catalog()

func _load_catalog() -> void:
	if _catalog_loading: return
	var account := get_node("/root/CloudAccount")
	if account.signed_in():
		_catalog_loading = true
		_refresh()
		var response: Dictionary = await account.api("/v1/catalog")
		_catalog_loading = false
		if not response.has("error") and int(response.get("shopVersion",0)) >= 2:
			_catalog = response.get("supplies",{})
		else:
			_status = "Online coin spending is updating. Earned coins and free recovery remain available."
		_refresh()

func _text(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color("#4b3424"))
	_content.add_child(label)

func _button(value: String, action: Callable, disabled := false) -> void:
	var button := game._make_menu_button(value)
	button.custom_minimum_size.x = 0
	button.clip_text = true
	button.tooltip_text = value
	button.add_theme_font_size_override("font_size",32)
	button.disabled = disabled or _busy
	button.pressed.connect(action)
	_content.add_child(button)

func _price(kind: String) -> int:
	return int(_catalog.get(kind,game._economy_manager.get_shop_item(ITEMS[kind])).get("price",0))

func _refresh() -> void:
	if not is_instance_valid(_content):
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var account := get_node("/root/CloudAccount")
	var purchases := get_node("/root/CoinPurchases")
	var earned: int = game._economy_manager.get_coins()
	var paid: int = account.wallet if account.signed_in() and game._account_panel._owner == account.user_id and not account.conflict else 0
	var heading := Label.new()
	heading.text = "COIN SHOP"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font",Game.DISPLAY_FONT)
	heading.add_theme_font_size_override("font_size",34)
	heading.add_theme_color_override("font_color",Color("#4b3424"))
	_content.add_child(heading)
	_text("COINS AVAILABLE: %d\nEarned: %d  |  Purchased: %d\nYou can spend both balances here. Earned coins are used first." % [earned+paid,earned,paid])
	if not _status.is_empty():
		_text(_status)
	if _catalog_loading:
		_text("Loading online prices… Earned-coin supplies remain available.")
	if _busy or purchases.processing_purchase():
		_text("Confirming your purchase. Please wait…")
	_dialog.get_ok_button().disabled = _busy or purchases.processing_purchase()
	if _busy or purchases.processing_purchase():
		return
	if _packs_only:
		_button("BACK TO SUPPLIES",func():
			_packs_only = false
			_refresh())
		_show_coin_packs()
		return
	_button("BUY COINS - GOOGLE PLAY",func():
		_packs_only = true
		_refresh())
	var kinds: Array = [_focus] if not _focus.is_empty() and _focus not in ["life","lives"] else (["life","lives"] if _focus in ["life","lives"] else ["life","lives","rocket","bomb","thunder","ethan"])
	for kind in kinds:
		if kind == "continue" and int(game._campaign_progress.get_value("campaign","continue_credits",0)) > 0:
			_button("USE SAVED +5 MOVES",_redeem_continue,not game._can_buy_continue())
			continue
		var item: Dictionary = game._economy_manager.get_shop_item(ITEMS[kind])
		var blocked: bool = (kind in ["life","lives"] and game._economy_manager.get_lives() >= 5) or (kind == "ethan" and game._economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS)
		if kind == "continue" and not game._can_buy_continue():
			blocked = true
		var name := str(item.get("name",kind))
		if kind == "lives":
			name = "Refill to 5 lives"
		_button("%s — %d coins" % [name,_price(kind)],_buy.bind(kind),blocked)
	if _focus == "continue":
		_text("One coin continuation per attempt. Keeps your board and restores the life lost on this failure.")
	else:
		var seconds: int = game._economy_manager.seconds_until_next_life()
		_text("Free recovery: one life every 30 minutes. Next life: %02d:%02d" % [seconds/60,seconds%60])
		if game._economy_manager.get_lives() < 5:
			game._add_reward_offer(_content,"WATCH AD: +1 LIFE","life",func():
				game._economy_manager.add_life(1)
				game._persist_campaign_progress()
				_refresh())
		if _focus in ["rocket","bomb","thunder","ethan"]:
			game._add_reward_offer(_content,"WATCH AD: +1 " + _focus.to_upper(),"supply_" + _focus,func():
				if _focus == "ethan":
					game._economy_manager.add_ethan(1)
				else:
					game._economy_manager.add_booster(_focus,1)
				game._save_inventory_progress()
				_refresh())

func _show_coin_packs() -> void:
	var account := get_node("/root/CloudAccount")
	var purchases := get_node("/root/CoinPurchases")
	_text("BUY COINS — GOOGLE PLAY")
	if not account.signed_in():
		_button("SIGN IN WITH GOOGLE TO BUY COINS",func():
			_close()
			game._account_panel.show_account())
	else:
		if account.conflict or game._account_panel._owner != account.user_id:
			_text("Load this Google account's cloud progress from Account & Coins before using its purchased balance.")
			_button("ACCOUNT & CLOUD SAVE",func():
				_close()
				game._account_panel.show_account())
		for product in purchases.PRODUCTS:
			var price := str(purchases.products.get(product,{}).get("formatted_price","Unavailable"))
			_button("%d COINS — %s" % [purchases.PRODUCTS[product],price],game._account_panel._confirm_purchase.bind(product,price),not purchases.available(product))

func _buy(kind: String) -> void:
	if _busy or (kind == "continue" and not game._can_buy_continue()):
		return
	var confirmation := ConfirmationDialog.new()
	game._prepare_dialog(confirmation)
	confirmation.add_theme_constant_override("buttons_min_width",mini(180,int(game.get_viewport_rect().size.x * 0.30)))
	confirmation.title = "CONFIRM COIN PURCHASE"
	var price := _price(kind)
	confirmation.dialog_text = "Spend %d coins on %s?" % [price,str(game._economy_manager.get_shop_item(ITEMS[kind]).get("name",kind))]
	confirmation.ok_button_text = "SPEND %d COINS" % price
	_dialog.add_child(confirmation)
	confirmation.confirmed.connect(func():
		confirmation.queue_free()
		_complete_buy(kind,price))
	confirmation.canceled.connect(confirmation.queue_free)
	confirmation.popup_centered_clamped(Vector2i(480,220))

func _complete_buy(kind: String, price: int) -> void:
	if _busy or price <= 0 or (kind == "continue" and not game._can_buy_continue()):
		return
	if kind == "continue" and int(game._campaign_progress.get_value("campaign","continue_credits",0)) > 0:
		_redeem_continue()
		return
	if (kind in ["life","lives"] and game._economy_manager.get_lives() >= 5) or (kind == "ethan" and game._economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS):
		_refresh()
		return
	_busy = true
	_refresh()
	var economy := game._economy_manager
	var success := false
	if economy.get_coins() >= price:
		var cost := Purchase.new()
		cost.initialize()
		cost.set_item(ITEMS[kind])
		cost.set_currency("coins")
		cost.set_price(price)
		game._progress_transaction = true
		if economy.purchase(cost):
			var item: Dictionary = economy.get_shop_item(ITEMS[kind])
			if kind in ["life","lives"]:
				economy.add_life(int(item.amount))
			elif kind == "ethan":
				economy.add_ethan(1)
			elif kind == "continue":
				game._campaign_progress.set_value("campaign","continue_credits",int(game._campaign_progress.get_value("campaign","continue_credits",0))+1)
			else:
				economy.add_booster(kind,1)
			success = true
		game._progress_transaction = false
		if success:
			game._save_inventory_progress()
		cost.free()
	else:
		var account := get_node("/root/CloudAccount")
		if _catalog.has(kind) and account.signed_in() and economy.get_coins()+int(account.wallet) >= price:
			success = await game._account_panel.spend_supply(kind,price,true)
		else:
			_status = "Not enough coins. Complete levels, watch an available rewarded ad, or buy a coin pack below."
	_busy = false
	preload("res://scripts/economy/BalanceMetrics.gd").record({"event":"shop_purchase","kind":kind,"price":price,"success":success,"earned_balance":economy.get_coins()})
	if success and kind == "continue":
		game._use_coin_continue()
		_close()
	else:
		if success:
			_status = "Purchase complete. Your supply is ready."
		_refresh()

func show_message(message: String) -> void:
	_status = message
	_refresh()

func _redeem_continue() -> void:
	if not _busy and game._can_buy_continue():
		game._use_coin_continue()
		_close()

func _close() -> void:
	if not _busy and not get_node("/root/CoinPurchases").processing_purchase() and is_instance_valid(_layer):
		_dialog.hide()
		_layer.queue_free()
