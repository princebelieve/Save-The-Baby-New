extends Node
class_name PlayerInventory

# =========================================================
# PURPOSE
# =========================================================
# Stores persistent player-owned resources (except lives)
# - Coins
# - Stars
# - Gold Bars (premium currency placeholder)
#
# Rules:
# - No gameplay logic
# - No shop logic
# - No reward logic
# - No save logic
# - No coordination
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _coins: int = 0
var _stars: int = 0
var _gold_bars: int = 0


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


func reset() -> void:
	clear()


func clear() -> void:
	_coins = 0
	_stars = 0
	_gold_bars = 0


# =========================================================
# COINS
# =========================================================

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	_coins += amount


func remove_coins(amount: int) -> void:
	if amount <= 0:
		return
	_coins = max(0, _coins - amount)


func set_coins(amount: int) -> void:
	_coins = max(0, amount)


func get_coins() -> int:
	return _coins


func has_coins(amount: int) -> bool:
	return _coins >= amount


# =========================================================
# STARS
# =========================================================

func add_stars(amount: int) -> void:
	if amount <= 0:
		return
	_stars += amount


func remove_stars(amount: int) -> void:
	if amount <= 0:
		return
	_stars = max(0, _stars - amount)


func set_stars(amount: int) -> void:
	_stars = max(0, amount)


func get_stars() -> int:
	return _stars


func has_stars(amount: int) -> bool:
	return _stars >= amount


# =========================================================
# GOLD BARS (PREMIUM CURRENCY)
# =========================================================

func add_gold_bars(amount: int) -> void:
	if amount <= 0:
		return
	_gold_bars += amount


func remove_gold_bars(amount: int) -> void:
	if amount <= 0:
		return
	_gold_bars = max(0, _gold_bars - amount)


func set_gold_bars(amount: int) -> void:
	_gold_bars = max(0, amount)


func get_gold_bars() -> int:
	return _gold_bars


func has_gold_bars(amount: int) -> bool:
	return _gold_bars >= amount


# =========================================================
# UTILITY
# =========================================================

func duplicate_inventory() -> Dictionary:
	return {
		"coins": _coins,
		"stars": _stars,
		"gold_bars": _gold_bars
	}