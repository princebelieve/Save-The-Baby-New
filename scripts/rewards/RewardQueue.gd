extends Node
class_name RewardQueue

# =========================================================
# PURPOSE
# Stores rewards waiting to be claimed.
#
# Contains no calculations.
# Contains no UI.
# =========================================================


# =========================================================
# INTERNAL STATE
# =========================================================

var _pending_rewards: Array = []


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	clear()


# =========================================================
# QUEUE OPERATIONS
# =========================================================

func add(reward) -> void:
	_pending_rewards.append(reward)


func add_multiple(rewards) -> void:
	if typeof(rewards) != TYPE_ARRAY:
		return

	for reward in rewards:
		add(reward)


func claim():
	if is_empty():
		return null

	return _pending_rewards.pop_front()


func claim_all() -> Array:
	var rewards := _pending_rewards.duplicate()
	clear()
	return rewards


func peek():
	if is_empty():
		return null

	return _pending_rewards.front()


func clear() -> void:
	_pending_rewards.clear()


# =========================================================
# QUERY
# =========================================================

func is_empty() -> bool:
	return _pending_rewards.is_empty()


func count() -> int:
	return _pending_rewards.size()