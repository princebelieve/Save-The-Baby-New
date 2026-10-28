extends RefCounted
class_name SaveFile

func initialize() -> void:
	pass


func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func write(path: String, data: Dictionary) -> bool:
	var directory := path.get_base_dir()
	if directory.begins_with("user://") and not DirAccess.dir_exists_absolute(directory):
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if error != OK:
			return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func delete(path: String) -> bool:
	if not exists(path):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


func copy(source: String, destination: String) -> bool:
	if not exists(source):
		return false
	var source_file := FileAccess.open(source, FileAccess.READ)
	if source_file == null:
		return false
	var data := source_file.get_buffer(source_file.get_length())
	source_file.close()
	var destination_file := FileAccess.open(destination, FileAccess.WRITE)
	if destination_file == null:
		return false
	destination_file.store_buffer(data)
	destination_file.close()
	return true


func rename(path: String, new_name: String) -> bool:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path.get_base_dir().path_join(new_name))) == OK


func create_backup(path: String) -> bool:
	return copy(path, path + ".bak")


func restore_backup(path: String) -> bool:
	return copy(path + ".bak", path)
