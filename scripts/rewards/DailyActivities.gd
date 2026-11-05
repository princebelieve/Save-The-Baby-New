extends RefCounted
class_name DailyActivities

## Calendar rules and claim markers share the campaign's atomic save.
const DAY := 86400

static func settings() -> Dictionary:
	var config := JsonLoader.load_file("res://configs/daily_activities.json").duplicate(true)
	var portraits: Array = config.portraits
	for tile in JsonLoader.load_file("res://configs/tiles.json").get("tiles", []):
		var path := str(tile.get("icon", ""))
		if not path.is_empty() and not portraits.has(path): portraits.append(path)
	for artwork in config.get("puzzle_art", []):
		if not portraits.has(str(artwork.path)): portraits.append(str(artwork.path))
	return config


static func day_at(now: int) -> int:
	return int(floor(float(now) / DAY))


static func slot_at(now: int) -> int:
	return int(floor(float(now) / (int(settings().slot_hours) * 3600)))


static func clock_valid(progress: ConfigFile, now: int) -> bool:
	return now >= int(progress.get_value("daily", "last_seen", 0))


static func stamp(progress: ConfigFile, now: int) -> Dictionary:
	if not clock_valid(progress, now):
		return {}
	var today := day_at(now)
	var previous := int(progress.get_value("daily", "last_day", -1))
	if today <= previous:
		return {}
	var config := settings()
	var streak := int(progress.get_value("daily", "streak", 0))
	var protected := false
	if previous >= 0 and today - previous == 2 and today - int(progress.get_value("daily", "grace_day", -100)) >= int(config.grace_cooldown_days):
		protected = true
		progress.set_value("daily", "grace_day", today)
	streak = streak + 1 if today - previous == 1 or protected else 1
	progress.set_value("daily", "last_day", today)
	progress.set_value("daily", "last_seen", now)
	progress.set_value("daily", "streak", streak)
	var week := int(floor(float(today + 3) / 7)) # Monday, UTC.
	var weekly := int(progress.get_value("daily", "weekly_count", 0)) if int(progress.get_value("daily", "week", -1)) == week else 0
	weekly += 1
	progress.set_value("daily", "week", week)
	progress.set_value("daily", "weekly_count", weekly)
	var coins := int(config.streak_coins[(streak - 1) % config.streak_coins.size()])
	if weekly == int(config.weekly_days):
		coins += int(config.weekly_coins)
	return {"coins": coins, "streak": streak, "protected": protected}


static func available(progress: ConfigFile, now: int) -> bool:
	return clock_valid(progress, now) and slot_at(now) > int(progress.get_value("daily", "portrait_slot", -1))


static func record_mission(progress: ConfigFile, kind: String, amount: int, now: int) -> int:
	if amount <= 0 or not clock_valid(progress, now):
		return 0
	var today := day_at(now)
	var counts: Dictionary = progress.get_value("daily", "missions", {}) if int(progress.get_value("daily", "mission_day", -1)) == today else {}
	var coins := 0
	for mission in settings().missions:
		if str(mission.id) != kind:
			continue
		var previous := int(counts.get(kind, 0))
		var target := int(mission.target)
		counts[kind] = mini(target, previous + amount)
		if previous < target and int(counts[kind]) >= target:
			coins = int(mission.coins)
	progress.set_value("daily", "mission_day", today)
	progress.set_value("daily", "missions", counts)
	progress.set_value("daily", "last_seen", now)
	return coins


static func start_portrait(progress: ConfigFile, now: int) -> Dictionary:
	if not available(progress, now):
		return {}
	var config := settings()
	var slot := slot_at(now)
	var challenge := puzzle_for_slot(slot)
	var portrait: String = config.portraits[slot % config.portraits.size()]
	var count := int(challenge.columns) * int(challenge.rows)
	var pieces: Array[int] = []
	for index in count:
		pieces.append(index)
	var rng := RandomNumberGenerator.new()
	rng.seed = slot * 7919 + 41
	for index in range(count - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var temporary := pieces[index]
		pieces[index] = pieces[other]
		pieces[other] = temporary
	var solved := true
	for index in count:
		if pieces[index] != index: solved = false
	if solved:
		pieces[0] = 1
		pieces[1] = 0
	var deadline := mini(now + int(challenge.seconds), (slot + 1) * int(config.slot_hours) * 3600)
	var attempt := {"slot": slot, "portrait": portrait, "pieces": pieces, "deadline": deadline,
		"columns": int(challenge.columns), "rows": int(challenge.rows), "difficulty": str(challenge.name)}
	progress.set_value("daily", "portrait_slot", slot)
	progress.set_value("daily", "last_seen", now)
	progress.set_value("daily", "attempt", attempt)
	return attempt


static func active_attempt(progress: ConfigFile, now: int) -> Dictionary:
	var attempt: Dictionary = progress.get_value("daily", "attempt", {})
	if not clock_valid(progress, now) or attempt.is_empty() or now >= int(attempt.deadline) or int(attempt.slot) != slot_at(now):
		return {}
	return attempt.duplicate(true)


static func finish_portrait(progress: ConfigFile, slot: int, now: int) -> Dictionary:
	var attempt := active_attempt(progress, now)
	if attempt.is_empty() or int(attempt.slot) != slot:
		return {}
	var count := int(attempt.get("columns", 3)) * int(attempt.get("rows", 3))
	if attempt.pieces.size() != count: return {}
	for index in count:
		if int(attempt.pieces[index]) != index:
			return {}
	progress.set_value("daily", "attempt", {})
	progress.set_value("daily", "last_seen", now)
	var collection: Dictionary = progress.get_value("daily", "portraits", {})
	collection[str(attempt.portrait)] = int(collection.get(str(attempt.portrait), 0)) + 1
	progress.set_value("daily", "portraits", collection)
	var daily := stamp(progress, now)
	return {"coins": int(settings().portrait_coins) + int(daily.get("coins", 0)), "streak": int(progress.get_value("daily", "streak", 0))}


static func puzzle_for_slot(slot: int) -> Dictionary:
	var config := settings()
	var rotation: Array = config.get("difficulty_rotation", [0])
	var difficulties: Array = config.get("puzzle_difficulties", [{"name":"Standard", "columns":3, "rows":3, "seconds":120}])
	return difficulties[int(rotation[posmod(slot, rotation.size())])].duplicate()


static func artwork_title(path: String) -> String:
	if path.contains("amara_and_ethan"): return "Amara & Ethan"
	if path.contains("david"): return "David"
	for tile in JsonLoader.load_file("res://configs/tiles.json").get("tiles", []):
		if str(tile.get("icon", "")) == path: return str(tile.name)
	for artwork in settings().get("puzzle_art", []):
		if str(artwork.path) == path: return str(artwork.title)
	return path.get_file().get_basename().replace("_", " ").capitalize()
