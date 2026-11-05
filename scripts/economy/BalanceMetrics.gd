extends RefCounted

## Local diagnostics only. No account identifiers and no network uploads.
const PATH := "user://balance_events.jsonl"
const MAX_BYTES := 1024 * 1024

static func record(event: Dictionary) -> void:
	if FileAccess.file_exists(PATH):
		var previous := FileAccess.open(PATH,FileAccess.READ)
		var length := previous.get_length() if previous != null else 0
		previous = null
		if length > MAX_BYTES:
			DirAccess.remove_absolute(PATH + ".previous")
			DirAccess.rename_absolute(PATH,PATH + ".previous")
	var file := FileAccess.open(PATH,FileAccess.READ_WRITE if FileAccess.file_exists(PATH) else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	var entry := event.duplicate(true)
	entry["unix_time"] = TimeHelper.current_unix_time()
	file.store_line(JSON.stringify(entry))
