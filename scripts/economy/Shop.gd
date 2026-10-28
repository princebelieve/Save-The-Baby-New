extends Node
class_name Shop

# =========================================================
# PURPOSE
# =========================================================
# Provides read-only access to shop catalogue data.
#
# Loads from configs/economy.json via ConfigLoader.
#
# Rules:
# - No currency deduction
# - No inventory modification
# - No reward logic
# - No gameplay logic
# - Lookup only
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _shop_cache: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reload()


func reload() -> void:
	_shop_cache.clear()

	var data: Dictionary = ConfigLoader.load(Constants.ConfigPaths.ECONOMY)

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Shop: Invalid economy config format")
		return

	# Expecting structure:
	# {
	#   "items": {
	#       "item_id": { price, currency, category, ... }
	#   }
	# }

	if data.has("items") and typeof(data["items"]) == TYPE_DICTIONARY:
		_shop_cache = data["items"]
	else:
		_shop_cache = {}


# =========================================================
# LOOKUP API
# =========================================================

func get_item(id: String) -> Dictionary:
	if _shop_cache.has(id):
		return _shop_cache[id]

	return {}


func has_item(id: String) -> bool:
	return _shop_cache.has(id)


func get_price(id: String) -> int:
	var item := get_item(id)

	if item.has("price"):
		return item["price"]

	return 0


func get_currency(id: String) -> String:
	var item := get_item(id)

	if item.has("currency"):
		return item["currency"]

	return ""


func get_category(id: String) -> String:
	var item := get_item(id)

	if item.has("category"):
		return item["category"]

	return ""


func get_all_items() -> Dictionary:
	return _shop_cache.duplicate(true)
