extends Node
class_name RewardValidator

# =========================================================
# PURPOSE
# Validates reward definitions before they are granted.
#
# Ensures rewards are legal.
# Performs no economy updates.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _validation_rules: Dictionary = {}


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_validation_rules.clear()


# =========================================================
# VALIDATION
# =========================================================

func validate_reward(reward) -> bool:
	if typeof(reward) != TYPE_DICTIONARY:
		return false

	if not reward.has("type"):
		return false

	if not reward.has("amount"):
		return false

	if not validate_reward_type(reward["type"]):
		return false

	if not validate_amount(reward["type"], reward["amount"]):
		return false

	return is_claimable(reward)


func validate_reward_list(rewards) -> bool:
	if typeof(rewards) != TYPE_ARRAY:
		return false

	for reward in rewards:
		if not validate_reward(reward):
			return false

	return true


func validate_reward_type(type) -> bool:
	return type != null


func validate_amount(type, amount) -> bool:
	if typeof(amount) != TYPE_INT:
		return false

	return amount >= 0


func is_claimable(reward) -> bool:
	if typeof(reward) != TYPE_DICTIONARY:
		return false

	return true