extends Node
class_name EconomyValidator

# =========================================================
# PURPOSE
# =========================================================
# Validates economy operations only.
#
# Rules:
# - No inventory modification
# - No purchase execution
# - No reward granting
# - No side effects
# - Pure validation logic only
# =========================================================


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	pass


# =========================================================
# CORE VALIDATION
# =========================================================

func can_afford(inventory: Object, purchase: Object) -> bool:
	if inventory == null or purchase == null:
		return false

	var currency := purchase.get_currency()
	var price := purchase.get_price()
	var quantity := purchase.get_quantity()

	var total_cost := price * quantity

	match currency:
		"coins":
			return inventory.has_coins(total_cost)
		"stars":
			return inventory.has_stars(total_cost)
		"gold_bars":
			return inventory.has_gold_bars(total_cost)
		_:
			return false


func can_use_booster(inventory: Object, type: String) -> bool:
	if inventory == null:
		return false

	return inventory.has_booster(type)


func can_use_ethan(inventory: Object) -> bool:
	if inventory == null:
		return false

	return inventory.has_ethan()


func can_lose_life(life_system: Object) -> bool:
	if life_system == null:
		return false

	return life_system.has_lives()


# =========================================================
# PURCHASE VALIDATION
# =========================================================

func validate_purchase(purchase: Object) -> bool:
	if purchase == null:
		return false

	if purchase.get_item() == "":
		return false

	if purchase.get_price() < 0:
		return false

	if purchase.get_quantity() <= 0:
		return false

	var currency := purchase.get_currency()

	return currency == "coins" \
		or currency == "stars" \
		or currency == "gold_bars"


# =========================================================
# INVENTORY VALIDATION
# =========================================================

func validate_inventory(inventory: Object) -> bool:
	if inventory == null:
		return false

	# Basic safety checks — ensure expected methods exist
	return inventory.has_method("get_coins") \
		and inventory.has_method("get_stars") \
		and inventory.has_method("get_gold_bars")
