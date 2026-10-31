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
	_reward_config = ConfigLoader.get_config(Constants.ConfigPaths.REWARDS)


func clear() -> void:
	_reward_config.clear()


# =========================================================
# LOOKUP
# =========================================================

func get_level_rewards(level):
	return _get_table_entry("levels", level)


func get_star_rewards(stars):
	return _get_table_entry("stars", stars)


func get_daily_reward():
	return _reward_config.get("daily", [])


func get_story_reward(id):
	return _get_table_entry("stories", id)


func get_chest_reward(id):
	return _get_table_entry("chests", id)


func get_bonus_rewards():
	return _reward_config.get("bonus", [])


func get_special_move_config() -> Dictionary:
	return _reward_config.get("special_move", {})


func get_random_pool(pool):
	return _get_table_entry("random_pools", pool)


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
	var key := str(id)
	var levels: Dictionary = _reward_config.get("levels", {})
	if levels.has(key):
		return levels[key]
	var stories: Dictionary = _reward_config.get("stories", {})
	if stories.has(key):
		return stories[key]
	return _reward_config.get(key, {})


func _get_table_entry(table_name: String, id) -> Variant:
	if id == null:
		return {}
	var table: Dictionary = _reward_config.get(table_name, {})
	return table.get(str(id), table.get(id, {}))
