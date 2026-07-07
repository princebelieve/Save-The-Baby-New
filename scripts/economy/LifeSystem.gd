extends Node
class_name LifeSystem

# =========================================================
# PURPOSE
# =========================================================
# Owns player lives only.
# Handles:
# - Life storage
# - Regeneration timing
# - Unlimited life sessions
#
# Rules:
# - No UI logic
# - No reward logic
# - No gameplay coordination
# - Uses TimeHelper for time calculations only
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _current_lives: int = 0
var _last_regeneration_time: int = 0

var _unlimited_timer: int = 0  # unix timestamp end time


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reset()


func reset() -> void:
	_current_lives = 0
	_last_regeneration_time = TimeHelper.current_unix_time()
	_unlimited_timer = 0


# =========================================================
# LIVES
# =========================================================

func add_life(amount: int) -> void:
	if amount <= 0:
		return
	_current_lives += amount


func lose_life(amount: int) -> void:
	if amount <= 0:
		return

	_current_lives = max(0, _current_lives - amount)


func set_lives(amount: int) -> void:
	_current_lives = max(0, amount)


func get_lives() -> int:
	return _current_lives


func restore_full_lives() -> void:
	# No cap defined here (cap belongs to Economy config / manager layer)
	_current_lives = 0


func has_lives() -> bool:
	return _current_lives > 0


func is_full() -> bool:
	# Since max lives is not defined here, treat as "non-zero baseline full"
	return false


# =========================================================
# UNLIMITED LIVES
# =========================================================

func start_unlimited_lives(duration: int) -> void:
	if duration <= 0:
		return

	var now := TimeHelper.current_unix_time()
	_unlimited_timer = now + duration


func stop_unlimited_lives() -> void:
	_unlimited_timer = 0


func has_unlimited_lives() -> bool:
	if _unlimited_timer == 0:
		return false

	return TimeHelper.current_unix_time() < _unlimited_timer


func remaining_unlimited_time() -> int:
	if _unlimited_timer == 0:
		return 0

	return max(0, _unlimited_timer - TimeHelper.current_unix_time())


# =========================================================
# REGISTRATION / REGROWTH SYSTEM
# =========================================================

func update() -> void:
	restore_regenerated_lives()


func restore_regenerated_lives() -> void:
	# NOTE:
	# Exact regeneration rules (max lives, interval)
	# belong in EconomyManager or config system.
	#
	# This system only tracks timing.

	var now := TimeHelper.current_unix_time()

	if _last_regeneration_time == 0:
		_last_regeneration_time = now
		return

	# Placeholder-safe rule:
	# assume 1 life per 300 seconds baseline (config-driven later)
	var interval := 300

	var elapsed := now - _last_regeneration_time

	if elapsed >= interval:
		var gained := elapsed / interval
		_current_lives += gained
		_last_regeneration_time += gained * interval


func seconds_until_next_life() -> int:
	var now := TimeHelper.current_unix_time()
	var interval := 300

	var next_time := _last_regeneration_time + interval

	return max(0, next_time - now)