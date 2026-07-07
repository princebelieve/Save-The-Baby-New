extends Node
class_name EconomyAnimator

# =========================================================
# PURPOSE
# =========================================================
# Owns all economy-related animations.
#
# Rules:
# - No gameplay logic
# - No reward logic
# - No UI flow
# - Only animation execution
#
# AnimationManager decides WHEN.
# This class decides HOW.
# =========================================================


var _active: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_active.clear()


# =========================================================
# CURRENCY
# =========================================================

func play_coin_gain() -> void:
	_execute("coin_gain")


func play_coin_spend() -> void:
	_execute("coin_spend")


func play_star_gain() -> void:
	_execute("star_gain")


func play_gold_bar_gain() -> void:
	_execute("gold_bar_gain")


# =========================================================
# LIVES
# =========================================================

func play_life_gain() -> void:
	_execute("life_gain")


func play_life_loss() -> void:
	_execute("life_loss")


func play_unlimited_lives_start() -> void:
	_execute("unlimited_lives_start")


func play_unlimited_lives_end() -> void:
	_execute("unlimited_lives_end")


# =========================================================
# BOOSTERS
# =========================================================

func play_booster_gain(type: String) -> void:
	_execute("booster_gain_" + type)


func play_booster_use(type: String) -> void:
	_execute("booster_use_" + type)


# =========================================================
# ETHAN
# =========================================================

func play_ethan_gain() -> void:
	_execute("ethan_gain")


func play_ethan_use() -> void:
	_execute("ethan_use")


func play_ethan_suggestion() -> void:
	_execute("ethan_suggestion")


# =========================================================
# SHOP
# =========================================================

func play_purchase_success() -> void:
	_execute("purchase_success")


func play_purchase_failed() -> void:
	_execute("purchase_failed")


# =========================================================
# UTILITY
# =========================================================

func stop(target) -> void:
	if _active.has(target):
		_active.erase(target)


func stop_all() -> void:
	_active.clear()


func pause(target) -> void:
	pass


func resume(target) -> void:
	pass


func is_playing(target) -> bool:
	return _active.has(target)


func wait_until_finished(target) -> void:
	while _active.has(target):
		await get_tree().process_frame


# =========================================================
# INTERNAL
# =========================================================

func _execute(animation_name: String) -> void:
	# Placeholder execution hook
	# In your architecture this will call:
	# AnimationManager -> AnimationRequest -> TweenHelper
	_active[animation_name] = true

	# Simulate completion
	await get_tree().process_frame
	_active.erase(animation_name)


func _complete(animation_name: String) -> void:
	_active.erase(animation_name)