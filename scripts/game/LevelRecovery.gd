extends RefCounted

static func settings() -> Dictionary:
	return JsonLoader.load_file("res://configs/difficulty_policy.json").get("return_assistance",{})

static func touch(progress: ConfigFile, now: int) -> void:
	progress.set_value("recovery","last_activity",maxi(now,int(progress.get_value("recovery","last_activity",0))))

static func begin_session(progress: ConfigFile, now: int) -> void:
	var config := settings()
	var last := int(progress.get_value("recovery","last_activity",0))
	var last_help := int(progress.get_value("recovery","last_assistance",0))
	if last > 0 and now-last >= int(config.absence_seconds) and (last_help == 0 or now-last_help >= int(config.cooldown_seconds)):
		progress.set_value("recovery","eligible_until",now+int(config.claim_window_seconds))
	touch(progress,now)

static func record_result(progress: ConfigFile, level_id: int, won: bool, now: int) -> void:
	var cases: Dictionary = progress.get_value("recovery","cases",{})
	var state: Dictionary = cases.get(str(level_id),{})
	if won:
		if bool(state.get("assistance_used",false)):
			cases[str(level_id)] = {"assistance_used":true}
		else:
			cases.erase(str(level_id))
	else:
		state["failures"] = int(state.get("failures",0))+1
		cases[str(level_id)] = state
	progress.set_value("recovery","cases",cases)
	touch(progress,now)

static func eligible(progress: ConfigFile, data: Dictionary, now: int) -> bool:
	var config := settings()
	var level_id := int(data.get("level_id",0))
	var cases: Dictionary = progress.get_value("recovery","cases",{})
	var state: Dictionary = cases.get(str(level_id),{})
	var last := int(progress.get_value("recovery","last_activity",0))
	var last_help := int(progress.get_value("recovery","last_assistance",0))
	return level_id >= int(config.first_level) and str(data.get("difficulty","")) in ["MEDIUM","HARD","VERY_HARD","CRITICAL_CASE"] and int(state.get("failures",0)) >= int(config.minimum_failures) and not bool(state.get("assistance_used",false)) and now >= last and now < int(progress.get_value("recovery","eligible_until",0)) and (last_help == 0 or now-last_help >= int(config.cooldown_seconds))

static func preview(progress: ConfigFile, authored: Dictionary, now: int) -> Dictionary:
	var data := authored.duplicate(true)
	if not eligible(progress,data,now):
		return data
	var config := settings()
	data.moves.total = int(data.moves.total)+int(config.extra_moves)
	var objective: Dictionary = data.objectives[0]
	var index: int = data.tile_pool.tiles.find(str(objective.get("target","")).to_lower())
	if index >= 0 and index < data.tile_pool.weights.size():
		data.tile_pool.weights[index] = float(data.tile_pool.weights[index])*float(config.target_weight_multiplier)
	data.metadata["authored_seed"] = int(data.metadata.get("seed",0))
	data.metadata["seed"] = int(data.metadata.get("seed",0))+int(progress.get_value("recovery","eligible_until",0))*31+int(data.level_id)
	data.settings["return_assistance"] = true
	data.settings["lucky_refill_chance"] = float(config.lucky_refill_chance)
	return data

static func start_attempt(progress: ConfigFile, data: Dictionary, now: int) -> void:
	if bool(data.get("settings",{}).get("return_assistance",false)):
		var cases: Dictionary = progress.get_value("recovery","cases",{})
		var state: Dictionary = cases.get(str(int(data.level_id)),{})
		state["assistance_used"] = true
		cases[str(int(data.level_id))] = state
		progress.set_value("recovery","cases",cases)
		progress.set_value("recovery","last_assistance",now)
		progress.set_value("recovery","eligible_until",0)
	touch(progress,now)
