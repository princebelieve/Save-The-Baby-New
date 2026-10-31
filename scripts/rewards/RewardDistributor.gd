extends Node
class_name RewardDistributor

# =========================================================
# PURPOSE
# Converts validated rewards into economy operations.
#
# Does not own player inventory.
# Does not calculate rewards.
#
# RewardManager calls this class after calculation.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _economy_manager


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(economy_manager = null) -> void:
	_economy_manager = economy_manager


# =========================================================
# DISTRIBUTION
# =========================================================

func grant_reward(reward) -> void:
	if typeof(reward) != TYPE_DICTIONARY:
		return

	var reward_type = reward.get("type")
	var amount = reward.get("amount", 0)

	match reward_type:
		Constants.RewardType.COINS:
			grant_coins(amount)

		Constants.RewardType.STARS:
			grant_stars(amount)

		Constants.RewardType.LIVES:
			grant_lives(amount)

		Constants.RewardType.BOOSTER:
			grant_booster(
				reward.get("booster"),
				amount
			)

		_:
			grant_custom_reward(reward)


func grant_rewards(rewards) -> void:
	if typeof(rewards) != TYPE_ARRAY:
		return

	for reward in rewards:
		grant_reward(reward)


# =========================================================
# ECONOMY OPERATIONS
# =========================================================

func grant_coins(amount) -> void:
	if _economy_manager == null:
		return

	if _economy_manager.has_method("add_coins"):
		_economy_manager.add_coins(amount)


func grant_stars(amount) -> void:
	if _economy_manager == null:
		return

	if _economy_manager.has_method("add_stars"):
		_economy_manager.add_stars(amount)


func grant_lives(amount) -> void:
	if _economy_manager == null:
		return

	if _economy_manager.has_method("add_life"):
		_economy_manager.add_life(amount)


func grant_booster(type, amount) -> void:
	if _economy_manager == null:
		return

	if _economy_manager.has_method("add_booster"):
		_economy_manager.add_booster(type, amount)


func grant_custom_reward(data) -> void:
	if _economy_manager == null:
		return

	if _economy_manager.has_method("grant_custom_reward"):
		_economy_manager.grant_custom_reward(data)
