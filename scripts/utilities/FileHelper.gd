extends Node
class_name FileHelper

# =========================================================
# PURPOSE
# Low-level filesystem helper only.
# No gameplay logic.
# No state management.
# No dependency on managers.
# =========================================================


# =========================================================
# FILES
# =========================================================

func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func copy_file(source: String, destination: String) -> bool:
	if not FileAccess.file_exists(source):
		return false

	var src_file := FileAccess.open(source, FileAccess.READ)
	if src_file == null:
		return false

	var data := src_file.get_buffer(src_file.get_length())
	src_file.close()

	_ensure_directory(destination.get_base_dir())

	var dst_file := FileAccess.open(destination, FileAccess.WRITE)
	if dst_file == null:
		return false

	dst_file.store_buffer(data)
	dst_file.close()

	return true


func move_file(source: String, destination: String) -> bool:
	if not copy_file(source, destination):
		return false

	return delete_file(source)


func delete_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false

	var file_name := path.get_file()
	return dir.remove(file_name) == OK


func rename_file(path: String, new_name: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var dir_path := path.get_base_dir()
	var old_name := path.get_file()
	var new_path := dir_path.path_join(new_name)

	var dir := DirAccess.open(dir_path)
	if dir == null:
		return false

	return dir.rename(old_name, new_name) == OK


func get_file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1

	var size := file.get_length()
	file.close()

	return size


# =========================================================
# DIRECTORIES
# =========================================================

func directory_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)


func create_directory(path: String) -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return false

	return dir.make_dir_recursive(path) == OK


func delete_directory(path: String) -> bool:
	if not DirAccess.dir_exists_absolute(path):
		return false

	var dir := DirAccess.open(path)
	if dir == null:
		return false

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path := path.path_join(file_name)

			if dir.current_is_dir():
				delete_directory(full_path)
			else:
				dir.remove(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	# finally remove empty directory
	var parent := DirAccess.open(path.get_base_dir())
	if parent == null:
		return false

	return parent.remove(path.get_file()) == OK


func list_files(path: String) -> Array:
	var result: Array = []

	var dir := DirAccess.open(path)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name != "." and file_name != "..":
			result.append(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	return result


func list_directories(path: String) -> Array:
	var result: Array = []

	var dir := DirAccess.open(path)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			result.append(file_name)

		file_name = dir.get_next()

	dir.list_dir_end()

	return result


# =========================================================
# INTERNAL HELPERS
# =========================================================

func _ensure_directory(path: String) -> void:
	var dir_path := path.get_base_dir()

	if dir_path == "":
		return

	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive(dir_path)