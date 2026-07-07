extends Node
class_name EconomyManager

signal coins_changed(coins)
signal lives_changed(lives)
signal boosters_changed(boosters)
signal stars_changed(stars)

var _coins: PlayerInventory
var _stars: PlayerInventory
var _lives: LifeSystem
var _boosters: BoosterInventory
var _validator: EconomyValidator


func initialize() -> void:
	_coins = PlayerInventory.new()
	_coins.initialize()

	_stars = PlayerInventory.new()
	_stars.initialize()

	_lives = LifeSystem.new()
	_lives.initialize()

	_boosters = BoosterInventory.new()
	_boosters.initialize()

	_validator = EconomyValidator.new()
	_validator.initialize()


# ---------------- COINS ----------------

func add_coins(amount: int) -> void:
	_coins.add_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func remove_coins(amount: int) -> void:
	_coins.remove_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func get_coins() -> int:
	return _coins.get_coins()


# ---------------- STARS ----------------

func add_stars(amount: int) -> void:
	_stars.add_stars(amount)
	emit_signal("stars_changed", _stars.get_stars())


func get_stars() -> int:
	return _stars.get_stars()


# ---------------- LIVES ----------------

func add_life(amount: int = 1) -> void:
	_lives.add_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func lose_life(amount: int = 1) -> void:
	_lives.lose_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func get_lives() -> int:
	return _lives.get_lives()


func update_life_timer() -> void:
	_lives.update()
	emit_signal("lives_changed", _lives.get_lives())


# ---------------- BOOSTERS ----------------

func add_booster(type: String, amount: int) -> void:
	_boosters.add_booster(type, amount)
	emit_signal("boosters_changed", _boosters.get_all_boosters())


func use_booster(type: String) -> void:
	_boosters.use_booster(type)
	emit_signal("boosters_changed", _boosters.get_all_boosters())


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