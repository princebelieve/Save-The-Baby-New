extends Control
class_name IllustratedPopup

signal acknowledged
signal skipped

const SHADE := Color(0.015, 0.025, 0.06, 0.78)

var _spotlight := Rect2()
var _shade_panels: Array[ColorRect] = []
var _bubble: Panel
var _speaker_portrait: TextureRect
var _heading: Label
var _body_label: Label
var _pointer: Polygon2D
var _gesture_hand: Polygon2D
var _gesture_outline: Line2D
var _gesture_tween: Tween
var _acknowledge_button: Button
var _body_scroll: ScrollContainer
var _pages: Array[String] = []
var _page := 0
var _needs_ack := false
var _skip_button: Button
var _previous_button: Button
var _page_indicator: Label
var _hero_art: TextureRect
var _decoration: Control
var _modal := false
var _card_title := "DAVID'S ACADEMY"
var _art_path := ""
var _final_caption := "CONTINUE"
var _show_action_gesture := false
var _entrance: Tween


class CardDecoration extends Control:
	func _draw() -> void:
		var center := size * Vector2(0.5, 0.43)
		for index in range(12):
			var angle := index * TAU / 12.0
			var direction := Vector2.from_angle(angle)
			var side := direction.orthogonal() * 12.0
			draw_colored_polygon(PackedVector2Array([center + direction * 35.0, center + direction * 170.0 + side, center + direction * 170.0 - side]), Color(0.25, 0.76, 0.66, 0.10))
		draw_circle(center, 107, Color(0.37, 0.85, 0.73, 0.13))
		draw_arc(center, 122, 0, TAU, 80, Color(0.91, 0.72, 0.30, 0.55), 2.0, true)
		for point in [Vector2(0.14, 0.18), Vector2(0.86, 0.26), Vector2(0.76, 0.70), Vector2(0.20, 0.70)]:
			var at: Vector2 = size * point
			draw_colored_polygon(PackedVector2Array([at + Vector2(0,-10), at + Vector2(4,0), at + Vector2(0,10), at + Vector2(-4,0)]), Color("#e2b34f"))


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
	_modal = needs_acknowledgement
	_show_action_gesture = show_gesture
	for shade in _shade_panels:
		shade.color = Color(SHADE.r, SHADE.g, SHADE.b, 0.12 if keep_board_bright else SHADE.a)
	_pages.clear()
	var bubble_width := minf(560.0, get_viewport_rect().size.x - 48.0)
	var text_width := bubble_width - 64.0 if _modal else bubble_width - 164.0 - (70.0 if not _art_path.is_empty() else 0.0)
	var font := _body_label.get_theme_font("font")
	var two_lines := font.get_height(24) * 2.0 + 2.0
	# Explicit lesson lines are pages; legacy instruction copy is wrapped into
	# short pages rather than shrinking the text or hiding it in a scroll area.
	for paragraph in message.strip_edges().split("\n", false):
		var page_text := ""
		for word in paragraph.split(" ", false):
			var candidate := page_text + (" " if not page_text.is_empty() else "") + word
			if font.get_multiline_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, text_width, 24).y > two_lines and not page_text.is_empty():
				_pages.append(page_text)
				page_text = ""
			page_text += (" " if not page_text.is_empty() else "") + word
		if not page_text.is_empty():
			_pages.append(page_text)
	if _pages.is_empty(): _pages.append("Follow the highlighted action.")
	_page = 0
	_needs_ack = needs_acknowledgement
	_update_page()
	_heading.text = _card_title if not _card_title.is_empty() else speaker_name.to_upper()
	_speaker_portrait.texture = ResourceManager.load_portrait(portrait_path) if not portrait_path.is_empty() else null
	_hero_art.texture = ResourceManager.load_texture(_art_path) if not _art_path.is_empty() else null
	_speaker_portrait.visible = _speaker_portrait.texture != null
	_gesture_hand.visible = show_gesture
	_gesture_outline.visible = show_gesture
	show()
	_layout_tip()
	_animate_gesture_hand(keep_board_bright)
	_bubble.scale = Vector2(0.94, 0.94)
	_bubble.modulate.a = 0.0
	if _entrance != null and _entrance.is_running(): _entrance.kill()
	_entrance = create_tween().set_parallel(true)
	_entrance.tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(_bubble, "modulate:a", 1.0, 0.16)


func hide_tip() -> void:
	hide()
	if _gesture_tween != null and _gesture_tween.is_running():
		_gesture_tween.kill()
	_gesture_hand.hide()
	_gesture_outline.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and visible:
		_layout_tip()


func set_card_context(title: String, illustration_path: String = "", final_caption: String = "CONTINUE") -> void:
	_card_title = title
	_art_path = illustration_path
	_final_caption = final_caption


func _build_bubble() -> void:
	_bubble = Panel.new()
	_bubble.name = "IllustratedCoachingCard"
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#efffed")
	style.border_color = Color("#edc66e")
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0.0, 0.03, 0.04, 0.55)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 10)
	_bubble.add_theme_stylebox_override("panel", style)
	add_child(_bubble)
	_decoration = CardDecoration.new()
	_decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_decoration)
	_heading = Label.new()
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heading.add_theme_font_size_override("font_size", 30)
	_heading.add_theme_color_override("font_color", Color("#084f49"))
	_heading.add_theme_color_override("font_outline_color", Color.WHITE)
	_heading.add_theme_constant_override("outline_size", 5)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_heading)
	_speaker_portrait = TextureRect.new()
	_speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_speaker_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_speaker_portrait)
	_hero_art = TextureRect.new()
	_hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); c.a *= smoothstep(0.025,0.12,max(c.r,max(c.g,c.b))); COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	_hero_art.material = material
	_bubble.add_child(_hero_art)
	_body_scroll = ScrollContainer.new()
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_body_scroll)
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.add_theme_font_size_override("font_size", 24)
	_body_label.add_theme_color_override("font_color", Color("#173f40"))
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_scroll.add_child(_body_label)
	_previous_button = _card_button("<", false)
	_previous_button.tooltip_text = "Previous page"
	_previous_button.pressed.connect(_previous_page)
	_acknowledge_button = _card_button(">", true)
	_acknowledge_button.pressed.connect(_next_page)
	_page_indicator = Label.new()
	_page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_indicator.add_theme_font_size_override("font_size", 17)
	_page_indicator.add_theme_color_override("font_color", Color("#477f78"))
	_page_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_page_indicator)
	_skip_button = _card_button("X", false)
	_skip_button.tooltip_text = "Close"
	_skip_button.pressed.connect(func():
		hide_tip()
		skipped.emit())
	_pointer = Polygon2D.new()
	_pointer.hide()
	add_child(_pointer)


func _card_button(caption: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff9d9") if primary else Color("#12645b"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#147d70") if primary else Color("#d6f3d9")
	style.border_color = Color("#e3ba5c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.03, 0.23, 0.19, 0.25)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	_bubble.add_child(button)
	return button


func _layout_tip() -> void:
	if _shade_panels.size() != 4 or _bubble == null: return
	var viewport := get_viewport_rect().size
	var hole := _spotlight.grow(12.0)
	hole.position = hole.position.clamp(Vector2(12,12), viewport - Vector2(24,24))
	hole.size.x = clampf(hole.size.x, 12, viewport.x - hole.position.x - 12)
	hole.size.y = clampf(hole.size.y, 12, viewport.y - hole.position.y - 12)
	if _modal:
		_set_panel(_shade_panels[0], Vector2.ZERO, viewport)
		for index in range(1,4): _set_panel(_shade_panels[index], Vector2.ZERO, Vector2.ZERO)
	else:
		_set_panel(_shade_panels[0], Vector2.ZERO, Vector2(viewport.x, hole.position.y))
		_set_panel(_shade_panels[1], Vector2(0,hole.position.y), Vector2(hole.position.x,hole.size.y))
		_set_panel(_shade_panels[2], Vector2(hole.end.x,hole.position.y), Vector2(viewport.x-hole.end.x,hole.size.y))
		_set_panel(_shade_panels[3], Vector2(0,hole.end.y), Vector2(viewport.x,viewport.y-hole.end.y))
	var width := minf(560, viewport.x - 48)
	var height := minf(620, viewport.y * 0.73) if _modal else 286.0
	var at := (viewport - Vector2(width,height)) * 0.5
	if not _modal:
		at.y = hole.position.y - height - 22
		if at.y < 20: at.y = minf(viewport.y-height-20,hole.end.y+22)
	_bubble.custom_minimum_size = Vector2(width,height)
	_bubble.size = Vector2(width,height)
	_bubble.position = at
	_bubble.pivot_offset = _bubble.size * 0.5
	_heading.position = Vector2(36,22)
	_heading.size = Vector2(width-72,76 if _modal else 42)
	_heading.add_theme_font_size_override("font_size", 29 if _modal else 23)
	_decoration.position = Vector2(20,90 if _modal else 48)
	_decoration.size = Vector2(width-40,280 if _modal else 130)
	_decoration.visible = _modal
	_decoration.queue_redraw()
	var has_art := _hero_art.texture != null
	_speaker_portrait.position = Vector2(48 if has_art else width*0.25,102) if _modal else Vector2(20,65)
	_speaker_portrait.size = Vector2(width*0.49,268) if _modal else Vector2(108,132)
	_hero_art.position = Vector2(width*0.49,135) if _modal else Vector2(width-98,72)
	_hero_art.size = Vector2(width*0.43,218) if _modal else Vector2(72,90)
	_hero_art.visible = has_art
	var text_at := Vector2(32,height-220) if _modal else Vector2(136,64)
	var text_size := Vector2(width-64,130) if _modal else Vector2(width-164-(70 if has_art else 0),136)
	# Clear the previous large card's minimum before shrinking to an action tip.
	_body_label.custom_minimum_size = Vector2.ZERO
	_body_label.size = text_size
	_body_scroll.custom_minimum_size = Vector2.ZERO
	_body_scroll.position = text_at
	_body_scroll.size = text_size
	_body_label.custom_minimum_size = Vector2(0, text_size.y)
	_previous_button.position = Vector2(22,height-72)
	_previous_button.size = Vector2(54,48)
	_acknowledge_button.size = Vector2(150 if _page == _pages.size()-1 and _needs_ack else 54,48)
	_acknowledge_button.position = Vector2(width-_acknowledge_button.size.x-22,height-72)
	_page_indicator.position = Vector2(width*0.5-44,height-59)
	_page_indicator.size = Vector2(88,30)
	_skip_button.position = Vector2(width-54,10)
	_skip_button.size = Vector2(44,44)


func _update_page() -> void:
	_body_label.text = _pages[_page]
	_previous_button.visible = _page > 0
	_page_indicator.text = "%d / %d" % [_page+1,_pages.size()]
	_acknowledge_button.visible = _page < _pages.size()-1 or _needs_ack
	_acknowledge_button.text = ">" if _page < _pages.size()-1 else _final_caption
	_acknowledge_button.tooltip_text = "Next page" if _page < _pages.size()-1 else _final_caption.capitalize()


func _previous_page() -> void:
	if _page > 0:
		_page -= 1
		_update_page()
		_layout_tip()


func _next_page() -> void:
	if _page < _pages.size()-1:
		_page += 1
		_update_page()
		_layout_tip()
	else:
		hide_tip()
		acknowledged.emit()


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
	_gesture_outline.default_color = Color("#18304a")
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
