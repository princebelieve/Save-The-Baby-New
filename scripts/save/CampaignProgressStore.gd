extends RefCounted
class_name CampaignProgressStore

## Browsing the full map never grants access. Only consecutive wins do.
static func unlocked_level(completed: Dictionary, max_levels: int) -> int:
	var next_level := 1
	while next_level < maxi(1, max_levels) and int(completed.get(str(next_level), 0)) > 0:
		next_level += 1
	return next_level

## Keep the last successful save intact until its replacement is on disk.
static func write(config: ConfigFile, path: String) -> Error:
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var error := config.save(temporary)
	if error != OK:
		return error
	if FileAccess.file_exists(path):
		# Never replace a healthy backup with an unreadable primary file.
		var previous := ConfigFile.new()
		if previous.load(path) == OK:
			error = DirAccess.copy_absolute(path, backup)
			if error != OK:
				return error
	return DirAccess.rename_absolute(temporary, path)


static func read(config: ConfigFile, path: String) -> Error:
	var error := config.load(path)
	if error == OK:
		return OK
	config.clear()
	error = config.load(path + ".bak")
	if error != OK:
		config.clear()
	return error
