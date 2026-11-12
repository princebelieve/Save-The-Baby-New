extends Control
class_name PortraitPuzzle

signal map_requested
signal settings_requested
signal case_file_requested
signal closed
signal pieces_changed(slot: int, pieces: Array)
signal completed(slot: int)
signal save_requested

var _attempt: Dictionary
var _pieces: Array
var _buttons: Array[Button] = []
var _columns := 3
var _rows := 3
var _selected := -1
var _timer_label: Label
var _message: Label
var _running := false
var _started_ticks := 0
var _remaining_on_open := 0.0
var _save_button: Button
var _grid: GridContainer
var _image: Texture2D
var _progress_label: Label
var _board_host: CenterContainer
var _menu: Control
var _overlay: Control
var _gallery_message: Label
var _swipe_from := -1
var _swipe_start := Vector2.ZERO
var _suppress_tap := false


func configure(attempt: Dictionary) -> void:
	_attempt = attempt.duplicate(true)
	_pieces = _attempt.pieces.duplicate()
	_columns = int(_attempt.get("columns", 3))
	_rows = int(_attempt.get("rows", 3))
	_remaining_on_open = maxf(0.0, float(_attempt.deadline) - TimeHelper.current_unix_time())
	_started_ticks = Time.get_ticks_msec()
	_running = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MobileGameUI.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var content := MobileGameUI.column(margin, 16)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	MobileGameUI.button(heading, "<", closed.emit, MobileGameUI.PURPLE).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var title := MobileGameUI.label(heading, "Restore evidence", 42)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MobileGameUI.button(heading, "Menu", _show_menu, MobileGameUI.PURPLE).size_flags_horizontal = Control.SIZE_SHRINK_END
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	content.add_child(hud)
	var clock := MobileGameUI.card(hud, MobileGameUI.PURPLE)
	clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var clock_content := MobileGameUI.column(clock, 0)
	MobileGameUI.label(clock_content, "TIME", 32, Color.WHITE)
	_timer_label = MobileGameUI.label(clock_content, "2:00", 56, Color.WHITE)
	var progress := MobileGameUI.card(hud, MobileGameUI.TEAL)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var progress_content := MobileGameUI.column(progress, 0)
	MobileGameUI.label(progress_content, "RESTORED", 32, Color.WHITE)
	_progress_label = MobileGameUI.label(progress_content, "0 / %d" % _pieces.size(), 44, Color.WHITE)
	var reward := MobileGameUI.card(hud, MobileGameUI.PINK)
	reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reward_content := MobileGameUI.column(reward, 0)
	MobileGameUI.image(reward_content, MobileGameUI.COIN, Vector2(56, 42))
	MobileGameUI.label(reward_content, "+%d" % int(DailyActivities.settings().portrait_coins), 56, Color.WHITE)
	_image = ResourceManager.load_texture(str(_attempt.portrait))
	_board_host = CenterContainer.new()
	_board_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_board_host)
	var frame := MobileGameUI.card(_board_host, Color("#334064"))
	_grid = GridContainer.new()
	_grid.columns = _columns
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 3)
	frame.add_child(_grid)
	for index in _pieces.size():
		var button := Button.new()
		button.name = "Piece%d" % index
		button.add_theme_color_override("icon_disabled_color", Color.WHITE)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#334064")
			style.set_content_margin_all(0)
			if state == "focus":
				style.bg_color = Color.TRANSPARENT
				style.border_color = MobileGameUI.GOLD
				style.set_border_width_all(5)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(func():
			if not _suppress_tap: _select(index))
		button.gui_input.connect(_piece_input.bind(index))
		_grid.add_child(button)
		_buttons.append(button)
	_message = MobileGameUI.label(content, "Swipe a fragment, or tap two to swap", 34)
	_gallery_message = MobileGameUI.label(content, "", 32)
	_gallery_message.hide()
	_save_button = MobileGameUI.button(content, "Save image", save_requested.emit, MobileGameUI.PINK)
	_save_button.hide()
	MobileGameUI.button(content, "View reference", _show_help)
	_board_host.resized.connect(_resize_board)
	_refresh_pieces(_image)
	call_deferred("_resize_board")


func _show_help() -> void:
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.1, 0.22, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_overlay.add_child(margin)
	var column := MobileGameUI.column(margin)
	MobileGameUI.label(column, "Reference image", 44, Color.WHITE)
	var picture := MobileGameUI.image(column, str(_attempt.portrait))
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MobileGameUI.label(column, "Swipe one fragment onto another, or tap two.\nThe timer keeps running.", 34, Color.WHITE)
	MobileGameUI.button(column, "Resume restoration", func(): _overlay.queue_free())


func _remaining() -> float:
	# Both clocks must allow play: backgrounding or changing the clock cannot add time.
	return minf(float(_attempt.deadline) - TimeHelper.current_unix_time(), _remaining_on_open - float(Time.get_ticks_msec() - _started_ticks) / 1000.0)


func _process(_delta: float) -> void:
	if not _running:
		return
	var seconds := maxi(0, ceili(_remaining()))
	_timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	if seconds <= 0:
		_running = false
		_message.text = "Time expired"
		for button in _buttons:
			button.disabled = true


func _select(index: int) -> void:
	if not _running or _remaining() <= 0.0:
		return
	if _selected < 0:
		_selected = index
		SignalBus.play_sfx.emit("booster_select")
	elif _selected == index:
		_selected = -1
	else:
		var first := _selected
		var was_correct := int(_pieces[first]) == first
		var other_was_correct := int(_pieces[index]) == index
		var old_first: Texture2D = _buttons[first].icon
		var old_second: Texture2D = _buttons[index].icon
		var temporary: int = int(_pieces[index])
		_pieces[index] = _pieces[_selected]
		_pieces[_selected] = temporary
		_selected = -1
		SignalBus.play_sfx.emit("tile_swap")
		if (int(_pieces[first]) == first and not was_correct) or (int(_pieces[index]) == index and not other_was_correct):
			SignalBus.play_sfx.emit("tile_match")
		pieces_changed.emit(int(_attempt.slot), _pieces.duplicate())
		_refresh_pieces(_image)
		_animate_swap(first, index, old_first, old_second)
	_refresh_pieces(ResourceManager.load_texture(str(_attempt.portrait)))
	for piece in _pieces.size():
		if int(_pieces[piece]) != piece:
			return
	_running = false
	for button in _buttons:
		button.disabled = true
	completed.emit(int(_attempt.slot))
	SignalBus.play_sfx.emit("win_sting")


func _piece_input(event: InputEvent, index: int) -> void:
	if not _running or is_instance_valid(_menu) or is_instance_valid(_overlay): return
	var down := false
	var released := false
	var point := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed
		released = not event.pressed
		point = _buttons[index].get_global_transform() * event.position
	elif event is InputEventScreenTouch:
		if event.index != 0: return
		down = event.pressed
		released = not event.pressed
		point = _buttons[index].get_global_transform() * event.position
	else: return
	if down:
		_swipe_from = index
		_swipe_start = point
	elif released and _swipe_from == index:
		_swipe_from = -1
		if point.distance_to(_swipe_start) < 18.0: return
		for target in _buttons.size():
			if target != index and _buttons[target].get_global_rect().has_point(point):
				_suppress_tap = true
				_selected = index
				_select(target)
				call_deferred("_release_swipe")
				return


func _release_swipe() -> void:
	_suppress_tap = false


func _animate_swap(first: int, second: int, first_image: Texture2D, second_image: Texture2D) -> void:
	for pair in [[first, second, first_image], [second, first, second_image]]:
		var ghost := TextureRect.new()
		ghost.texture = pair[2]
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.position = get_global_transform().affine_inverse() * _buttons[pair[0]].get_global_rect().position
		ghost.size = _buttons[pair[0]].size
		ghost.z_index = 5
		add_child(ghost)
		var tween := create_tween()
		tween.tween_property(ghost, "position", get_global_transform().affine_inverse() * _buttons[pair[1]].get_global_rect().position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(ghost.queue_free)


func show_reward(coins: int, streak: int, booster: String = "", points: int = 0) -> void:
	_running = false
	_message.text = "Evidence restored! +%d coins" % coins
	if points > 0: _message.text += "\n+%d points" % points
	_timer_label.text = "DONE"
	_progress_label.text = "%d / %d" % [_pieces.size(), _pieces.size()]
	_save_button.tooltip_text = "%d day streak" % streak
	_save_button.show()
	if not booster.is_empty() and not _message.get_parent().has_node("EarnedSupply"):
		var supply := HBoxContainer.new()
		supply.name = "EarnedSupply"
		supply.alignment = BoxContainer.ALIGNMENT_CENTER
		_message.get_parent().add_child(supply)
		_message.get_parent().move_child(supply, _message.get_index() + 1)
		MobileGameUI.image(supply, "res://assets/sprites/powerups/" + booster + "_powerup_icon.jpeg", Vector2(70, 70))
		MobileGameUI.display_label(supply, "+1 " + booster.capitalize() + " earned!", 40)

func show_gallery_status(message: String) -> void:
	_gallery_message.text = message
	_gallery_message.visible = not message.is_empty()


func _refresh_pieces(image: Texture2D) -> void:
	if image == null:
		return
	var placed := 0
	for index in _pieces.size():
		if int(_pieces[index]) == index: placed += 1
	_progress_label.text = "%d / %d" % [placed, _pieces.size()]
	var piece_size := image.get_size() / Vector2(_columns, _rows)
	for index in _pieces.size():
		var piece := int(_pieces[index])
		var atlas := AtlasTexture.new()
		atlas.atlas = image
		atlas.region = Rect2(Vector2(piece % _columns, piece / _columns) * piece_size, piece_size)
		_buttons[index].icon = atlas
		_buttons[index].modulate = Color("#f3cc67") if index == _selected else Color.WHITE


func _resize_board() -> void:
	if _image == null or _grid == null or _board_host == null:
		return
	var available := _board_host.size - Vector2(42, 42)
	var ratio := _image.get_size().aspect()
	var width := minf(available.x, maxf(120.0, available.y) * ratio)
	var cell := (Vector2(width, width / ratio) - Vector2((_columns - 1) * 3, (_rows - 1) * 3)) / Vector2(_columns, _rows)
	for button in _buttons:
		button.custom_minimum_size = cell


func go_back() -> void:
	if is_instance_valid(_menu):
		_menu.queue_free()
	elif is_instance_valid(_overlay):
		_overlay.queue_free()
	else:
		closed.emit()


func _show_menu() -> void:
	if is_instance_valid(_menu): return
	_menu = MobileGameUI.field_menu(self, settings_requested.emit, case_file_requested.emit, map_requested.emit)
