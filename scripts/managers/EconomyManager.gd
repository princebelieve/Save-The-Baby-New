extends Node
class_name EconomyManager

signal coins_changed(coins)
signal lives_changed(lives)
signal boosters_changed(boosters)
signal stars_changed(stars)
signal ethan_changed(count)

var _coins: PlayerInventory
var _stars: PlayerInventory
var _lives: LifeSystem
var _boosters: BoosterInventory
var _ethan: EthanInventory
var _validator: EconomyValidator
var _shop: Shop


func _ready() -> void:
	initialize()


func _process(_delta: float) -> void:
	update_life_timer()


func initialize() -> void:
	if _coins != null:
		return
	_coins = PlayerInventory.new()
	_coins.initialize()

	_stars = PlayerInventory.new()
	_stars.initialize()

	_lives = LifeSystem.new()
	_lives.initialize()

	_boosters = BoosterInventory.new()
	_boosters.initialize()
	_ethan = EthanInventory.new()
	_ethan.initialize()

	_validator = EconomyValidator.new()
	_validator.initialize()
	_shop = Shop.new()
	_shop.initialize()


# ---------------- COINS ----------------

func add_coins(amount: int) -> void:
	_coins.add_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func remove_coins(amount: int) -> void:
	_coins.remove_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func get_coins() -> int:
	return _coins.get_coins()


func set_coins(amount: int) -> void:
	_coins.set_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


# ---------------- STARS ----------------

func add_stars(amount: int) -> void:
	_stars.add_stars(amount)
	emit_signal("stars_changed", _stars.get_stars())


func get_stars() -> int:
	return _stars.get_stars()


func set_stars(amount: int) -> void:
	_stars.set_stars(amount)
	emit_signal("stars_changed", _stars.get_stars())


# ---------------- LIVES ----------------

func add_life(amount: int = 1) -> void:
	_lives.add_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func lose_life(amount: int = 1) -> void:
	_lives.lose_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func get_lives() -> int:
	return _lives.get_lives()


func set_lives(amount: int) -> void:
	_lives.set_lives(amount)
	emit_signal("lives_changed", _lives.get_lives())


func update_life_timer() -> void:
	var previous_lives := _lives.get_lives()
	_lives.update()
	if _lives.get_lives() != previous_lives:
		emit_signal("lives_changed", _lives.get_lives())


# ---------------- BOOSTERS ----------------

func add_booster(type: String, amount: int) -> void:
	_boosters.add_booster(type, amount)
	emit_signal("boosters_changed", _boosters.get_all_boosters())


func use_booster(type: String) -> void:
	if _boosters.use_booster(type):
		emit_signal("boosters_changed", _boosters.get_all_boosters())


func get_booster_count(type: String) -> int:
	return _boosters.get_booster_count(type)


func set_booster_count(type: String, amount: int) -> void:
	_boosters.remove_booster(type, _boosters.get_booster_count(type))
	_boosters.add_booster(type, maxi(0, amount))
	emit_signal("boosters_changed", _boosters.get_all_boosters())


func add_ethan(amount: int = 1) -> void:
	_ethan.add_ethan(amount)
	emit_signal("ethan_changed", _ethan.get_ethan_count())


func use_ethan() -> bool:
	if not _ethan.use_ethan():
		return false
	emit_signal("ethan_changed", _ethan.get_ethan_count())
	return true


func get_ethan_count() -> int:
	return _ethan.get_ethan_count()


func set_ethan_count(amount: int) -> void:
	_ethan.reset()
	_ethan.add_ethan(maxi(0, amount))
	emit_signal("ethan_changed", _ethan.get_ethan_count())


# ---------------- PURCHASE ----------------

func can_afford(cost: Purchase) -> bool:
	return _validator.can_afford(_coins, cost)


func purchase(cost: Purchase) -> bool:
	if not _validator.can_afford(_coins, cost):
		return false

	match cost.get_currency():
		"coins":
			_coins.remove_coins(cost.get_price())
			emit_signal("coins_changed", _coins.get_coins())

		"stars":
			_stars.remove_stars(cost.get_price())
			emit_signal("stars_changed", _stars.get_stars())

		_:
			return false

	return true


func get_shop_item(item_id: String) -> Dictionary:
	return _shop.get_item(item_id) if _shop != null else {}
