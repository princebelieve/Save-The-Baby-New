extends RefCounted
class_name SaveValidator

var _errors: Array[String] = []

func initialize() -> void:
	_errors.clear()


func validate(save_data: SaveData) -> bool:
	_errors.clear()
	if save_data == null:
		_errors.append("Save data is missing.")
		return false
	return validate_version(save_data) and validate_sections(save_data) and validate_required_fields(save_data)


func validate_version(save_data: SaveData) -> bool:
	return save_data != null and not save_data.get_save_version().is_empty()


func validate_sections(save_data: SaveData) -> bool:
	return save_data != null


func validate_required_fields(save_data: SaveData) -> bool:
	return save_data != null


func get_validation_errors() -> Array:
	return _errors.duplicate()
