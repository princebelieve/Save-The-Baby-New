extends RefCounted
class_name SaveSerializer

func initialize() -> void:
	pass


func serialize(save_data: SaveData) -> Dictionary:
	if save_data == null:
		return {}
	return {
		"version": save_data.get_save_version(),
		"timestamp": save_data.get_timestamp(),
		"data": save_data._data.duplicate(true)
	}


func deserialize(data: Dictionary) -> SaveData:
	if data.is_empty() or typeof(data.get("data")) != TYPE_DICTIONARY:
		return null
	var save_data := SaveData.new()
	save_data.initialize()
	save_data._data = data["data"].duplicate(true)
	save_data.set_save_version(str(data.get("version", "1")))
	save_data.set_timestamp(int(data.get("timestamp", 0)))
	return save_data


func to_json(save_data: SaveData) -> String:
	return JSON.stringify(serialize(save_data))


func from_json(json_text: String) -> SaveData:
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return deserialize(parsed)
