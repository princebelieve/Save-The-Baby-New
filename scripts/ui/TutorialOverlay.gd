extends Control
class_name TutorialOverlay

signal acknowledged
signal skipped
signal page_presented(index: int, message: String)
signal help_settings_requested

const SHADE := Color(0.10, 0.065, 0.03, 0.78)

var _spotlight := Rect2()
var _shade_panels: Array[ColorRect] = []
var _bubble: Panel
var _top_scroll_roll: Panel
var _bottom_scroll_roll: Panel
var _speaker_portrait: TextureRect
var _heading: Label
var _body_label: Label
var _pointer: Polygon2D
var _gesture_hand: Polygon2D
var _gesture_outline: Line2D
var _gesture_tween: Tween
var _page_typing_tween: Tween
var _acknowledge_button: Button
var _body_scroll: ScrollContainer
var _skip_button: Button
var _previous_button: Button
var _pages: Array[String] = []
var _page := 0
var _needs_ack := false
var _source_indices: Array[int] = []
var _source_texts: Array[String] = []
var _last_chunks: Array[bool] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for index in 4:
		var shade := ColorRect.new()
		shade.color = SHADE
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(shade)
		_shade_panels.append(shade)
	_build_bubble()
	_build_gesture_hand()
	hide()


func show_tip(message: String, target_rect: Rect2, speaker_name: String = "DAVID", portrait_path: String = "", needs_acknowledgement: bool = false, keep_board_bright: bool = false, show_gesture: bool = false) -> void:
	_spotlight = target_rect
	for shade in _shade_panels:
		shade.color = Color(SHADE.r, SHADE.g, SHADE.b, 0.12 if keep_board_bright else SHADE.a)
	_pages.clear()
	_source_indices.clear()
	_source_texts.clear()
	_last_chunks.clear()
	var width := minf(570.0, get_viewport_rect().size.x - 36.0)
	var text_width := maxf(120.0, width - 68.0 - (104.0 if not portrait_path.is_empty() else 0.0))
	var font := _body_label.get_theme_font("font")
	var paragraphs := message.split("\n", false)
	for source_index in paragraphs.size():
		var paragraph := paragraphs[source_index].strip_edges()
		var chunk := ""
		for word in paragraph.split(" ", false):
			var candidate := chunk + (" " if not chunk.is_empty() else "") + word
			if not chunk.is_empty() and font.get_multiline_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, text_width, 22).y > font.get_height(22) * 2.0 + 2.0:
				_append_chunk(chunk, source_index, paragraph, false)
				chunk = ""
			chunk += (" " if not chunk.is_empty() else "") + word
		if not chunk.is_empty(): _append_chunk(chunk, source_index, paragraph, true)
	if _pages.is_empty(): _append_chunk(message, 0, message, true)
	_page = 0
	_needs_ack = needs_acknowledgement
	_update_page()
	_heading.text = speaker_name.to_upper()
	_speaker_portrait.texture = ResourceManager.load_texture(portrait_path) if not portrait_path.is_empty() else null
	if portrait_path.ends_with("david_portrait_v2.png") and _speaker_portrait.texture != null:
		var source := _speaker_portrait.texture
		var face := AtlasTexture.new()
		face.atlas = source
		face.region = Rect2(source.get_size() * Vector2(0.15, 0), source.get_size() * Vector2(0.72, 0.58))
		_speaker_portrait.texture = face
	_speaker_portrait.visible = _speaker_portrait.texture != null

	_gesture_hand.visible = show_gesture
	_gesture_outline.visible = show_gesture
	show()
	_layout_tip()
	_animate_gesture_hand(keep_board_bright)
	_emit_page_presented()
	_bubble.scale = Vector2(0.94, 0.94)
	_bubble.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bubble, "modulate:a", 1.0, 0.16)


func hide_tip() -> void:
	hide()
	if _page_typing_tween != null and _page_typing_tween.is_running():
		_page_typing_tween.kill()
	if _gesture_tween != null and _gesture_tween.is_running():
		_gesture_tween.kill()
	_gesture_hand.hide()
	_gesture_outline.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and visible:
		_layout_tip()


func _build_bubble() -> void:
	_bubble = Panel.new()
	_bubble.name = "TutorialSpeechBubble"
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.clip_contents = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff3cf")
	style.border_color = Color("#dc8735")
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.set_content_margin(SIDE_LEFT, 22)
	style.set_content_margin(SIDE_TOP, 14)
	style.set_content_margin(SIDE_RIGHT, 22)
	style.set_content_margin(SIDE_BOTTOM, 14)
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 12
	_bubble.add_theme_stylebox_override("panel", style)
	add_child(_bubble)
	var bubble_content := VBoxContainer.new()
	bubble_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bubble_content.offset_left = 22
	bubble_content.offset_top = 106
	bubble_content.offset_right = -22
	bubble_content.offset_bottom = -14
	bubble_content.add_theme_constant_override("separation", 6)
	bubble_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(bubble_content)
	var guide_title := Label.new()
	guide_title.text = "FIELD GUIDE"
	guide_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	guide_title.offset_left = 22
	guide_title.offset_right = -110
	guide_title.offset_top = 22
	guide_title.offset_bottom = 92
	guide_title.add_theme_font_size_override("font_size", 32)
	guide_title.add_theme_color_override("font_color", Color("#4b2d1a"))
	_bubble.add_child(guide_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_content.add_child(row)
	_speaker_portrait = TextureRect.new()
	_speaker_portrait.custom_minimum_size = Vector2(92, 112)
	_speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_portrait.hide()
	row.add_child(_speaker_portrait)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(content)
	_heading = Label.new()
	_heading.text = "DAVID"
	_heading.add_theme_font_size_override("font_size", 32)
	_heading.add_theme_color_override("font_color", Color("#995221"))
	_heading.add_theme_color_override("font_outline_color", Color("#fffaf0"))
	_heading.add_theme_constant_override("outline_size", 2)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_heading)
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 32)
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_body_label.add_theme_color_override("font_color", Color("#4b2d1a"))
	_body_label.add_theme_color_override("font_outline_color", Color("#fffaf0"))
	_body_label.add_theme_constant_override("outline_size", 1)
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_body_scroll)
	_body_scroll.add_child(_body_label)
	_acknowledge_button = Button.new()
	_acknowledge_button.text = "CONTINUE"
	_acknowledge_button.custom_minimum_size = Vector2(220, 92)
	_acknowledge_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_acknowledge_button.add_theme_font_size_override("font_size", 32)
	_acknowledge_button.add_theme_color_override("font_color", Color("#4b2d1a"))
	var ack_style := StyleBoxFlat.new()
	ack_style.bg_color = Color("#d8b77b")
	ack_style.border_color = Color("#dc8735")
	ack_style.set_border_width_all(2)
	ack_style.set_corner_radius_all(12)
	_acknowledge_button.add_theme_stylebox_override("normal", ack_style)
	var ack_hover := ack_style.duplicate() as StyleBoxFlat
	ack_hover.bg_color = Color("#ead09b")
	_acknowledge_button.add_theme_stylebox_override("hover", ack_hover)
	_acknowledge_button.pressed.connect(_next_page)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	bubble_content.add_child(footer)
	_previous_button = Button.new()
	_previous_button.text = "BACK"
	_previous_button.custom_minimum_size = Vector2(120, 92)
	_previous_button.add_theme_font_size_override("font_size", 32)
	_previous_button.pressed.connect(_previous_page)
	footer.add_child(_previous_button)
	var help_settings := Button.new()
	help_settings.name = "HelpSettings"
	help_settings.text = "HELP SETTINGS"
	help_settings.custom_minimum_size = Vector2(172, 64)
	help_settings.tooltip_text = "Turn move hints and tutorials on or off."
	help_settings.pressed.connect(func(): help_settings_requested.emit())
	bubble_content.add_child(help_settings)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	footer.add_child(_acknowledge_button)
	_skip_button = Button.new()
	_skip_button.text = "X"
	_skip_button.custom_minimum_size = Vector2(92, 92)
	_skip_button.tooltip_text = "Skip coaching"
	_skip_button.add_theme_color_override("font_color", Color("#4b2d1a"))
	_skip_button.pressed.connect(func():
		hide_tip()
		skipped.emit())
	_bubble.add_child(_skip_button)
	_top_scroll_roll = _make_scroll_roll()
	_bottom_scroll_roll = _make_scroll_roll()
	_bubble.add_child(_top_scroll_roll)
	_bubble.add_child(_bottom_scroll_roll)
	_pointer = Polygon2D.new()
	_pointer.color = Color("#fff3cf")
	add_child(_pointer)


func _layout_tip() -> void:
	if _shade_panels.size() != 4 or _bubble == null:
		return
	var viewport := get_viewport_rect().size
	var hole := _spotlight.grow(12.0)
	hole.position.x = clampf(hole.position.x, 12.0, viewport.x - 24.0)
	hole.position.y = clampf(hole.position.y, 12.0, viewport.y - 24.0)
	hole.size.x = clampf(hole.size.x, 36.0, viewport.x - hole.position.x - 12.0)
	hole.size.y = clampf(hole.size.y, 36.0, viewport.y - hole.position.y - 12.0)
	_set_panel(_shade_panels[0], Vector2.ZERO, Vector2(viewport.x, hole.position.y))
	_set_panel(_shade_panels[1], Vector2(0, hole.position.y), Vector2(hole.position.x, hole.size.y))
	_set_panel(_shade_panels[2], Vector2(hole.end.x, hole.position.y), Vector2(viewport.x - hole.end.x, hole.size.y))
	_set_panel(_shade_panels[3], Vector2(0, hole.end.y), Vector2(viewport.x, viewport.y - hole.end.y))

	var bubble_width := minf(570.0, viewport.x - 36.0)
	var portrait_width := 104.0 if _speaker_portrait.visible else 0.0
	var body_width := maxf(120.0, bubble_width - 68.0 - portrait_width)
	var font := _body_label.get_theme_font("font")
	var body_height := ceilf(font.get_multiline_string_size(_body_label.text, HORIZONTAL_ALIGNMENT_LEFT, body_width, 32).y) + 24.0
	var action_height := (100.0 if _acknowledge_button.visible else 0.0) + 76.0
	var visible_body_height := minf(body_height, viewport.y * 0.55 - 80.0 - action_height)
	_body_label.custom_minimum_size = Vector2(0, body_height)
	_body_scroll.custom_minimum_size = Vector2(0, visible_body_height)
	var row_height := maxf(visible_body_height + 80.0, 112.0 if _speaker_portrait.visible else 0.0)
	var bubble_height := row_height + action_height + 120.0
	_bubble.custom_minimum_size = Vector2(bubble_width, bubble_height)
	_bubble.size = Vector2(bubble_width, bubble_height)
	var bubble_x := clampf(hole.get_center().x - bubble_width * 0.5, 18.0, viewport.x - bubble_width - 18.0)
	var bubble_y := hole.position.y - bubble_height - 28.0
	var pointer_points := PackedVector2Array([Vector2(0, 0), Vector2(28, 0), Vector2(14, 18)])
	if bubble_y < 24.0 or bubble_y + bubble_height > hole.position.y - 12.0:
		bubble_y = minf(viewport.y - bubble_height - 24.0, hole.end.y + 28.0)
		pointer_points = PackedVector2Array([Vector2(14, 0), Vector2(0, 18), Vector2(28, 18)])
		_pointer.position = Vector2(clampf(hole.get_center().x - 14.0, 20.0, viewport.x - 48.0), bubble_y - 16.0)
	else:
		_pointer.position = Vector2(clampf(hole.get_center().x - 14.0, 20.0, viewport.x - 48.0), bubble_y + bubble_height - 2.0)
	_pointer.polygon = pointer_points
	_bubble.position = Vector2(bubble_x, bubble_y)
	_top_scroll_roll.position = Vector2(5, 0)
	_top_scroll_roll.size = Vector2(bubble_width - 10, 13)
	_bottom_scroll_roll.position = Vector2(5, bubble_height - 13)
	_bottom_scroll_roll.size = Vector2(bubble_width - 10, 13)
	_skip_button.position = Vector2(bubble_width - 100, 6)
	_skip_button.z_index = 3


func _make_scroll_roll() -> Panel:
	var roll := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#b27a3e")
	style.border_color = Color("#70421f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	roll.add_theme_stylebox_override("panel", style)
	roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roll.z_index = 2
	return roll


func _update_page() -> void:
	_body_label.text = _pages[_page]
	_body_label.visible_characters = 0
	SignalBus.play_sfx.emit("case_open")
	if _page_typing_tween != null and _page_typing_tween.is_running():
		_page_typing_tween.kill()
	_page_typing_tween = create_tween()
	_page_typing_tween.tween_property(_body_label, "visible_characters", _body_label.text.length(), maxf(0.35, _body_label.text.length() * 0.022))
	_page_typing_tween.finished.connect(_on_page_typing_finished.bind(_page))
	_tutorial_typing_ticks(_page)
	_body_scroll.scroll_vertical = 0
	_acknowledge_button.visible = _page < _pages.size() - 1 or _needs_ack
	_acknowledge_button.text = "SHOW TEXT" if _acknowledge_button.visible else ""
	_previous_button.visible = _page > 0
	_update_page_button(_page)


func _on_page_typing_finished(page_index: int) -> void:
	_update_page_button(page_index)


func _update_page_button(page_index: int) -> void:
	if page_index != _page or _acknowledge_button == null or not _acknowledge_button.visible:
		return
	if _body_label.visible_characters == -1 or _body_label.visible_characters >= _body_label.text.length():
		_acknowledge_button.text = "NEXT" if _page < _pages.size() - 1 else "CONTINUE"
	else:
		_acknowledge_button.text = "SHOW TEXT"


func _tutorial_typing_ticks(page_index: int) -> void:
	var target_count := _body_label.text.length()
	var last_tick := 0
	while is_inside_tree() and page_index == _page and _body_label.visible_characters >= 0 and _body_label.visible_characters < target_count:
		await get_tree().create_timer(0.09).timeout
		if not is_inside_tree():
			return
		var visible_count := _body_label.visible_characters
		if visible_count - last_tick >= 3:
			last_tick = visible_count
			SignalBus.play_sfx.emit("dialogue_type")


func _next_page() -> void:
	if _body_label.visible_characters != -1 and _body_label.visible_characters < _body_label.text.length():
		if _page_typing_tween != null and _page_typing_tween.is_running():
			_page_typing_tween.kill()
		_body_label.visible_characters = -1
		_update_page_button(_page)
		return
	if _page < _pages.size() - 1:
		_page += 1
		_update_page()
		_layout_tip()
		_emit_page_presented()
	else:
		hide_tip()
		acknowledged.emit()


func _previous_page() -> void:
	if _page > 0:
		_page -= 1
		_update_page()
		_layout_tip()
		_emit_page_presented()


func _append_chunk(copy: String, source_index: int, source_text: String, last: bool) -> void:
	_pages.append(copy)
	_source_indices.append(source_index)
	_source_texts.append(source_text)
	_last_chunks.append(last)


func _emit_page_presented() -> void:
	# Archive a rule after its complete instruction has been presented. Screen
	# pagination must not shift its authored skill ID or truncate the journal.
	if _last_chunks[_page]:
		page_presented.emit(_source_indices[_page], _source_texts[_page])


func _set_panel(panel: ColorRect, panel_position: Vector2, panel_size: Vector2) -> void:
	panel.position = panel_position
	panel.size = Vector2(maxf(0.0, panel_size.x), maxf(0.0, panel_size.y))


func _build_gesture_hand() -> void:
	var points := PackedVector2Array([
		Vector2(11, 0), Vector2(21, 0), Vector2(22, 25), Vector2(26, 18),
		Vector2(33, 21), Vector2(30, 33), Vector2(24, 44), Vector2(11, 44),
		Vector2(5, 37), Vector2(0, 30), Vector2(6, 26), Vector2(12, 31)
	])
	_gesture_hand = Polygon2D.new()
	_gesture_hand.polygon = points
	_gesture_hand.color = Color("#fff6dc")
	_gesture_hand.z_index = 10
	_gesture_hand.hide()
	add_child(_gesture_hand)
	_gesture_outline = Line2D.new()
	var closed := points.duplicate()
	closed.append(points[0])
	_gesture_outline.points = closed
	_gesture_outline.width = 3.0
	_gesture_outline.default_color = Color("#70421f")
	_gesture_outline.z_index = 9
	_gesture_outline.hide()
	add_child(_gesture_outline)


func _animate_gesture_hand(swipe: bool) -> void:
	if not _gesture_hand.visible:
		return
	if not swipe:
		var tap_position := _spotlight.get_center() - Vector2(11, 32)
		_gesture_hand.position = tap_position
		_gesture_outline.position = tap_position
		if _gesture_tween != null and _gesture_tween.is_running():
			_gesture_tween.kill()
		_gesture_tween = create_tween().set_loops()
		_gesture_tween.tween_property(_gesture_hand, "position:y", tap_position.y + 7.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_gesture_tween.parallel().tween_property(_gesture_outline, "position:y", tap_position.y + 7.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_gesture_tween.tween_property(_gesture_hand, "position:y", tap_position.y, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_gesture_tween.parallel().tween_property(_gesture_outline, "position:y", tap_position.y, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_gesture_tween.tween_interval(0.45)
		return
	var horizontal := _spotlight.size.x >= _spotlight.size.y
	var start := _spotlight.position + _spotlight.size * (Vector2(0.25, 0.5) if horizontal else Vector2(0.5, 0.25)) - Vector2(11, 28)
	var finish := _spotlight.position + _spotlight.size * (Vector2(0.75, 0.5) if horizontal else Vector2(0.5, 0.75)) - Vector2(11, 28)
	_gesture_hand.position = start
	_gesture_outline.position = start
	if _gesture_tween != null and _gesture_tween.is_running():
		_gesture_tween.kill()
	_gesture_tween = create_tween().set_loops()
	_gesture_tween.tween_property(_gesture_hand, "position", finish, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gesture_tween.parallel().tween_property(_gesture_outline, "position", finish, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gesture_tween.tween_interval(0.12)
	_gesture_tween.tween_property(_gesture_hand, "position", start, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gesture_tween.parallel().tween_property(_gesture_outline, "position", start, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gesture_tween.tween_interval(0.38)
