extends Node
class_name Purchase

# =========================================================
# PURPOSE
# =========================================================
# Represents a single purchase transaction.
#
# Rules:
# - Data only
# - No gameplay logic
# - No validation
# - No inventory modification
# - No currency deduction
# - No reward handling
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _item: String = ""
var _currency: String = ""
var _price: int = 0
var _quantity: int = 1


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	clear()


func clear() -> void:
	_item = ""
	_currency = ""
	_price = 0
	_quantity = 1


# =========================================================
# DATA
# =========================================================

func set_item(id: String) -> void:
	_item = id


func get_item() -> String:
	return _item


func set_currency(currency: String) -> void:
	_currency = currency


func get_currency() -> String:
	return _currency


func set_price(price: int) -> void:
	_price = max(0, price)


func get_price() -> int:
	return _price


func set_quantity(quantity: int) -> void:
	_quantity = max(1, quantity)


func get_quantity() -> int:
	return _quantity
