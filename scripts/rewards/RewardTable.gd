extends Node
class_name RewardTable

# =========================================================
# PURPOSE
# Provides access to reward definitions stored in
# configs/rewards.json.
#
# Performs no calculations.
# Performs no randomness.
# Acts as the read-only data source for the Reward System.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _reward_config: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	reload()


func reload() -> void:
	clear()
	_reward_config = ConfigLoader.get(Constants.ConfigPaths.REWARDS)


func clear() -> void:
	_reward_config.clear()


# =========================================================
# LOOKUP
# =========================================================

func get_level_rewards(level):
	return _get_entry(level)


func get_star_rewards(stars):
	return _get_entry(stars)


func get_daily_reward():
	return _get_entry("daily")


func get_story_reward(id):
	return _get_entry(id)


func get_chest_reward(id):
	return _get_entry(id)


func get_bonus_rewards():
	return _get_entry("bonus")


func get_random_pool(pool):
	return _get_entry(pool)


# =========================================================
# COLLECTIONS
# =========================================================

func get_all_rewards() -> Dictionary:
	return _reward_config


func get_reward(id) -> Dictionary:
	return _get_entry(id)


func get_reward_ids() -> Array:
	return _reward_config.keys()


func get_reward_values() -> Array:
	return _reward_config.values()


# =========================================================
# VALIDATION
# =========================================================

func has_reward(id) -> bool:
	return _reward_config.has(id)


func is_empty() -> bool:
	return _reward_config.is_empty()


# =========================================================
# INTERNAL HELPERS
# =========================================================

func _get_entry(id):
	if id == null:
		return {}

	return _reward_config.get(id, {})