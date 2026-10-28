extends Control
class_name HUD

# =========================================================
# PURPOSE
# =========================================================
# Displays live gameplay information:
# moves, score, objectives, coins, lives, boosters.
#
# NO gameplay logic.
# ONLY display + update values.

# =========================================================
# STATE
# =========================================================

var _moves: int = 0
var _score: int = 0
var _objectives: Dictionary = {}
var _coins: int = 0
var _lives: int = 0
var _boosters: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


# =========================================================
# MOVES
# =========================================================

func set_moves(value: int) -> void:
	_moves = value
	update_moves(value)


func get_moves() -> int:
	return _moves


func update_moves(value: int) -> void:
	_moves = value
	# UI update hook (Label etc.)
	# $MovesLabel.text = str(_moves)


# =========================================================
# SCORE
# =========================================================

func set_score(value: int) -> void:
	_score = value
	update_score(value)


func get_score() -> int:
	return _score


func add_score(points: int) -> void:
	_score += points
	update_score(_score)


func update_score(value: int) -> void:
	_score = value
	# $ScoreLabel.text = str(_score)


# =========================================================
# OBJECTIVES
# =========================================================

func set_objectives(objectives: Dictionary) -> void:
	_objectives = objectives


func update_objective(id: String, progress: int) -> void:
	if _objectives.has(id):
		_objectives[id] = progress


func complete_objective(id: String) -> void:
	if _objectives.has(id):
		_objectives[id] = -1


func get_objectives() -> Dictionary:
	return _objectives


# =========================================================
# ECONOMY
# =========================================================

func set_coins(value: int) -> void:
	_coins = value
	update_coins(value)


func update_coins(value: int) -> void:
	_coins = value
	# $CoinsLabel.text = str(_coins)


func set_lives(value: int) -> void:
	_lives = value
	update_lives(value)


func update_lives(value: int) -> void:
	_lives = value
	# $LivesLabel.text = str(_lives)


func set_boosters(boosters: Dictionary) -> void:
	_boosters = boosters


func update_booster(type: String, amount: int) -> void:
	_boosters[type] = amount


# =========================================================
# POWERUPS
# =========================================================

func show_powerup(type: String) -> void:
	pass


func hide_powerup(type: String) -> void:
	pass


func update_powerup_count(type: String, amount: int) -> void:
	pass


# =========================================================
# UTILITY
# =========================================================

func show_message(text: String) -> void:
	# $MessageLabel.text = text
	pass


func clear_message() -> void:
	# $MessageLabel.text = ""
	pass


func reset() -> void:
	_moves = 0
	_score = 0
	_objectives.clear()
	_coins = 0
	_lives = 0
	_boosters.clear()
