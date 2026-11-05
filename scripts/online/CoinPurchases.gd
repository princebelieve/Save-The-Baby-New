extends Node

signal changed
signal message(text: String)
const PRODUCTS := {"coins_500":500,"coins_1500":1500,"coins_3500":3500}
const PENDING_PATH := "user://pending_purchases.cfg"
var products: Dictionary = {}
var busy := false
var _billing: BillingClient
var _pending: Dictionary = {}
var _verifying := false
var _server_enabled := false
var _checking_catalog := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	var saved := ConfigFile.new()
	if saved.load(PENDING_PATH) == OK:
		_pending = saved.get_value("purchases","pending",{})
	if OS.get_name() != "Android" or not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_billing = BillingClient.new()
	add_child(_billing)
	_billing.connected.connect(_on_connected)
	_billing.connect_error.connect(func(_code: int,_debug: String):
		busy = false
		message.emit("Google Play billing is unavailable. Please try again later.")
	)
	_billing.disconnected.connect(func(): changed.emit())
	_billing.query_product_details_response.connect(_on_products)
	_billing.query_purchases_response.connect(_on_purchases)
	_billing.on_purchase_updated.connect(_on_purchases)
	_billing.start_connection()
	var retry := Timer.new()
	retry.wait_time = 60.0
	retry.timeout.connect(restore)
	add_child(retry)
	retry.start()
	get_node("/root/CloudAccount").changed.connect(_account_changed)

func _account_changed() -> void:
	var account := get_node("/root/CloudAccount")
	if _billing != null and _billing.is_ready() and account.signed_in():
		_billing.set_obfuscated_account_id(account.billing_account)
		_verify_pending()
	if account.signed_in():
		_refresh_catalog()
	else:
		_server_enabled = false
	changed.emit()

func _refresh_catalog() -> void:
	if _checking_catalog:
		return
	_checking_catalog = true
	var account := get_node("/root/CloudAccount")
	var owner: String = account.user_id
	var response: Dictionary = await account.api("/v1/catalog")
	_server_enabled = owner == account.user_id and account.signed_in() and bool(response.get("commerceEnabled",false))
	_checking_catalog = false
	changed.emit()

func _on_connected() -> void:
	_billing.query_product_details(PackedStringArray(PRODUCTS.keys()),BillingClient.ProductType.INAPP)
	_account_changed()
	restore()

func _on_products(response: Dictionary) -> void:
	products = {}
	if int(response.get("response_code",-1)) == BillingClient.BillingResponseCode.OK:
		for product in response.get("product_details",[]):
			var offers: Variant = product.get("one_time_purchase_offer_details_list",[])
			if offers is Array and not offers.is_empty():
				products[str(product.product_id)] = offers[0]
	changed.emit()

func available(product: String) -> bool:
	var account := get_node("/root/CloudAccount")
	return _server_enabled and not busy and account.configured() and account.signed_in() and _billing != null and _billing.is_ready() and products.has(product)

func buy(product: String) -> void:
	if not available(product):
		message.emit("Sign in and connect to Google Play to buy coins.")
		return
	var account := get_node("/root/CloudAccount")
	_billing.set_obfuscated_account_id(account.billing_account)
	busy = true
	var offer: Dictionary = products[product]
	var option_id: Variant = offer.get("purchase_option_id")
	var offer_id: Variant = offer.get("offer_id")
	var response := _billing.purchase(product,str(option_id) if option_id != null else "",str(offer_id) if offer_id != null else "")
	if int(response.get("response_code",-1)) != BillingClient.BillingResponseCode.OK:
		busy = false
		message.emit("Google Play could not start the purchase. No coins were added.")
	changed.emit()

func restore() -> void:
	if _billing == null:
		return
	if not _billing.is_ready():
		_billing.start_connection()
		return
	_billing.query_purchases(BillingClient.ProductType.INAPP)
	_verify_pending()

func _on_purchases(response: Dictionary) -> void:
	busy = false
	if int(response.get("response_code",-1)) != BillingClient.BillingResponseCode.OK:
		message.emit("Purchase canceled or unavailable. No coins were added.")
		changed.emit()
		return
	for purchase in response.get("purchases",[]):
		if int(purchase.get("purchase_state",0)) == BillingClient.PurchaseState.PENDING:
			message.emit("Payment pending. Coins will arrive after Google confirms payment.")
			continue
		if int(purchase.get("purchase_state",0)) != BillingClient.PurchaseState.PURCHASED:
			continue
		var ids: Variant = purchase.get("product_ids",[])
		if ids.size() == 1 and PRODUCTS.has(str(ids[0])):
			_pending[str(purchase.purchase_token)] = str(ids[0])
	_save_pending()
	_verify_pending()
	changed.emit()

func _verify_pending() -> void:
	var account := get_node("/root/CloudAccount")
	if _verifying or not account.signed_in():
		return
	_verifying = true
	for purchase_token in _pending.keys():
		var owner: String = account.user_id
		var response: Dictionary = await account.api("/v1/purchases/google",HTTPClient.METHOD_POST,{"productId":_pending[purchase_token],"purchaseToken":purchase_token})
		if owner != account.user_id:
			break
		if not response.has("error"):
			_pending.erase(purchase_token)
			_save_pending()
			account.wallet = int(response.wallet)
			account._save_session()
			account.changed.emit()
			message.emit("Purchased coin balance updated.")
		else:
			message.emit(str(response.error))
	_verifying = false
	changed.emit()

func _save_pending() -> void:
	var saved := ConfigFile.new()
	saved.set_value("purchases","pending",_pending)
	CampaignProgressStore.write(saved,PENDING_PATH)
