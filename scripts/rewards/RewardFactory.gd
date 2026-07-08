extends Node
class_name RewardFactory

# =========================================================
# PURPOSE
# Creates standardized RewardData objects.
#
# Ensures all rewards share the same structure.
# Performs no calculations.
# =========================================================


# =========================================================
# CREATION
# =========================================================

func create_reward(type, amount) -> RewardData:
	var reward := RewardData.new()
	reward.type = type
	reward.amount = amount
	return reward


func create_coin_reward(amount) -> RewardData:
	return create_reward(Constants.RewardType.COINS, amount)


func create_star_reward(amount) -> RewardData:
	return create_reward(Constants.RewardType.STARS, amount)


func create_life_reward(amount) -> RewardData:
	return create_reward(Constants.RewardType.LIVES, amount)


func create_booster_reward(type, amount) -> RewardData:
	var reward := create_reward(Constants.RewardType.BOOSTER, amount)
	reward.data = {
		"booster_type": type
	}
	return reward


func create_custom_reward(data) -> RewardData:
	var reward := RewardData.new()

	if typeof(data) == TYPE_DICTIONARY:
		if data.has("type"):
			reward.type = data["type"]

		if data.has("amount"):
			reward.amount = data["amount"]

		reward.data = data.duplicate(true)

	return reward