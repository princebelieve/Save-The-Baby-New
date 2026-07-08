extends RefCounted
class_name RewardData

# =========================================================
# PURPOSE
# Represents one reward.
#
# Pure data container.
# Contains no gameplay logic.
# =========================================================


# =========================================================
# PROPERTIES
# =========================================================

var type = null
var id = null
var amount = 0
var metadata: Dictionary = {}
var claimable: bool = true
var source = null
var icon = ""


# =========================================================
# PUBLIC API
# =========================================================

func duplicate() -> RewardData:
	var reward := RewardData.new()

	reward.type = type
	reward.id = id
	reward.amount = amount
	reward.metadata = metadata.duplicate(true)
	reward.claimable = claimable
	reward.source = source
	reward.icon = icon

	return reward


func to_dictionary() -> Dictionary:
	return {
		"type": type,
		"id": id,
		"amount": amount,
		"metadata": metadata.duplicate(true),
		"claimable": claimable,
		"source": source,
		"icon": icon
	}


func from_dictionary(data: Dictionary) -> RewardData:
	type = data.get("type", null)
	id = data.get("id", null)
	amount = data.get("amount", 0)
	metadata = data.get("metadata", {}).duplicate(true)
	claimable = data.get("claimable", true)
	source = data.get("source", null)
	icon = data.get("icon", "")

	return self