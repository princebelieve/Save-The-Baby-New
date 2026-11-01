extends RefCounted
class_name CaseJournal

const SECTION := "case_journal"


static func discover(progress: ConfigFile, skill_id: String, title: String, fact_id: String, message: String, illustration: String, level_id: int) -> bool:
	if skill_id.is_empty() or fact_id.is_empty() or message.strip_edges().is_empty():
		return false
	var entries: Dictionary = progress.get_value(SECTION, "entries", {})
	var entry: Dictionary = entries.get(skill_id, {"id": skill_id, "title": title, "illustration": illustration, "facts": {}, "level": level_id})
	var facts: Dictionary = entry.get("facts", {})
	# Revisiting the same rule never adds another card or another paraphrase.
	if facts.has(fact_id):
		return false
	facts[fact_id] = message.strip_edges()
	entry["facts"] = facts
	entries[skill_id] = entry
	progress.set_value(SECTION, "entries", entries)
	return true


static func entries(progress: ConfigFile) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var saved: Dictionary = progress.get_value(SECTION, "entries", {})
	for entry in saved.values():
		if entry is Dictionary and not entry.get("facts", {}).is_empty():
			result.append(entry.duplicate(true))
	return result
