extends Control
class_name TutorialOverlay

signal acknowledged

const SHADE := Color(0.015, 0.025, 0.06, 0.78)

var _spotlight := Rect2()
var _shade_panels: Array[ColorRect] = []
var _bubble: PanelContainer
var _speaker_portrait: TextureRect
var _heading: Label
var _body_label: Label
var _pointer: Polygon2D
var _acknowledge_button: Button


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
	hide()


func show_tip(message: String, target_rect: Rect2, speaker_name: String = "DAVID", portrait_path: String = "", needs_acknowledgement: bool = false) -> void:
	_spotlight = target_rect
	_body_label.text = " ".join(message.strip_edges().split("\n", false))
	_heading.text = speaker_name.to_upper()
	_speaker_portrait.texture = ResourceManager.load_texture(portrait_path) if not portrait_path.is_empty() else null
	_speaker_portrait.visible = _speaker_portrait.texture != null
	_acknowledge_button.visible = needs_acknowledgement
	_acknowledge_button.text = "CONTINUE"
	show()
	_layout_tip()
	_bubble.scale = Vector2(0.94, 0.94)
	_bubble.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bubble, "modulate:a", 1.0, 0.16)


func hide_tip() -> void:
	hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and visible:
		_layout_tip()


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.name = "TutorialSpeechBubble"
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.clip_contents = true
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
	bubble_content.add_theme_constant_override("separation", 6)
	bubble_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(bubble_content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_content.add_child(row)
	_speaker_portrait = TextureRect.new()
	_speaker_portrait.custom_minimum_size = Vector2(64, 64)
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
	_heading.add_theme_font_size_override("font_size", 16)
	_heading.add_theme_color_override("font_color", Color("#995221"))
	_heading.add_theme_color_override("font_outline_color", Color("#fffaf0"))
	_heading.add_theme_constant_override("outline_size", 2)
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_heading)
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 19)
	_body_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_body_label.add_theme_color_override("font_color", Color("#26364d"))
	_body_label.add_theme_color_override("font_outline_color", Color("#fffaf0"))
	_body_label.add_theme_constant_override("outline_size", 1)
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_body_label)
	_acknowledge_button = Button.new()
	_acknowledge_button.text = "CONTINUE"
	_acknowledge_button.custom_minimum_size = Vector2(138, 44)
	_acknowledge_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_acknowledge_button.add_theme_font_size_override("font_size", 17)
	_acknowledge_button.add_theme_color_override("font_color", Color("#fff8e9"))
	var ack_style := StyleBoxFlat.new()
	ack_style.bg_color = Color("#245a70")
	ack_style.border_color = Color("#dc8735")
	ack_style.set_border_width_all(2)
	ack_style.set_corner_radius_all(12)
	_acknowledge_button.add_theme_stylebox_override("normal", ack_style)
	var ack_hover := ack_style.duplicate() as StyleBoxFlat
	ack_hover.bg_color = Color("#347e94")
	_acknowledge_button.add_theme_stylebox_override("hover", ack_hover)
	_acknowledge_button.pressed.connect(acknowledged.emit)
	bubble_content.add_child(_acknowledge_button)
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

	var bubble_width := minf(440.0, viewport.x - 36.0)
	var bubble_height := minf(248.0 if _acknowledge_button.visible else 190.0, viewport.y * (0.21 if _acknowledge_button.visible else 0.17))
	_bubble.size = Vector2(bubble_width, bubble_height)
	_bubble.custom_minimum_size = _bubble.size
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


func _set_panel(panel: ColorRect, panel_position: Vector2, panel_size: Vector2) -> void:
	panel.position = panel_position
	panel.size = Vector2(maxf(0.0, panel_size.x), maxf(0.0, panel_size.y))
