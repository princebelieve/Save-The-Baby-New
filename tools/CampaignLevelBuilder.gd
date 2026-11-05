extends RefCounted

## Offline level composition. Runtime gameplay only reads levels/levelNNN.json.
static func settings() -> Dictionary:
	return JsonLoader.load_file("res://configs/endless_progression.json")


static func last_level() -> int:
	return int(settings().get("last_level", 50))


static func generate(level_id: int) -> Dictionary:
	var config := settings()
	if level_id < int(config.first_level) or level_id > int(config.last_level):
		return {}
	var rng := RandomNumberGenerator.new()
	var stable_seed := int(config.seed) + level_id * 7919
	rng.seed = stable_seed
	var data := JsonLoader.load_file("res://levels/level%03d.json" % int(config.base_level)).duplicate(true)
	var offset := level_id - int(config.first_level)
	var length := int(config.chapter_length)
	var chapter := 7 + offset / length
	var difficulty: String = config.cadence[offset % config.cadence.size()]
	var band: Dictionary = config.bands[difficulty]
	var theme: Dictionary = config.themes[(offset / length) % config.themes.size()]
	var shape: Array = config.shapes[rng.randi_range(0, config.shapes.size() - 1)]
	var width := int(shape[0])
	var height := int(shape[1])
	var target: String = config.targets[rng.randi_range(0, config.targets.size() - 1)]
	data.level_id = level_id
	data.name = "Evidence Patrol %d" % level_id
	data.description = "Gather %s evidence and clear every blocker on this patrol." % target.to_lower()
	data.difficulty = difficulty
	data.board.columns = width
	data.board.rows = height
	data.board.blocked_cells = []
	# Corner cutouts keep every column connected to a spawn route.
	if offset % 3 == 1:
		data.board.blocked_cells = [[0, height - 1], [width - 1, height - 1]]
	# Encode the case into small weight variations, avoiding repeated compositions.
	var weight_code := offset
	for index in 5:
		data.tile_pool.weights[index] = 16 + weight_code % 5
		weight_code = weight_code / 5
	data.moves.total = int(band.moves)
	if level_id <= int(config.get("onboarding_last_level", 0)):
		data.moves.total += int(config.get("onboarding_extra_moves", 0))
	data.objectives = [{"type": "COLLECT_ITEMS", "target": target, "amount": int(band.amount)}]
	var override: Dictionary = config.get("case_overrides", {}).get(str(level_id), {})
	if override.has("moves"):
		data.moves.total = int(override.moves)
	if override.has("amount"):
		data.objectives[0].amount = int(override.amount)
	var cells: Array[Vector2i] = []
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			cells.append(Vector2i(x, y))
	var obstacles: Array[Dictionary] = []
	for index in range(int(band.obstacles)):
		var chosen := rng.randi_range(0, cells.size() - 1)
		var cell := cells[chosen]
		cells.remove_at(chosen)
		obstacles.append({"x": cell.x, "y": cell.y, "type": config.obstacles[(index + offset) % config.obstacles.size()], "health": 1})
	data.obstacles.items = obstacles
	var challenge: Dictionary = JsonLoader.load_file("res://configs/difficulty_policy.json").get("booster_challenges",{})
	if level_id >= int(challenge.get("first_level",100)) and (level_id-int(challenge.get("first_level",100))) % int(challenge.get("interval",50)) == 0 and not obstacles.is_empty():
		obstacles[0]["inventory_only"] = true
		obstacles[0]["type"] = "lock"
		obstacles[0]["health"] = 1
		data.description = "Critical Case: gather the evidence and break through a reinforced investigation. Plan your supplies before following the trail."
		data.difficulty = "CRITICAL_CASE"
	data.story = {"before_level": "", "after_level": "", "first_clear": "", "return_to_map": true}
	data.tutorial = {"enabled": false, "steps": []}
	data.rewards.coins = int(config.get("coins_by_difficulty", {}).get(data.difficulty, config.coins))
	data.metadata = {
		"chapter_id": chapter, "chapter_title": theme.title,
		"chapter_start_level": level_id - offset % length,
		"chapter_end_level": mini(int(config.last_level), level_id - offset % length + length - 1),
		"map_background": theme.background, "map_landmark": theme.landmark,
		"map_props": ["wooden_bridge_cutout.png", "police_car_topdown_cutout.png"],
		"generator_version": int(config.version), "seed": stable_seed,
		"notes": "Collect a common evidence tile while clearing dispersed single-hit blockers. Recovery cases alternate with combined challenges."
	}
	if data.difficulty == "CRITICAL_CASE":
		var case_index := (level_id-int(challenge.get("first_level",100)))/int(challenge.get("interval",50))
		data.metadata["recommended_booster"] = ["rocket","bomb","thunder"][case_index % 3]
		data.metadata["scout_supply"] = case_index % 4 == 0
	return preload("res://scripts/story/StoryCampaign.gd").apply_to_level(data)
