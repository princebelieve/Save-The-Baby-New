extends Control
class_name PortraitPuzzle

signal closed
signal pieces_changed(slot: int, pieces: Array)
signal completed(slot: int)

var _attempt: Dictionary
var _pieces: Array
var _buttons: Array[Button] = []
var _selected := -1
var _timer_label: Label
var _message: Label
var _running := false
var _started_ticks := 0
var _remaining_on_open := 0.0


func configure(attempt: Dictionary) -> void:
	_attempt = attempt.duplicate(true)
	_pieces = _attempt.pieces.duplicate()
	_remaining_on_open = maxf(0.0, float(_attempt.deadline) - Time.get_unix_time_from_system())
	_started_ticks = Time.get_ticks_msec()
	_running = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#102c2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	_label(content, "RESTORE THE EVIDENCE", 30)
	_label(content, "Tap two pieces to swap them and restore the portrait.", 21)
	_timer_label = _label(content, "", 26)
	_label(content, "Reward: %d coins + today's stamp if needed" % int(DailyActivities.settings().portrait_coins), 20)
	var image := ResourceManager.load_texture(str(_attempt.portrait))
	var reference := TextureRect.new()
	reference.texture = image
	reference.custom_minimum_size = Vector2(100, 120)
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(reference)
	var center := CenterContainer.new()
	content.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	center.add_child(grid)
	var cell_size := minf(150.0, (get_viewport_rect().size.x - 64.0) / 3.0)
	for index in 9:
		var button := Button.new()
		button.name = "Piece%d" % index
		button.custom_minimum_size = Vector2(cell_size, cell_size)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_select.bind(index))
		grid.add_child(button)
		_buttons.append(button)
	_message = _label(content, "Two evidence puzzles daily: 00:00 and 12:00 UTC.", 20)
	var back := Button.new()
	back.text = "Return to trail"
	back.custom_minimum_size.y = 56
	back.pressed.connect(closed.emit)
	content.add_child(back)
	_refresh_pieces(image)


func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _remaining() -> float:
	# Both clocks must allow play: backgrounding or changing the clock cannot add time.
	return minf(float(_attempt.deadline) - Time.get_unix_time_from_system(), _remaining_on_open - float(Time.get_ticks_msec() - _started_ticks) / 1000.0)


func _process(_delta: float) -> void:
	if not _running:
		return
	var seconds := maxi(0, ceili(_remaining()))
	_timer_label.text = "Time remaining: %d:%02d" % [seconds / 60, seconds % 60]
	if seconds <= 0:
		_running = false
		_message.text = "Time is up. Come back for the next evidence puzzle."
		for button in _buttons:
			button.disabled = true


func _select(index: int) -> void:
	if not _running or _remaining() <= 0.0:
		return
	if _selected < 0:
		_selected = index
	elif _selected == index:
		_selected = -1
	else:
		var temporary: int = int(_pieces[index])
		_pieces[index] = _pieces[_selected]
		_pieces[_selected] = temporary
		_selected = -1
		pieces_changed.emit(int(_attempt.slot), _pieces.duplicate())
	_refresh_pieces(ResourceManager.load_texture(str(_attempt.portrait)))
	for piece in 9:
		if int(_pieces[piece]) != piece:
			return
	_running = false
	for button in _buttons:
		button.disabled = true
	completed.emit(int(_attempt.slot))


func show_reward(coins: int, streak: int) -> void:
	_message.text = "Portrait restored! +%d coins\nDaily streak: %d | Added to your collection" % [coins, streak]


func _refresh_pieces(image: Texture2D) -> void:
	if image == null:
		return
	var side := minf(image.get_width(), image.get_height())
	var origin := (image.get_size() - Vector2(side, side)) * 0.5
	for index in 9:
		var piece := int(_pieces[index])
		var atlas := AtlasTexture.new()
		atlas.atlas = image
		atlas.region = Rect2(origin + Vector2(piece % 3, piece / 3) * side / 3.0, Vector2.ONE * side / 3.0)
		_buttons[index].icon = atlas
		_buttons[index].modulate = Color("#f3cc67") if index == _selected else Color.WHITE
