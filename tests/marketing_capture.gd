extends Node
## Actual game rendering using a separate, preconfigured demonstration save.
var game: Game
var output := "res://exports/marketing-v9"
var shots: Array = []
var scenes: Array = []
var start_frame := 0
var segment_start := 0.0

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	get_window().content_scale_size = Vector2i(720,1280)
	get_window().borderless = true
	get_window().size = Vector2i(1080,1920)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output + "/raw"))
	var ignore := FileAccess.open(output + "/.gdignore", FileAccess.WRITE)
	ignore.store_string("")
	ignore.close()
	start_frame = Engine.get_process_frames()
	call_deferred("run")

func hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func stamp() -> float:
	return float(Engine.get_process_frames()) / 30.0

func begin_segment() -> void:
	segment_start = stamp()

func end_segment(name: String, caption: String) -> void:
	scenes.append({"name":name, "caption":caption, "start":segment_start, "duration":stamp()-segment_start})

func capture(name: String, caption: String) -> void:
	await RenderingServer.frame_post_draw
	var file := output + "/raw/" + name + ".png"
	var result := get_viewport().get_texture().get_image().save_png(file)
	shots.append({"name":name, "caption":caption, "file":file, "time":stamp(), "saved":result == OK})
	print("CAPTURE ", name, " ", get_viewport().get_visible_rect().size)

func clear_layer(property: String) -> void:
	var layer = game.get(property)
	if is_instance_valid(layer): layer.queue_free()
	game.set(property, null)

func enter_level(id: int, with_tutorial := false) -> void:
	game._finish_tutorial()
	for property in ["_story_layer", "_campaign_layer", "_briefing_layer", "_chapter_layer", "_result_layer"]:
		clear_layer(property)
	await get_tree().process_frame
	game._result_in_progress = false
	game.get_node("Managers/LevelManager").load_level(id)
	game._begin_level("alone")
	if not with_tutorial: game._finish_tutorial()
	await hold(0.65)

func run() -> void:
	game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await hold(2.3)
	begin_segment()
	await capture("01-title", "Save The Baby")
	await hold(2.8)
	end_segment("title", "A match-3 rescue adventure")
	game._start_opening_story()
	await hold(0.7)
	game._finish_dialogue_typing()
	begin_segment()
	await capture("02-david-story", "Follow David's story")
	await hold(3.4)
	game._story_manager.next_dialogue()
	await hold(0.25)
	game._story_manager.next_dialogue()
	await hold(0.25)
	game._finish_dialogue_typing()
	await capture("03-amara-instructions", "Bring Ethan home")
	await hold(3.5)
	end_segment("story", "David needs your help")
	game._skip_opening_story()
	await hold(0.6)
	game._finish_tutorial()
	game._campaign_coach_shown = true
	begin_segment()
	await capture("04-campaign-map", "Follow the trail")
	await hold(2.6)
	end_segment("map", "Follow the trail")
	clear_layer("_campaign_layer")
	game._show_new_chapter(JsonLoader.load_file("res://levels/level001.json"), "alone")
	await hold(0.6)
	begin_segment()
	await capture("05-chapter", "Explore the investigation")
	await hold(2.8)
	end_segment("chapter", "A new chapter awaits")
	clear_layer("_chapter_layer")
	if game._campaign_progress.has_section("academy_completed"): game._campaign_progress.erase_section("academy_completed")
	await enter_level(1, true)
	begin_segment()
	await capture("06-david-lesson", "Learn with David")
	await hold(4.0)
	end_segment("lesson", "Learn with David")
	for kind in ["rocket","bomb","thunder","ethan"]:
		game._campaign_progress.set_value("tool_unlocks",kind,true)
		if kind == "ethan": game._economy_manager.set_ethan_count(3)
		else: game._economy_manager.set_booster_count(kind,5)
	await enter_level(8)
	begin_segment()
	var board := game._board
	var swap := board.find_valid_swap_for_type(Constants.TileType.PHONE)
	if swap.is_empty(): swap = board.find_valid_swap()
	if swap.size() == 2: board.swap_tiles(swap[0],swap[1])
	await hold(0.18)
	await capture("07-match-action", "Match the clues")
	await hold(2.0)
	await capture("08-gameplay", "Every match matters")
	await hold(2.0)
	end_segment("matching", "Match the clues")
	for kind in ["rocket","bomb","thunder"]:
		await enter_level(48)
		begin_segment()
		game._board.use_booster_at(kind,Vector2i(3,3))
		await hold(0.16)
		await capture("09-"+kind+"-blast", "Unleash powerful boosters")
		await hold(2.3)
		end_segment(kind, "Unleash powerful boosters")
	await enter_level(24)
	begin_segment()
	game._board.use_ethan_gift()
	await hold(0.18)
	await capture("10-ethan", "Ethan changes everything")
	await hold(3.0)
	end_segment("ethan", "Ethan changes everything")
	# A valid prepared restoration attempt, with the real puzzle/reward pipeline.
	if game._campaign_progress.has_section("daily"): game._campaign_progress.erase_section("daily")
	var now := TimeHelper.current_unix_time()
	var attempt := {"slot":DailyActivities.slot_at(now), "portrait":str(DailyActivities.settings().portraits[0]), "columns":3, "rows":3, "pieces":[4,2,7,1,8,6,0,5,3], "deadline":now+120, "coins":15, "points":225, "booster":"rocket"}
	game._campaign_progress.set_value("daily","attempt",attempt)
	game._campaign_progress.set_value("daily","last_seen",now)
	game._show_portrait_attempt(attempt)
	await hold(0.6)
	begin_segment()
	await capture("11-restoration", "Restore their memories")
	await hold(1.0)
	var puzzle: PortraitPuzzle = game._portrait_puzzle
	for index in puzzle._pieces.size():
		if int(puzzle._pieces[index]) == index: continue
		var other := puzzle._pieces.find(index)
		puzzle._select(index)
		await hold(0.35)
		puzzle._select(other)
		await hold(0.45)
		if index == 2: await capture("12-restoration-progress", "Piece the story together")
	end_segment("restoration", "Restore their memories")
	await hold(0.6)
	begin_segment()
	await capture("13-restoration-reward", "Restore. Collect. Celebrate.")
	await hold(3.4)
	end_segment("restoration-reward", "Restore. Collect. Celebrate.")
	game._close_portrait_puzzle(false)
	await enter_level(8)
	# Prepared end-of-level state: actual settlement effects and score updates.
	game._board._remaining_moves = 5
	game._on_moves_changed(5)
	for index in 3:
		var tile: Tile = game._board.get_tile(Vector2i(index,0))
		tile.set_powerup([Constants.PowerupType.ROCKET,Constants.PowerupType.BOMB,Constants.PowerupType.THUNDER][index])
		tile.set_meta("powerup_kind",["rocket","bomb","thunder"][index])
	game._board.lock()
	begin_segment()
	game.victory_bonus_step.connect(func(kind, _points):
		if kind != "move": capture.call_deferred("14-victory-"+kind, "Make every move count"))
	await game._show_level_result(true)
	end_segment("victory-bonus", "Make every move count")
	await hold(0.7)
	begin_segment()
	await capture("15-victory", "Celebrate the rescue")
	await hold(3.0)
	end_segment("victory", "Celebrate every victory")
	game._dismiss_level_result()
	game._show_daily_rewards()
	await hold(0.6)
	begin_segment()
	await capture("16-daily-rewards", "Come back for more")
	await hold(2.7)
	end_segment("daily", "Rewards for your next adventure")
	var manifest := {"resolution":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"fps":30,"shots":shots,"segments":scenes,"note":"Actual Godot rendering and audio from an isolated, preconfigured demonstration save. No fabricated game UI. Prepared restoration and victory scenarios demonstrate existing mechanics."}
	var file := FileAccess.open(output+"/capture-manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "))
	file.close()
	print("MARKETING CAPTURE COMPLETE: ",shots.size()," screenshots, ",scenes.size()," segments")
	get_tree().quit()
