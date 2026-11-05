extends RefCounted
class_name MobileGameUI

const INK := Color("#273451")
const TEAL := Color("#168b9f")
const PINK := Color("#d94388")
const PURPLE := Color("#7350b5")
const GOLD := Color("#ffc85a")
const COIN := "res://assets/sprites/ui/icons/coins_icon.png"

static func background(parent: Control) -> void:
	var art := TextureRect.new()
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#c8f2f0"), Color("#eee0fa")])
	texture.gradient = gradient
	texture.fill_to = Vector2(0.7, 1)
	art.texture = texture
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)

static func style(color: Color, radius: int = 28) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = color.lightened(0.35)
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(18)
	box.shadow_color = Color(0.15, 0.16, 0.35, 0.2)
	box.shadow_size = 5
	box.shadow_offset = Vector2(0, 5)
	return box

static func card(parent: Node, color: Color = Color.WHITE) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style(color))
	parent.add_child(panel)
	return panel

static func label(parent: Node, value: String, font_size: int = 34, color: Color = INK) -> Label:
	var text := Label.new()
	text.text = value
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", color)
	parent.add_child(text)
	return text

static func button(parent: Node, value: String, action: Callable, color: Color = TEAL) -> Button:
	var control := Button.new()
	control.text = value
	control.custom_minimum_size = Vector2(92, 92)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", 36)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var fill := color
		if state == "hover": fill = color.lightened(0.12)
		if state == "pressed": fill = color.darkened(0.15)
		if state == "disabled": fill = Color("#8293a5")
		var box := style(fill)
		if state == "focus": box.border_color = GOLD
		control.add_theme_stylebox_override(state, box)
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_disabled_color", Color.WHITE)
	control.pressed.connect(action)
	if parent != null: parent.add_child(control)
	return control

static func image(parent: Node, path: String, minimum: Vector2 = Vector2(90, 90)) -> TextureRect:
	var art := TextureRect.new()
	art.texture = ResourceManager.load_texture(path)
	art.custom_minimum_size = minimum
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art

static func column(parent: Node, separation: int = 18) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

static func spacer(parent: Node) -> Control:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)
	return space


static func field_menu(parent: Control, settings: Callable, case_file: Callable, leave: Callable) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.1, 0.22, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := card(center, Color("#eef4ff"))
	panel.custom_minimum_size.x = minf(640, parent.get_viewport_rect().size.x - 48)
	var content := column(panel, 18)
	label(content, "FIELD MENU", 44)
	for entry in [{"text": "CASE FILE", "action": case_file}, {"text": "SETTINGS", "action": settings}, {"text": "INVESTIGATION MAP", "action": leave}]:
		var action: Callable = entry.action
		button(content, str(entry.text), func():
			overlay.queue_free()
			action.call()
		)
	button(content, "CLOSE MENU", overlay.queue_free, PURPLE)
	return overlay
