extends Control
class_name RewardsHub

signal map_requested
signal settings_requested
signal case_file_requested
signal closed
signal play_requested
signal supply_claim_requested(key: String)

var _progress: ConfigFile
var _gallery: Node
var _page := "home"
var _day := 0
var _portrait := 0
var _menu: Control
var _body: VBoxContainer
var _title: Label
var _history: Array[String] = []
var _status: Label
var _last_day := -1


func configure(progress: ConfigFile, gallery: Node) -> void:
	_progress = progress
	_gallery = gallery


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MobileGameUI.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := MobileGameUI.column(margin, 16)
	var header := HBoxContainer.new()
	column.add_child(header)
	MobileGameUI.button(header, "<", go_back, MobileGameUI.PURPLE).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_title = MobileGameUI.label(header, "Case rewards", 46)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MobileGameUI.button(header, "Menu", _show_menu, MobileGameUI.PURPLE).size_flags_horizontal = Control.SIZE_SHRINK_END
	_body = MobileGameUI.column(column, 16)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_day = _current_reward_day()
	_last_day = DailyActivities.day_at(TimeHelper.current_unix_time())
	_gallery.status_changed.connect(_gallery_status)
	_render()


func _process(_delta: float) -> void:
	var today := DailyActivities.day_at(TimeHelper.current_unix_time())
	if today != _last_day:
		_last_day = today
		_day = _current_reward_day()
		_render()


func go_back() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
		return
	if _history.is_empty():
		closed.emit()
	else:
		_page = _history.pop_back()
		_render()


func _open(page: String) -> void:
	_history.append(_page)
	_page = page
	_render()


func _render() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_status = null
	match _page:
		"home": _home()
		"daily": _daily()
		"album": _album()
		"portrait": _viewer()
		"goals": _goals()
		"settings": _settings()
		"rules": _rules()
		"prizes": _prizes()
	MobileGameUI.present(_body)


func _home() -> void:
	_title.text = "Case rewards"
	MobileGameUI.spacer(_body)
	var streak := int(_progress.get_value("daily", "streak", 0))
	var hero := MobileGameUI.card(_body, MobileGameUI.PURPLE)
	var column := MobileGameUI.column(hero, 0)
	MobileGameUI.label(column, str(streak), 100, Color.WHITE)
	MobileGameUI.label(column, "DAYS ON THE CASE", 36, Color.WHITE)
	MobileGameUI.button(_body, "Daily briefing  >", func(): _open("daily"), MobileGameUI.PINK)
	var offer := DailyActivities.earned_offer(_progress, TimeHelper.current_unix_time())
	var active := DailyActivities.active_attempt(_progress, TimeHelper.current_unix_time())
	if not offer.is_empty() or not active.is_empty():
		MobileGameUI.button(_body, "Resume earned challenge" if not active.is_empty() else "Earned challenge: +1 Rocket", play_requested.emit, MobileGameUI.TEAL)
	var collection: Dictionary = _progress.get_value("daily", "portraits", {})
	var collected := 0
	for path in DailyActivities.settings().portraits:
		if int(collection.get(str(path), 0)) > 0: collected += 1
	MobileGameUI.button(_body, "Evidence archive  %d / %d  >" % [collected, DailyActivities.settings().portraits.size()], func(): _open("album"))
	MobileGameUI.button(_body, "Field objectives  >", func(): _open("goals"), MobileGameUI.PURPLE)
	var pending: Dictionary = _progress.get_value("daily", "supply_rewards", {})
	if not pending.is_empty():
		MobileGameUI.button(_body, "%d rewards ready!" % pending.size(), func(): _open("prizes"), MobileGameUI.PINK)
	MobileGameUI.spacer(_body)
	MobileGameUI.button(_body, "Archive settings", func(): _open("settings"), MobileGameUI.PURPLE)


func _current_reward_day() -> int:
	var streak := int(_progress.get_value("daily", "streak", 0))
	var now := TimeHelper.current_unix_time()
	var today := DailyActivities.day_at(now)
	var previous := int(_progress.get_value("daily", "last_day", -1))
	if previous == today:
		return maxi(0, streak - 1) % 7
	var protected := today - previous == 2 and today - int(_progress.get_value("daily", "grace_day", -100)) >= int(DailyActivities.settings().grace_cooldown_days)
	return streak % 7 if today - previous == 1 or protected else 0


func _daily() -> void:
	_title.text = "Daily briefing"
	var config := DailyActivities.settings()
	var today := DailyActivities.day_at(TimeHelper.current_unix_time())
	var stamped := int(_progress.get_value("daily", "last_day", -1)) == today
	var stamps := HBoxContainer.new()
	stamps.alignment = BoxContainer.ALIGNMENT_CENTER
	stamps.add_theme_constant_override("separation", 6)
	_body.add_child(stamps)
	var reached := _current_reward_day()
	for index in 7:
		var stamp := MobileGameUI.card(stamps, MobileGameUI.TEAL if index < reached or (index == reached and stamped) else Color("#e8e1f1"))
		stamp.custom_minimum_size.x = 72
		var style := MobileGameUI.style(MobileGameUI.TEAL if index < reached or (index == reached and stamped) else Color("#e8e1f1"), 16)
		style.set_content_margin_all(6)
		stamp.add_theme_stylebox_override("panel", style)
		MobileGameUI.display_label(stamp, str(index + 1), 36, Color.WHITE if index < reached or (index == reached and stamped) else MobileGameUI.INK)
	var hero := MobileGameUI.card(_body, MobileGameUI.PURPLE)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := MobileGameUI.column(hero, 6)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	MobileGameUI.image(column, MobileGameUI.COIN, Vector2(140, 100))
	MobileGameUI.label(column, "+%d" % int(config.streak_coins[_day]), 80, Color.WHITE)
	MobileGameUI.label(column, ("Briefing complete" if stamped else "Today's briefing") if _day == _current_reward_day() else "Reward preview", 34, Color.WHITE)
	MobileGameUI.display_label(_body, "Today's stamp earned!" if stamped else "Win a case to earn today's stamp.", 36)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 16)
	_body.add_child(pages)
	MobileGameUI.button(pages, "<", _change_day.bind(-1)).disabled = _day == 0
	MobileGameUI.label(pages, "%d / 7" % (_day + 1), 36).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MobileGameUI.button(pages, ">", _change_day.bind(1)).disabled = _day == 6
	MobileGameUI.button(_body, "Play next case", map_requested.emit, MobileGameUI.PINK)
	MobileGameUI.button(_body, "How rewards work", func(): _open("rules"), MobileGameUI.PURPLE)


func _change_day(direction: int) -> void:
	_day = clampi(_day + direction, 0, 6)
	_render()


func _portrait_path() -> String:
	return str(DailyActivities.settings().portraits[_portrait])


func _portrait_count() -> int:
	var collection: Dictionary = _progress.get_value("daily", "portraits", {})
	return int(collection.get(_portrait_path(), 0))


func _portrait_name() -> String:
	return DailyActivities.artwork_title(_portrait_path())


func _album() -> void:
	_title.text = "Evidence archive"
	MobileGameUI.label(_body, _portrait_name(), 42)
	var card := MobileGameUI.card(_body, Color("#334064"))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var picture := MobileGameUI.image(card, _portrait_path())
	picture.modulate = Color.WHITE if _portrait_count() > 0 else Color(0.55, 0.55, 0.65)
	MobileGameUI.label(_body, "Collected" if _portrait_count() > 0 else "Restore this image to unlock", 34)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 16)
	_body.add_child(pages)
	MobileGameUI.button(pages, "<", _change_portrait.bind(-1)).disabled = _portrait == 0
	MobileGameUI.label(pages, "%d / %d" % [_portrait + 1, DailyActivities.settings().portraits.size()], 36).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MobileGameUI.button(pages, ">", _change_portrait.bind(1)).disabled = _portrait == DailyActivities.settings().portraits.size() - 1
	MobileGameUI.button(_body, "Open image", func(): _open("portrait"), MobileGameUI.PINK).disabled = _portrait_count() <= 0


func _change_portrait(direction: int) -> void:
	_portrait = clampi(_portrait + direction, 0, DailyActivities.settings().portraits.size() - 1)
	_render()


func _viewer() -> void:
	_title.text = _portrait_name()
	if _portrait_count() <= 0:
		go_back()
		return
	var picture := MobileGameUI.image(_body, _portrait_path())
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MobileGameUI.label(_body, "Restored once" if _portrait_count() == 1 else "Restored %d times" % _portrait_count(), 36)
	_status = MobileGameUI.label(_body, "", 32)
	_status.hide()
	if _gallery.supported():
		MobileGameUI.button(_body, "Save to phone", func(): _gallery.save_collection(_portrait_path(), _progress), MobileGameUI.PINK)
	MobileGameUI.button(_body, "Back to archive", go_back)


func _gallery_status(message: String) -> void:
	if is_instance_valid(_status):
		_status.text = message
		_status.show()


func _goals() -> void:
	_title.text = "Field objectives"
	var today := DailyActivities.day_at(TimeHelper.current_unix_time())
	var counts: Dictionary = _progress.get_value("daily", "missions", {}) if int(_progress.get_value("daily", "mission_day", -1)) == today else {}
	MobileGameUI.spacer(_body)
	for mission in DailyActivities.settings().missions:
		var card := MobileGameUI.card(_body)
		var column := MobileGameUI.column(card)
		MobileGameUI.label(column, str(mission.title), 38)
		var amount := mini(int(mission.target), int(counts.get(str(mission.id), 0)))
		MobileGameUI.label(column, "%d / %d  |  +%d coins" % [amount, int(mission.target), int(mission.coins)], 36, MobileGameUI.PURPLE)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 32
		bar.max_value = int(mission.target)
		bar.value = amount
		bar.show_percentage = false
		var track := MobileGameUI.style(Color("#d8dce7"), 12)
		track.set_content_margin_all(0)
		var fill := MobileGameUI.style(MobileGameUI.TEAL, 12)
		fill.set_content_margin_all(0)
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		column.add_child(bar)
		var kind := str(mission.get("supply", ""))
		if not kind.is_empty():
			MobileGameUI.reward_tile(column, kind, 1, "Task prize")
	MobileGameUI.spacer(_body)
	MobileGameUI.button(_body, "Back to case rewards", go_back)


func _prizes() -> void:
	_title.text = "Your earned prizes"
	MobileGameUI.spacer(_body)
	var pending: Dictionary = _progress.get_value("daily", "supply_rewards", {})
	# One claim at a time keeps the screen usable even after a long absence.
	if not pending.is_empty():
		var key: String = str(pending.keys()[0])
		var reward: Dictionary = pending[key]
		MobileGameUI.reward_tile(_body, str(reward.kind), 1)
		MobileGameUI.button(_body, "Claim reward", supply_claim_requested.emit.bind(key), MobileGameUI.PINK)
	else:
		MobileGameUI.display_label(_body, "All prizes collected!", 40)
	MobileGameUI.spacer(_body)
	MobileGameUI.button(_body, "Back to case rewards", go_back)


func _settings() -> void:
	_title.text = "Archive settings"
	MobileGameUI.spacer(_body)
	MobileGameUI.label(_body, "Save restored portraits to your phone's photo gallery.", 38)
	if _gallery.supported():
		var toggle := CheckButton.new()
		toggle.text = "Save automatically"
		toggle.custom_minimum_size.y = 100
		toggle.add_theme_font_size_override("font_size", 36)
		toggle.button_pressed = _gallery.auto_save()
		toggle.toggled.connect(_gallery.set_auto_save)
		_body.add_child(toggle)
	else:
		MobileGameUI.label(_body, "Photo saving is available on Android.", 34)
	MobileGameUI.spacer(_body)
	MobileGameUI.button(_body, "Back to case rewards", go_back)


func _rules() -> void:
	_title.text = "Reward rules"
	var config := DailyActivities.settings()
	MobileGameUI.spacer(_body)
	MobileGameUI.label(_body, "Complete a case or portrait to earn one daily stamp.\n\nRewards repeat every 7 stamps.\n\nOne missed day is protected every %d days.\n\n%d stamps in a week earns +%d coins." % [int(config.grace_cooldown_days), int(config.weekly_days), int(config.weekly_coins)], 34)
	MobileGameUI.spacer(_body)
	MobileGameUI.label(_body, "Daily reset: 00:00 UTC\nNew puzzles: 00:00 & 12:00 UTC", 32)
	MobileGameUI.button(_body, "Back to briefing", go_back)


func _show_menu() -> void:
	if is_instance_valid(_menu): return
	_menu = MobileGameUI.field_menu(self, settings_requested.emit, case_file_requested.emit, map_requested.emit)
