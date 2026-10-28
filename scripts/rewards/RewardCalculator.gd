extends Node
class_name RewardCalculator

# =========================================================
# PURPOSE
# Calculates rewards earned from gameplay.
# Uses RewardTable for reward definitions.
# Validates rewards before returning them.
# Performs no UI, economy, save, or gameplay progression.
# =========================================================


# =========================================================
# INTERNAL DEPENDENCIES
# =========================================================

var _reward_table: RewardTable
var _validator: RewardValidator


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_reward_table = RewardTable.new()
	_reward_table.initialize()

	_validator = RewardValidator.new()
	_validator.initialize()


# =========================================================
# LEVEL REWARDS
# =========================================================

func calculate_level_rewards(result) -> Array:
	if result == null:
		return []

	var level := _extract_level(result)

	var rewards = _reward_table.get_level_rewards(level)

	return calculate_reward_set("level", rewards)


func calculate_bonus_rewards(result) -> Array:
	if result == null:
		return []

	var rewards = _reward_table.get_bonus_rewards()

	return calculate_reward_set("bonus", rewards)


# =========================================================
# STORY
# =========================================================

func calculate_story_rewards(story_id) -> Array:
	if story_id == null:
		return []

	var rewards = _reward_table.get_story_reward(story_id)

	return calculate_reward_set("story", rewards)


# =========================================================
# DAILY
# =========================================================

func calculate_daily_reward() -> Array:
	var rewards = _reward_table.get_daily_reward()

	return calculate_reward_set("daily", rewards)


# =========================================================
# CHESTS
# =========================================================

func calculate_chest_reward(chest_id) -> Array:
	if chest_id == null:
		return []

	var rewards = _reward_table.get_chest_reward(chest_id)

	return calculate_reward_set("chest", rewards)


# =========================================================
# GENERIC
# =========================================================

func calculate_reward_set(type: String, data) -> Array:
	if data == null:
		return []

	var rewards: Array = []

	match typeof(data):
		TYPE_ARRAY:
			rewards = data.duplicate(true)

		TYPE_DICTIONARY:
			rewards.append(data.duplicate(true))

		_:
			return []

	if not _validator.validate_reward_list(rewards):
		return []
	return rewards


# =========================================================
# INTERNAL HELPERS
# =========================================================

func _extract_level(result) -> int:
	if result == null:
		return 0

	if typeof(result) == TYPE_DICTIONARY:
		return int(result.get("level", 0))

	if result.has_method("get_level"):
		return int(result.get_level())

	if "level" in result:
		return int(result.level)

	return 0
