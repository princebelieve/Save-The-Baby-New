extends Node
class_name EconomyManager

signal coins_changed(coins)
signal lives_changed(lives)
signal boosters_changed(boosters)
signal stars_changed(stars)

var _coins: PlayerInventory
var _lives: LifeSystem
var _stars: PlayerInventory
var _boosters: BoosterInventory
var _unlimited_lives_timer: LifeSystem


func initialize() -> void:
	_coins = PlayerInventory.new()
	_coins.initialize()

	_lives = LifeSystem.new()
	_lives.initialize()

	_stars = _coins

	_boosters = BoosterInventory.new()
	_boosters.initialize()

	_unlimited_lives_timer = _lives


func add_coins(amount: int) -> void:
	_coins.add_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func remove_coins(amount: int) -> void:
	_coins.remove_coins(amount)
	emit_signal("coins_changed", _coins.get_coins())


func get_coins() -> int:
	return _coins.get_coins()


func add_life(amount: int = 1) -> void:
	_lives.add_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func lose_life(amount: int = 1) -> void:
	_lives.lose_life(amount)
	emit_signal("lives_changed", _lives.get_lives())


func get_lives() -> int:
	return _lives.get_lives()


func restore_full_lives() -> void:
	_lives.restore_full_lives()
	emit_signal("lives_changed", _lives.get_lives())


func start_unlimited_lives(duration: float) -> void:
	_unlimited_lives_timer.start_unlimited_lives(duration)
	emit_signal("lives_changed", _lives.get_lives())


func has_unlimited_lives() -> bool:
	return _unlimited_lives_timer.has_unlimited_lives()


func add_booster(type: String, amount: int) -> void:
	_boosters.add_booster(type, amount)
	emit_signal("boosters_changed", _boosters.get_all_boosters())


func use_booster(type: String) -> void:
	_boosters.use_booster(type)
	emit_signal("boosters_changed", _boosters.get_all_boosters())


func get_booster_count(type: String) -> int:
	return _boosters.get_booster_count(type)


func add_stars(amount: int) -> void:
	_stars.add_stars(amount)
	emit_signal("stars_changed", _stars.get_stars())


func get_stars() -> int:
	return _stars.get_stars()


func can_afford(cost: Purchase) -> bool:
	var validator := EconomyValidator.new()
	validator.initialize()

	return validator.can_afford(_coins, cost)


func purchase(cost: Purchase) -> bool:
	var validator := EconomyValidator.new()
	validator.initialize()

	if not validator.can_afford(_coins, cost):
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


func update_life_timer() -> void:
	_lives.update()

	emit_signal("lives_changed", _lives.get_lives())