extends Node
class_name RewardPreview

# =========================================================
# PURPOSE
# Creates preview data for UI.
#
# Never grants rewards.
# Never modifies economy.
# =========================================================


# =========================================================
# INTERNAL DEPENDENCIES
# =========================================================

var _reward_table: RewardTable


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_reward_table = RewardTable.new()
	_reward_table.initialize()


# =========================================================
# PREVIEW
# =========================================================

func preview_level_rewards(level):
	return preview_reward_set(
		_reward_table.get_level_rewards(level)
	)


func preview_daily_reward():
	return preview_reward_set(
		_reward_table.get_daily_reward()
	)


func preview_story_reward(id):
	return preview_reward_set(
		_reward_table.get_story_reward(id)
	)


func preview_chest_reward(id):
	return preview_reward_set(
		_reward_table.get_chest_reward(id)
	)


func preview_reward_set(rewards):
	if rewards == null:
		return []

	if typeof(rewards) == TYPE_ARRAY:
		return rewards.duplicate(true)

	if typeof(rewards) == TYPE_DICTIONARY:
		return rewards.duplicate(true)

	return rewards