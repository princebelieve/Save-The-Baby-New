extends Control
class_name CampaignMap

signal level_selected(level_id: int)
signal back_requested

const GRASS_PATH := "res://assets/sprites/backgrounds/grass_terrain_texture.jpeg"
const SIGNPOST_PATH := "res://assets/sprites/props/wooden_signpost_cutout.png"
const NODE_PATH := "res://assets/sprites/ui/level_node_empty_cutout.png"
const BACKGROUND_DIR := "res://assets/sprites/backgrounds/"
const PROP_DIR := "res://assets/sprites/props/"
var _route_name := ""
var _level_records: Array[Dictionary] = []
var _chapter_records: Array[Dictionary] = []
var _map_width := 720.0
var _chapter_height := 610.0


func configure(route_name: String, level_records: Array[Dictionary]) -> void:
	_route_name = route_name
	_level_records = level_records.duplicate(true)


func get_level_screen_rect(level_id: int) -> Rect2:
	var level_button := get_node_or_null("CampaignScroll/CampaignTrail/Level%03d" % level_id) as Control
	return level_button.get_global_rect() if level_button != null else Rect2()


func _ready() -> void:
	_map_width = get_viewport_rect().size.x
	_chapter_height = maxf(570.0, _map_width * 0.86)
	_group_levels_into_chapters()
	_build_map()


func _group_levels_into_chapters() -> void:
	var groups: Dictionary = {}
	for level in _level_records:
		var metadata: Dictionary = level.get("metadata", {})
		var chapter_id := int(metadata.get("chapter_id", 0))
		if chapter_id <= 0:
			continue
		if not groups.has(chapter_id):
			groups[chapter_id] = {
				"id": chapter_id,
				"title": str(metadata.get("chapter_title", "Chapter %d" % chapter_id)),
				"first": int(metadata.get("chapter_start_level", level.get("level_id", 1))),
				"last": int(metadata.get("chapter_end_level", level.get("level_id", 1))),
				"background": str(metadata.get("map_background", "river_map_section_cutout.png")),
				"landmark": str(metadata.get("map_landmark", "wooden_bridge_cutout.png")),
				"levels": []
			}
		var chapter: Dictionary = groups[chapter_id]
		var chapter_levels: Array = chapter["levels"]
		chapter_levels.append(level)
		chapter["levels"] = chapter_levels
		groups[chapter_id] = chapter
	var chapter_ids: Array = groups.keys()
	chapter_ids.sort()
	for chapter_id in chapter_ids:
		var chapter: Dictionary = groups[chapter_id]
		var chapter_levels: Array = chapter["levels"]
		chapter_levels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("level_id", 0)) < int(b.get("level_id", 0)))
		chapter["levels"] = chapter_levels
		_chapter_records.append(chapter)


func _build_map() -> void:
	var base := ColorRect.new()
	base.color = Color("#243521")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var title_background := TextureRect.new()
	title_background.texture = ResourceManager.load_texture("res://assets/sprites/backgrounds/title_woodgrain_texture.jpeg")
	title_background.position = Vector2(0, 0)
	title_background.size = Vector2(_map_width, 118)
	title_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_background.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(title_background)
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 118.0
	scroll.offset_bottom = -12.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var map := Control.new()
	map.name = "CampaignTrail"
	map.custom_minimum_size = Vector2(_map_width, _chapter_records.size() * _chapter_height)
	map.size = map.custom_minimum_size
	scroll.add_child(map)

	var all_points := PackedVector2Array()
	for chapter_index in _chapter_records.size():
		var chapter: Dictionary = _chapter_records[chapter_index]
		var chapter_levels := _as_typed_levels(chapter.get("levels", []))
		var points := _build_chapter_art(map, chapter_index, chapter, chapter_levels)
		for point in points:
			all_points.append(point)
	_draw_trail(map, all_points)
	for chapter_index in _chapter_records.size():
		var chapter: Dictionary = _chapter_records[chapter_index]
		_add_chapter_nodes(map, chapter_index, chapter, _as_typed_levels(chapter.get("levels", [])))

	var header := ColorRect.new()
	header.color = Color(0.035, 0.08, 0.075, 0.96)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size.y = 118.0
	add_child(header)
	var title := Label.new()
	title.text = "THE SEARCH FOR ETHAN"
	title.position = Vector2(70, 10)
	title.size = Vector2(_map_width - 140, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#fff1ca"))
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "TRAIL: " + _route_name.to_upper()
	subtitle.position = Vector2(70, 54)
	subtitle.size = Vector2(_map_width - 140, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#d6e8c8"))
	header.add_child(subtitle)
	var back := TextureButton.new()
	back.texture_normal = ResourceManager.load_texture("res://assets/sprites/ui/buttons/back_normal.png")
	back.texture_hover = ResourceManager.load_texture("res://assets/sprites/ui/buttons/back_hover.png")
	back.texture_pressed = ResourceManager.load_texture("res://assets/sprites/ui/buttons/back_pressed.png")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.position = Vector2(12, 20)
	back.size = Vector2(94, 58)
	back.pressed.connect(back_requested.emit)
	header.add_child(back)

	var hint := Label.new()
	hint.text = "Scroll the trail | Chapters and level markers follow the campaign plan"
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -45
	hint.offset_left = 12
	hint.offset_right = -12
	hint.offset_bottom = -4
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("#fff1ca"))
	add_child(hint)


func _build_chapter_art(map: Control, index: int, chapter: Dictionary, levels: Array[Dictionary]) -> PackedVector2Array:
	var top := index * _chapter_height
	var grass := TextureRect.new()
	grass.texture = ResourceManager.load_texture(GRASS_PATH)
	grass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grass.stretch_mode = TextureRect.STRETCH_SCALE
	grass.position = Vector2(0, top)
	grass.size = Vector2(_map_width, _chapter_height)
	grass.modulate = Color(0.78, 0.86, 0.70, 1)
	map.add_child(grass)
	var location := TextureRect.new()
	location.texture = ResourceManager.load_texture(_asset_path(BACKGROUND_DIR, str(chapter["background"])))
	location.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	location.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	location.position = Vector2(12, top + 118)
	location.size = Vector2(_map_width - 24, _chapter_height - 130)
	map.add_child(location)
	var landmark := TextureRect.new()
	landmark.texture = ResourceManager.load_texture(_asset_path(PROP_DIR, str(chapter["landmark"])))
	landmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	landmark.position = Vector2(12 if index % 2 == 0 else _map_width - 142, top + 325)
	landmark.size = Vector2(130, 120)
	landmark.modulate = Color(1, 1, 1, 0.96)
	map.add_child(landmark)
	var sign := TextureRect.new()
	sign.texture = ResourceManager.load_texture(SIGNPOST_PATH)
	sign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sign.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sign.position = Vector2((_map_width - 220) * 0.5, top - 8)
	sign.size = Vector2(220, 220)
	map.add_child(sign)
	var sign_title := Label.new()
	sign_title.text = "CHAPTER %d\n%s" % [int(chapter["id"]), chapter["title"]]
	sign_title.position = Vector2((_map_width - 148) * 0.5, top + 21)
	sign_title.size = Vector2(148, 40)
	sign_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign_title.add_theme_font_size_override("font_size", 13)
	sign_title.add_theme_color_override("font_color", Color("#392619"))
	sign_title.add_theme_color_override("font_shadow_color", Color(1, 0.88, 0.62, 0.7))
	sign_title.add_theme_constant_override("shadow_offset_x", 1)
	sign_title.add_theme_constant_override("shadow_offset_y", 1)
	map.add_child(sign_title)
	var range_label := Label.new()
	range_label.text = "LEVELS %02d-%02d" % [chapter["first"], chapter["last"]]
	range_label.position = Vector2((_map_width - 148) * 0.5, top + 57)
	range_label.size = Vector2(148, 18)
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 11)
	range_label.add_theme_color_override("font_color", Color("#392619"))
	range_label.add_theme_color_override("font_shadow_color", Color(1, 0.88, 0.62, 0.7))
	range_label.add_theme_constant_override("shadow_offset_x", 1)
	range_label.add_theme_constant_override("shadow_offset_y", 1)
	map.add_child(range_label)
	var points := PackedVector2Array()
	var count := levels.size()
	for step in count:
		var progress := 0.0 if count <= 1 else float(step) / float(count - 1)
		var x := _map_width * (0.50 + 0.31 * sin(progress * TAU + index * 0.72))
		var y := top + 225 + progress * (_chapter_height - 270)
		points.append(Vector2(x, y))
	return points


func _asset_path(directory: String, file_name: String) -> String:
	if file_name.get_base_dir() == ".":
		return directory + file_name
	if file_name.begins_with("res://"):
		return file_name
	return "res://assets/sprites/" + file_name


func _as_typed_levels(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(value)
	return result


func _add_chapter_nodes(map: Control, index: int, chapter: Dictionary, levels: Array[Dictionary]) -> void:
	var top := index * _chapter_height
	var count := levels.size()
	for step in count:
		var level: Dictionary = levels[step]
		var level_id := int(level.get("level_id", 0))
		var progress := 0.0 if count <= 1 else float(step) / float(count - 1)
		var x := _map_width * (0.50 + 0.31 * sin(progress * TAU + index * 0.72))
		var y := top + 225 + progress * (_chapter_height - 270)
		var node := TextureButton.new()
		node.name = "Level%03d" % level_id
		node.texture_normal = ResourceManager.load_texture(NODE_PATH)
		node.texture_hover = node.texture_normal
		node.texture_pressed = node.texture_normal
		node.ignore_texture_size = true
		node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		node.position = Vector2(x - 35, y - 35)
		node.size = Vector2(70, 70)
		node.pressed.connect(level_selected.emit.bind(level_id))
		map.add_child(node)
		var number := Label.new()
		number.text = str(level_id)
		number.position = node.position + Vector2(4, 5)
		number.size = node.size - Vector2(8, 10)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 24)
		number.add_theme_color_override("font_color", Color("#603515"))
		number.add_theme_color_override("font_outline_color", Color("#fff4d1"))
		number.add_theme_constant_override("outline_size", 3)
		number.add_theme_color_override("font_shadow_color", Color("#22140b"))
		number.add_theme_constant_override("shadow_offset_x", 1)
		number.add_theme_constant_override("shadow_offset_y", 2)
		map.add_child(number)


func _draw_trail(map: Control, points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	var shadow := Line2D.new()
	shadow.points = points
	shadow.width = 13
	shadow.default_color = Color("#50391e")
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	map.add_child(shadow)
	var center := Line2D.new()
	center.points = points
	center.width = 6
	center.default_color = Color("#f0d88a")
	center.begin_cap_mode = Line2D.LINE_CAP_ROUND
	center.end_cap_mode = Line2D.LINE_CAP_ROUND
	center.joint_mode = Line2D.LINE_JOINT_ROUND
	map.add_child(center)
