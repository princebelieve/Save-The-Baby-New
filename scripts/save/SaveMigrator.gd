extends RefCounted
class_name SaveMigrator

func initialize() -> void:
	pass


func can_migrate(version: String) -> bool:
	return version != str(Constants.SAVE_VERSION)


func migrate(save_data: SaveData) -> SaveData:
	if save_data != null:
		save_data.set_save_version(str(Constants.SAVE_VERSION))
	return save_data


func get_supported_versions() -> Array:
	return ["1"]


func get_current_version() -> String:
	return str(Constants.SAVE_VERSION)
