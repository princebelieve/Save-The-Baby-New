extends Node

const CLOCK_PATH := "user://developer_clock.cfg"
const OFFSET_KEY := "developer_clock_offset"
var game: Node
var _layer: CanvasLayer
var _panel: PanelContainer
var _status: Label
var _level: SpinBox
var _route: OptionButton
var _story: CheckBox
var _was_locked := true

static func enabled() -> bool:
	if not OS.is_debug_build():
		return false
	if OS.get_name() == "Android":
		return OS.has_feature("developer_phone")
	return OS.has_feature("editor") and "--developer-tools" in OS.get_cmdline_user_args() and OS.get_user_data_dir().replace("\\","/").contains("/.test-data/developer-play/")

static func restore_clock() -> void:
	if not enabled():
		return
	var saved := ConfigFile.new()
	if saved.load(CLOCK_PATH) == OK:
		Engine.set_meta(OFFSET_KEY,int(saved.get_value("clock","offset",0)))

func initialize(current_game: Node) -> void:
	if not enabled():
		return
	game = current_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.name = "DeveloperTools"
	_layer.layer = 100
	add_child(_layer)
	var button := Button.new()
	button.text = "DEV TOOLS (F8)"
	button.position = Vector2(12,12)
	button.custom_minimum_size = Vector2(190,44)
	button.pressed.connect(toggle)
	_layer.add_child(button)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 12
	_panel.offset_right = -12
	_panel.offset_top = 66
	_panel.offset_bottom = -12
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#102c2b")
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel",style)
	_layer.add_child(_panel)
	var scroll := ScrollContainer.new()
	_panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	var heading := Label.new()
	heading.text = "DEVELOPER PLAY — SEPARATE TEST SAVE"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)
	_level = SpinBox.new()
	_level.min_value = 1
	_level.max_value = int(ConfigLoader.load_config(Constants.ConfigPaths.GAME).get("max_levels",1050))
	_level.value = game._current_level_id
	_level.step = 1
	_level.prefix = "Level "
	content.add_child(_level)
	_route = OptionButton.new()
	for caption in ["Go alone","Trace the signal","Call the police"]:
		_route.add_item(caption)
	content.add_child(_route)
	_story = CheckBox.new()
	_story.text = "Show story and briefing before play"
	content.add_child(_story)
	_action(content,"PLAY SELECTED LEVEL",func(): jump_to(int(_level.value),["alone","signal","police"][_route.selected],_story.button_pressed))
	_action(content,"DAILY REWARDS SCREEN",func(): close(); game._show_daily_rewards())
	_action(content,"CLAIM TODAY'S STAMP (TEST)",claim_stamp)
	_action(content,"NEXT UTC DAY",func(): advance_time("day"))
	_action(content,"SKIP ONE DAY (TEST STREAK GRACE)",func(): advance_time("miss"))
	_action(content,"NEXT PORTRAIT SLOT",func(): advance_time("slot"))
	_action(content,"PLAY PORTRAIT PUZZLE",func(): close(); game._open_portrait_puzzle())
	_action(content,"REFILL TEST LIVES AND BOOSTERS",refill_supplies)
	_action(content,"RESET DAILY TEST PROGRESS",reset_daily)
	_action(content,"CLOSE DEVELOPER TOOLS",close)
	_panel.hide()
	_refresh("Choose any level, or test daily rewards without waiting.")

func _action(parent: Control, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	parent.add_child(button)

func _unhandled_key_input(event: InputEvent) -> void:
	if enabled() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if _panel.visible:
		close()
		return
	if is_instance_valid(game._board) and not game._board.is_stable():
		game._show_shop_notice("Let the current move finish before opening developer tools.")
		return
	_was_locked = not is_instance_valid(game._board) or game._board.is_locked()
	if is_instance_valid(game._board):
		game._board.cancel_pointer_gesture()
		game._board.lock()
	_panel.show()
	_refresh()

func close() -> void:
	_panel.hide()
	if is_instance_valid(game._board) and not _was_locked:
		game._board.unlock()

func _refresh(message := "") -> void:
	var now := TimeHelper.current_unix_time()
	var state: ConfigFile = game._campaign_progress
	_status.text = "Test UTC: %s\nLevel: %d | Coins: %d | Streak: %d | Stamped today: %s\n%s" % [Time.get_datetime_string_from_unix_time(now).replace("T"," "),game._current_level_id,game._economy_manager.get_coins(),int(state.get_value("daily","streak",0)),"Yes" if int(state.get_value("daily","last_day",-1)) == DailyActivities.day_at(now) else "No",message]

func jump_to(level_id: int, route := "alone", with_story := false) -> bool:
	if not enabled() or route not in ["alone","signal","police"]:
		return false
	var manager: Node = game.get_node("Managers/LevelManager")
	if not manager.has_level(level_id):
		_refresh("That level does not exist.")
		return false
	if is_instance_valid(game._board) and not game._board.is_stable():
		_refresh("Wait for the current move to finish.")
		return false
	close()
	game._close_pause_menu()
	game._close_daily_rewards()
	game._close_portrait_puzzle()
	game._close_case_file()
	game._dismiss_level_result()
	game.get_tree().paused = false
	game._pending_level_id = 0
	game._pending_story_id = ""
	game._highest_unlocked_level = int(_level.max_value)
	game._current_route_id = route
	game._economy_manager.set_lives(5)
	if is_instance_valid(game._launch_layer):
		game._launch_layer.queue_free()
	game._launch_layer = null
	game._persist_campaign_progress()
	if with_story:
		game._on_campaign_level_selected(level_id,route)
	else:
		if not manager.load_level(level_id):
			return false
		game._begin_level(route)
		game._finish_tutorial()
	return true

func claim_stamp() -> Dictionary:
	if not enabled():
		return {}
	var result := DailyActivities.stamp(game._campaign_progress,TimeHelper.current_unix_time())
	if not result.is_empty():
		game._grant_activity_coins(int(result.coins))
	game._persist_campaign_progress()
	_refresh("Already stamped today; advance the test day." if result.is_empty() else "Stamp awarded: +%d coins. Uses the real daily reward rules." % int(result.coins))
	return result

func advance_time(kind: String) -> void:
	if not enabled() or kind not in ["day","miss","slot"]:
		return
	var now := TimeHelper.current_unix_time()
	var period := 86400 if kind != "slot" else int(DailyActivities.settings().slot_hours)*3600
	var next := (int(now/period)+(2 if kind == "miss" else 1))*period+60
	var offset := next-int(Time.get_unix_time_from_system())
	Engine.set_meta(OFFSET_KEY,offset)
	var saved := ConfigFile.new()
	saved.set_value("clock","offset",offset)
	saved.save(CLOCK_PATH)
	# An active portrait uses a monotonic countdown; close it at a simulated reset.
	game._close_portrait_puzzle()
	if is_instance_valid(game._campaign_map):
		game._campaign_map.configure_daily(game._campaign_progress)
	_refresh("Test time advanced. Windows time is unchanged.")

func refill_supplies() -> void:
	if not enabled():
		return
	game._economy_manager.set_lives(5)
	for kind in ["rocket","bomb","thunder"]:
		game._economy_manager.set_booster_count(kind,20)
	game._economy_manager.set_ethan_count(2)
	game._save_inventory_progress()
	_refresh("Test supplies refilled. No purchase was made.")

func reset_daily() -> void:
	if not enabled():
		return
	game._close_portrait_puzzle()
	if game._campaign_progress.has_section("daily"):
		game._campaign_progress.erase_section("daily")
	game._persist_campaign_progress()
	_refresh("Daily test progress reset; test coins are retained.")
