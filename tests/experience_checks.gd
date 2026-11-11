extends Node

var checks := 0
var failures := 0
var captures := false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame in 10: await get_tree().process_frame

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	captures = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func run() -> void:
	calendar()
	await layouts()
	await integration()
	print("EXPERIENCE_CHECKS: %d checks; %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func calendar() -> void:
	var progress := ConfigFile.new()
	var now := 20000 * 43200 + 100
	check(DailyActivities.offer_for_clear(progress, 2, true, now).is_empty(), "early cases do not interrupt with restoration")
	check(DailyActivities.offer_for_clear(progress, 3, false, now).is_empty(), "replayed cases cannot create an opportunity")
	check(not DailyActivities.offer_for_clear(progress, 3, true, now).is_empty(), "first clear of case three earns a challenge")
	check(DailyActivities.invitation_pending(progress, now), "earned challenge is queued once")
	check(progress.get_value("daily", "attempt", {}).is_empty(), "earning and previewing do not start a timer")
	check(not progress.has_section_key("daily", "portrait_slot"), "earning does not consume the attempt")
	check(DailyActivities.offer_for_clear(progress, 7, true, now).is_empty(), "one opportunity per slot")
	progress.set_value("daily", "portrait_offer_presented", DailyActivities.slot_at(now))
	check(not DailyActivities.invitation_pending(progress, now), "dismissed invitation is not forced again")
	check(not DailyActivities.earned_offer(progress, now).is_empty(), "dismissed invitation remains recoverable")
	var attempt := DailyActivities.start_portrait(progress, now)
	check(attempt.booster == "rocket", "earned reward is snapshotted into the attempt")
	check(DailyActivities.earned_offer(progress, now).is_empty(), "started opportunity is not offered again")
	attempt.pieces = range(attempt.pieces.size())
	progress.set_value("daily", "attempt", attempt)
	var result := DailyActivities.finish_portrait(progress, int(attempt.slot), now + 1)
	check(result.booster == "rocket" and result.coins == 20, "successful challenge includes supply and stamp")
	check(DailyActivities.finish_portrait(progress, int(attempt.slot), now + 2).is_empty(), "duplicate completion cannot repeat reward")
	check(DailyActivities.earned_offer(progress, now + 43200).is_empty(), "an unstarted offer cannot carry into another slot")
	check(not DailyActivities.offer_for_clear(progress, 7, true, now + 43200).is_empty(), "later new case earns a new opportunity")
	var boundary := ConfigFile.new()
	var near_reset := now - 100 + 43199
	DailyActivities.offer_for_clear(boundary, 3, true, near_reset)
	var crossing := DailyActivities.start_portrait(boundary, near_reset)
	check(int(crossing.deadline) - near_reset == int(DailyActivities.puzzle_for_slot(int(crossing.slot)).seconds), "near-reset attempts receive full time")
	check(not DailyActivities.active_attempt(boundary, near_reset + 5).is_empty(), "running attempt resumes across a slot boundary")
	check(not DailyActivities.available(boundary, near_reset + 5), "boundary cannot create overlapping attempts")
	crossing.pieces = range(crossing.pieces.size())
	boundary.set_value("daily", "attempt", crossing)
	check(DailyActivities.finish_portrait(boundary, int(crossing.slot), near_reset + 5).booster == "rocket", "cross-boundary completion keeps promised reward")
	var legacy := ConfigFile.new()
	legacy.set_value("daily", "attempt", {"slot":DailyActivities.slot_at(now), "portrait":str(DailyActivities.settings().portraits[0]), "pieces":range(9), "deadline":now + 100})
	check(DailyActivities.finish_portrait(legacy, DailyActivities.slot_at(now), now + 1).booster == "", "legacy attempts retain their original coin-only reward")

func layouts() -> void:
	for height in [1100, 1280]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, height)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		var overlay := TutorialOverlay.new()
		viewport.add_child(overlay)
		await settle()
		overlay.show_tip("Tap the glowing pieces to make a match. Every useful match brings us closer to Ethan. This deliberately longer explanation must split using the font that players actually see.", Rect2(260, 700, 180, 120), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)
		await settle()
		check(overlay._body_label.get_theme_font_size("font_size") == 40, "phone tutorial uses forty-unit body lettering")
		check(overlay._body_label.visible_characters == -1 and overlay._acknowledge_button.text != "SHOW TEXT", "instruction appears immediately")
		for page in overlay._pages:
			var font := overlay._body_label.get_theme_font("font")
			check(font.get_multiline_string_size(page, HORIZONTAL_ALIGNMENT_LEFT, 604, 40).y <= font.get_height(40) * 3 + 2, "pagination uses actual rendered font and width")
		check(Rect2(Vector2.ZERO, Vector2(720, height)).encloses(overlay._bubble.get_rect()), "tutorial card remains in phone bounds")
		check(overlay._bubble.get_global_rect().encloses(overlay._body_scroll.get_global_rect()), "body is inside its illustrated card")
		check(overlay._body_label.get_minimum_size().y <= overlay._body_scroll.size.y + 2, "all tutorial lines fit without scrolling")
		check(overlay._bubble.get_global_rect().encloses(overlay._acknowledge_button.get_global_rect()), "tutorial action stays in its card")
		await capture(viewport, "tutorial-%d" % height)
		overlay.queue_free()
		await settle()
		var invite := preload("res://scripts/ui/RestorationInvite.gd").new()
		invite.details = {"portrait":str(DailyActivities.settings().portraits[0]), "booster":"rocket", "coins":15, "seconds":120, "teach":true}
		viewport.add_child(invite)
		await settle()
		check(Rect2(Vector2.ZERO, Vector2(720, height)).encloses(invite._primary.get_global_rect()), "challenge Start fits compact phone %d: %s" % [height, invite._primary.get_global_rect()])
		check(Rect2(Vector2.ZERO, Vector2(720, height)).encloses(invite.find_child("DeclineRestoration", true, false).get_global_rect()), "challenge exit remains visible")
		await capture(viewport, "earned-challenge-%d" % height)
		invite._start()
		await settle()
		check(invite._primary.disabled and invite._practice_buttons.size() == 2, "first encounter has a real untimed swap demonstration")
		invite._swap_practice(0)
		invite._swap_practice(1)
		check(invite._practice_solved and not invite._primary.disabled, "performing the swap enables timed Start")
		await capture(viewport, "practice-%d" % height)
		viewport.queue_free()
		await settle()

func capture(viewport: SubViewport, name: String) -> void:
	if not captures or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.test-data/experience-" + name + ".png")

func integration() -> void:
	var game = preload("res://scenes/game/Game.tscn").instantiate()
	add_child(game)
	await get_tree().create_timer(1).timeout
	game._skip_opening_story()
	game._finish_tutorial()
	if game._campaign_progress.has_section("daily"): game._campaign_progress.erase_section("daily")
	var now := TimeHelper.current_unix_time()
	DailyActivities.offer_for_clear(game._campaign_progress, 3, true, now)
	game._next_level_after_win()
	await settle()
	check(game._portrait_continuation.is_valid() and not DailyActivities.invitation_pending(game._campaign_progress, now), "next-case transition presents an earned opportunity once")
	var resumed := [0]
	game._portrait_continuation = func(): resumed[0] += 1
	check(is_instance_valid(game._restoration_invite) and game._portrait_puzzle == null, "earned challenge opens its invitation before any timed puzzle")
	check(game._campaign_progress.get_value("daily", "attempt", {}).is_empty(), "preview does not save a running attempt")
	game._restoration_invite.show_practice()
	game._restoration_invite._swap_practice(0)
	game._restoration_invite._swap_practice(1)
	check(game._campaign_progress.get_value("tutorials", "restoration_practice", false), "first interaction is remembered")
	var stock: int = game._economy_manager.get_booster_count("rocket")
	game._restoration_invite._start()
	await settle()
	var puzzle: PortraitPuzzle = game._portrait_puzzle
	check(puzzle != null and game._restoration_invite == null, "explicit Start opens the real timed board")
	if puzzle != null:
		var slot := int(puzzle._attempt.slot)
		for index in puzzle._pieces.size():
			if int(puzzle._pieces[index]) != index:
				puzzle._select(index)
				puzzle._select(puzzle._pieces.find(index))
		check(game._economy_manager.get_booster_count("rocket") == stock + 1, "real solved puzzle grants one usable Rocket")
		game._complete_portrait_puzzle(slot)
		check(game._economy_manager.get_booster_count("rocket") == stock + 1, "duplicate UI signal cannot grant another Rocket")
		var saved := ConfigFile.new()
		check(CampaignProgressStore.read(saved, Game.CAMPAIGN_PROGRESS_PATH) == OK and int(saved.get_value("campaign", "boosters", {}).get("rocket", -1)) == stock + 1, "inventory and consumed reward persist together")
	game._close_portrait_puzzle()
	await settle()
	check(resumed[0] == 1, "leaving a reward challenge resumes its original next-case action")
	game._campaign_progress.set_value("preferences", "tutorials", false)
	game._campaign_progress.set_value("daily", "portrait_slot", -1)
	game._open_portrait_puzzle()
	await settle()
	check(is_instance_valid(game._restoration_invite) and not bool(game._restoration_invite.details.teach), "Tutorials off bypasses the demonstration")
	game._close_portrait_puzzle()
	game.get_node("Managers/LevelManager").load_level(1)
	game._current_level_id = 1
	game._campaign_progress.set_value("preferences", "tutorials", true)
	game._campaign_progress.set_value("academy_completed", "first_moves", false)
	game._campaign_progress.set_value("tutorials", "1", false)
	game._start_academy_lesson(game.get_node("Managers/LevelManager").get_level_data())
	check(game._tutorial_overlay._pages.size() == 1 and game._tutorial_action == "academy_lesson", "first case introduces one idea instead of six reading pages")
	game._on_tutorial_acknowledged()
	check(game._tutorial_action == "guided_swap" and not game._board._required_swap.is_empty(), "introduction continues into real-board practice")
	game._finish_tutorial()
	game._show_level_briefing("alone")
	await settle()
	var mission: Control = game._briefing_layer.find_child("MissionCard", true, false)
	check(mission != null, "illustrated mission card opens")
	for label in mission.find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			check(label.get_theme_font_size("font_size") >= 32, "essential briefing lettering is phone-sized: " + label.text)
	if captures and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.test-data/experience-mission.png")
	game.queue_free()
	await settle()
