extends RefCounted
## Learning/earning a tool is player progress, not a restriction of the replayed
## board. Never changes inventory, level locks, moves or authored objectives.
const INTRODUCTIONS := {"rocket":4, "bomb":6, "thunder":8, "ethan":24}

static func apply(authored: Dictionary, progress: ConfigFile) -> Dictionary:
	var data := authored.duplicate(true)
	var settings: Dictionary = data.get("settings", {}).duplicate(true)
	var specials: Dictionary = data.get("powerups", {}).duplicate(true)
	var available: Array = settings.get("available_boosters", []).duplicate()
	var board_specials: Array = specials.get("available", []).duplicate()
	var completed: Dictionary = progress.get_value("campaign", "completed_levels", {})
	for kind in INTRODUCTIONS:
		var learned := bool(progress.get_value("tool_unlocks", kind, false)) or bool(progress.get_value("academy_completed", "characters" if kind == "ethan" else kind, false))
		for level in completed:
			if int(level) >= int(INTRODUCTIONS[kind]) and int(completed[level]) > 0:
				learned = true
		if available.has(kind) or learned:
			progress.set_value("tool_unlocks", kind, true)
			if not available.has(kind): available.append(kind)
			if kind != "ethan" and not board_specials.has(str(kind).to_upper()): board_specials.append(str(kind).to_upper())
	settings.available_boosters = available
	settings.allow_boosters = not available.is_empty()
	specials.available = board_specials
	specials.enabled = not board_specials.is_empty()
	data.settings = settings
	data.powerups = specials
	return data
