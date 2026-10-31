extends Node
class_name RewardManager

signal reward_granted(data)
signal reward_collected(data)

var _pending_rewards

var _calculator
var _preview
var _queue
var _distributor


func _ready() -> void:
	var economy_manager = get_parent().get_node_or_null("EconomyManager") if get_parent() != null else null
	initialize(economy_manager)


func initialize(economy_manager = null) -> void:
	if _calculator != null:
		return
	_calculator = RewardCalculator.new()
	_calculator.initialize()

	_preview = RewardPreview.new()
	_preview.initialize()

	_queue = RewardQueue.new()
	_queue.initialize()

	_distributor = RewardDistributor.new()
	_distributor.initialize(economy_manager)

	_pending_rewards = _queue

func calculate_level_rewards(result):
	var rewards = _calculator.calculate_level_rewards(result)

	if rewards != null:
		_queue.add_multiple(rewards)

	return rewards


func calculate_bonus_rewards(result):
	var rewards = _calculator.calculate_bonus_rewards(result)

	if rewards != null:
		_queue.add_multiple(rewards)

	return rewards


func grant_rewards(reward_data) -> void:
	if reward_data == null:
		return

	_distributor.grant_rewards(reward_data)

	emit_signal("reward_granted", reward_data)


func grant_special_move(kind: String, created_count: int) -> Array:
	var rewards: Array = _calculator.calculate_special_move_rewards(kind, created_count)
	if rewards.is_empty():
		return rewards
	_distributor.grant_rewards(rewards)
	emit_signal("reward_granted", rewards)
	return rewards


func get_special_move_milestone() -> int:
	return _calculator.get_special_move_milestone()


func grant_daily_reward():
	var rewards = _calculator.calculate_daily_reward()

	if rewards != null:
		_queue.add_multiple(rewards)

	return rewards


func grant_story_reward():
	var rewards = _calculator.calculate_story_rewards(null)

	if rewards != null:
		_queue.add_multiple(rewards)

	return rewards


func grant_chest_reward():
	var rewards = _calculator.calculate_chest_reward(null)

	if rewards != null:
		_queue.add_multiple(rewards)

	return rewards


func preview_rewards(level):
	return _preview.preview_level_rewards(level)


func claim_rewards():
	if _queue.is_empty():
		return []

	var rewards = _queue.claim_all()

	_distributor.grant_rewards(rewards)

	emit_signal("reward_collected", rewards)

	return rewards


func clear_pending_rewards() -> void:
	_queue.clear()
