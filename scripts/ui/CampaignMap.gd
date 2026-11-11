extends Control
class_name CampaignMap

signal level_selected(level_id: int)
signal back_requested
signal portrait_requested
signal daily_rewards_requested

var _daily_progress: ConfigFile
var _daily_label: Label
var _portrait_button: Button
var _daily_tick := 0.0


func configure_daily(progress: ConfigFile) -> void:
	_daily_progress = progress


func _process(delta: float) -> void:
	_daily_tick -= delta
	if _daily_tick > 0.0 or _daily_label == null or _daily_progress == null:
		return
	_daily_tick = 1.0
	var now := TimeHelper.current_unix_time()
	_portrait_button.text = ""
	_portrait_button.hide()
	var stamped := DailyActivities.day_at(now) == int(_daily_progress.get_value("daily", "last_day", -1))
	_daily_label.text = "%d days on the case | %s" % [int(_daily_progress.get_value("daily", "streak", 0)), "Briefing complete" if stamped else "Daily briefing ready"]

const GRASS_PATH := "res://assets/sprites/backgrounds/grass_terrain_texture.jpeg"
const SIGNPOST_PATH := "res://assets/sprites/props/wooden_signpost_cutout.png"
const NODE_PATH := "res://assets/sprites/ui/level_node_empty_cutout.png"
const LEVEL_BADGE_PATH := "res://assets/sprites/ui/level_badge.jpeg"
const LOCKED_BADGE_PATH := "res://assets/sprites/ui/locked_level_badge_cutout.png"
const DAVID_PORTRAIT_PATH := "res://assets/sprites/characters/david_portrait_cutout.png"
const WHITE_KEY_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV) * COLOR;
	float lowest = min(sample_color.r, min(sample_color.g, sample_color.b));
	float highest = max(sample_color.r, max(sample_color.g, sample_color.b));
	float distance_from_white = (highest - lowest) + (1.0 - lowest) * 0.7;
	float white_background = 1.0 - smoothstep(0.045, 0.15, distance_from_white);
	sample_color.a *= 1.0 - white_background;
	COLOR = sample_color;
}
"""
const BACKGROUND_DIR := "res://assets/sprites/backgrounds/"
const PROP_DIR := "res://assets/sprites/props/"
var _route_name := ""
var _level_records: Array[Dictionary] = []
var _chapter_records: Array[Dictionary] = []
var _highest_unlocked_level := 1
var _completed_levels: Dictionary = {}
var _map_width := 720.0
var _chapter_height := 610.0
var _level_positions: Dictionary = {}
var _map_scroll: ScrollContainer
var _map_canvas: Control
var _visible_chapters: Dictionary = {}


func configure(route_name: String, level_records: Array[Dictionary], highest_unlocked_level: int = 1, completed_levels: Dictionary = {}) -> void:
	_route_name = route_name
	_level_records = level_records.duplicate(true)
	_highest_unlocked_level = maxi(1, highest_unlocked_level)
	_completed_levels = completed_levels.duplicate(true)


func get_level_screen_rect(level_id: int) -> Rect2:
	if not _level_positions.has(level_id) or _map_scroll == null: return Rect2()
	return Rect2(_map_scroll.global_position + _level_positions[level_id] - Vector2(64, 64 + _map_scroll.scroll_vertical), Vector2(128, 128))


func _ready() -> void:
	_map_width = get_viewport_rect().size.x
	_chapter_height = maxf(2200.0, _map_width * 3.0)
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
				"props": metadata.get("map_props", []),
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
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var title_background := TextureRect.new()
	title_background.texture = ResourceManager.load_texture("res://assets/sprites/backgrounds/title_woodgrain_texture.jpeg")
	title_background.position = Vector2(0, 0)
	title_background.size = Vector2(_map_width, 118)
	title_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_background.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(title_background)
	var scroll := ScrollContainer.new()
	_map_scroll = scroll
	scroll.name = "CampaignScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 118.0
	scroll.offset_bottom = -340.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	var map := Control.new()
	map.name = "CampaignTrail"
	map.mouse_filter = Control.MOUSE_FILTER_PASS
	map.custom_minimum_size = Vector2(_map_width, _chapter_records.size() * _chapter_height + 260)
	_map_canvas = map
	map.size = map.custom_minimum_size
	scroll.add_child(map)

	var all_points := PackedVector2Array()
	for chapter_index in _chapter_records.size():
		var chapter: Dictionary = _chapter_records[chapter_index]
		var chapter_levels := _as_typed_levels(chapter.get("levels", []))
		for step in chapter_levels.size():
			var point := _node_position(chapter_index, step, chapter_levels.size())
			_level_positions[int(chapter_levels[step].level_id)] = point
			all_points.append(point)
	_draw_trail(map, all_points)
	_refresh_visible_chapters()
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): _refresh_visible_chapters())
	scroll.resized.connect(_refresh_visible_chapters)
	_add_david_progress_marker(map)
	var end := MobileGameUI.card(map, MobileGameUI.PURPLE)
	end.name = "MoreLevelsAhead"
	end.position = Vector2(32, _chapter_records.size() * _chapter_height + 20)
	end.size = Vector2(_map_width - 64, 180)
	MobileGameUI.label(end, "MORE LEVELS AHEAD\nThe investigation continues...", 38, Color.WHITE)

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
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#fff1ca"))
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "TRAIL: " + _route_name.to_upper()
	subtitle.position = Vector2(70, 54)
	subtitle.size = Vector2(_map_width - 140, 36)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color("#d6e8c8"))
	header.add_child(subtitle)
	var back := MobileGameUI.button(header, "<", back_requested.emit, MobileGameUI.PURPLE)
	back.position = Vector2(12, 12)
	back.size = Vector2(94, 92)

	var footer_background := ColorRect.new()
	footer_background.color = Color("#102c2b")
	footer_background.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_background.offset_top = -340
	add_child(footer_background)
	var footer := VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -330
	footer.offset_left = 16
	footer.offset_right = -16
	footer.add_theme_constant_override("separation", 5)
	add_child(footer)
	var pages := HBoxContainer.new()
	footer.add_child(pages)
	pages.add_theme_constant_override("separation", 12)
	MobileGameUI.button(pages, "My case", scroll_to_level.bind(_highest_unlocked_level))
	MobileGameUI.button(pages, "Ahead >", scroll_chapters.bind(1))
	var range_label := Label.new()
	range_label.text = "THE INVESTIGATION TRAIL"
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 32)
	footer.add_child(range_label)
	_portrait_button = MobileGameUI.button(footer, "Restore portrait", portrait_requested.emit)
	_portrait_button.hide()
	_daily_label = Label.new()
	_daily_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_daily_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_daily_label.add_theme_font_size_override("font_size", 32)
	footer.add_child(_daily_label)
	MobileGameUI.button(footer, "CASE REWARDS", daily_rewards_requested.emit, MobileGameUI.PURPLE)



func _build_chapter_art(map: Control, index: int, chapter: Dictionary, levels: Array[Dictionary]) -> PackedVector2Array:
	var top := index * _chapter_height
	var grass := TextureRect.new()
	grass.texture = ResourceManager.load_texture(GRASS_PATH)
	grass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grass.stretch_mode = TextureRect.STRETCH_SCALE
	grass.position = Vector2(0, top)
	grass.size = Vector2(_map_width, _chapter_height)
	grass.modulate = Color(0.78, 0.86, 0.70, 1)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(grass)
	var location := TextureRect.new()
	location.texture = ResourceManager.load_texture(_asset_path(BACKGROUND_DIR, str(chapter["background"])))
	location.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	location.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	location.position = Vector2(12, top + 118)
	location.size = Vector2(_map_width - 24, _chapter_height - 130)
	location.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(location)
	var landmark := TextureRect.new()
	landmark.texture = ResourceManager.load_texture(_asset_path(PROP_DIR, str(chapter["landmark"])))
	landmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	landmark.position = Vector2(12 if index % 2 == 0 else _map_width - 142, top + 325)
	landmark.size = Vector2(130, 120)
	landmark.modulate = Color(1, 1, 1, 0.96)
	landmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(landmark)
	var prop_set: Array = chapter.get("props", [])
	var prop_size := _map_width * 0.15
	for prop_index in prop_set.size():
		var prop := TextureRect.new()
		prop.name = "ChapterProp%d" % prop_index
		prop.texture = ResourceManager.load_texture(_asset_path(PROP_DIR, str(prop_set[prop_index])))
		prop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var prop_x := 8.0 if prop_index == 0 else _map_width - prop_size - 8.0
		var prop_y := top + 170.0 if prop_index == 0 else top + _chapter_height - 205.0
		prop.position = Vector2(prop_x, prop_y)
		prop.size = Vector2(prop_size, prop_size * 0.82)
		prop.modulate = Color(0.9, 0.95, 0.83, 0.94)
		prop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map.add_child(prop)
	var sign := Panel.new()
	var sign_width := minf(_map_width * 0.76, 440)
	sign.position = Vector2((_map_width - sign_width) * 0.5, top + 16)
	sign.size = Vector2(sign_width, 116)
	var sign_style := StyleBoxFlat.new()
	sign_style.bg_color = Color("#143b36")
	sign_style.border_color = Color("#e3c275")
	sign_style.set_border_width_all(2)
	sign_style.set_corner_radius_all(18)
	sign_style.shadow_color = Color(0, 0, 0, 0.35)
	sign_style.shadow_size = 6
	sign.add_theme_stylebox_override("panel", sign_style)
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(sign)
	var sign_title := Label.new()
	sign_title.text = "CHAPTER %d\n%s" % [int(chapter["id"]), chapter["title"]]
	sign_title.position = Vector2((_map_width - sign_width) * 0.5 + 12, top + 24)
	sign_title.size = Vector2(sign_width - 24, 72)
	sign_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sign_title.add_theme_font_size_override("font_size", 32)
	sign_title.add_theme_color_override("font_color", Color("#fff3d5"))
	sign_title.add_theme_color_override("font_shadow_color", Color("#102238"))
	sign_title.add_theme_constant_override("shadow_offset_x", 1)
	sign_title.add_theme_constant_override("shadow_offset_y", 1)
	sign_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(sign_title)
	var range_label := Label.new()
	range_label.text = "LEVELS %02d-%02d" % [chapter["first"], chapter["last"]]
	range_label.position = Vector2((_map_width - sign_width) * 0.5, top + 98)
	range_label.size = Vector2(sign_width, 24)
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 28)
	range_label.add_theme_color_override("font_color", Color("#f2ce7c"))
	range_label.add_theme_color_override("font_shadow_color", Color("#102238"))
	range_label.add_theme_constant_override("shadow_offset_x", 1)
	range_label.add_theme_constant_override("shadow_offset_y", 1)
	range_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(range_label)
	var points := PackedVector2Array()
	var count := levels.size()
	for step in count:
		var progress := 0.0 if count <= 1 else float(step) / float(count - 1)
		var x := _map_width * (0.50 + 0.31 * sin(progress * TAU + index * 0.72))
		var y := top + 225 + progress * (_chapter_height - 420)
		points.append(Vector2(x, y))
	return points


func _asset_path(directory: String, file_name: String) -> String:
	if file_name.get_base_dir().is_empty() or file_name.get_base_dir() == ".":
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
		var y := top + 225 + progress * (_chapter_height - 420)
		_level_positions[level_id] = Vector2(x, y)
		var node := TextureButton.new()
		node.name = "Level%03d" % level_id
		var star_count := int(_completed_levels.get(str(level_id), 0))
		var is_unlocked := level_id <= _highest_unlocked_level
		var badge_path := NODE_PATH
		if not is_unlocked:
			badge_path = LOCKED_BADGE_PATH
		elif level_id == _highest_unlocked_level:
			badge_path = LEVEL_BADGE_PATH
		node.texture_normal = ResourceManager.load_texture(badge_path)
		node.texture_hover = node.texture_normal
		node.texture_pressed = node.texture_normal
		node.ignore_texture_size = true
		node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		node.position = Vector2(x - 64, y - 64)
		node.size = Vector2(128, 128)
		node.disabled = not is_unlocked
		if is_unlocked:
			node.pressed.connect(level_selected.emit.bind(level_id))
		if badge_path.ends_with(".jpeg"):
			node.material = _make_white_key_material()
		node.z_index = 2
		map.add_child(node)
		var number := Label.new()
		number.text = str(level_id)
		if not is_unlocked:
			number.position = node.position + Vector2(0, 85)
			number.size = Vector2(node.size.x, 48)
		else:
			number.position = node.position + Vector2(4, 8)
			number.size = node.size - Vector2(8, 25)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 42)
		number.add_theme_color_override("font_color", Color("#603515") if is_unlocked else Color("#fff4d1"))
		number.add_theme_color_override("font_outline_color", Color("#fff4d1") if is_unlocked else Color("#13283f"))
		number.add_theme_constant_override("outline_size", 3)
		number.add_theme_color_override("font_shadow_color", Color("#22140b"))
		number.add_theme_constant_override("shadow_offset_x", 1)
		number.add_theme_constant_override("shadow_offset_y", 2)
		number.z_index = 3
		map.add_child(number)
		if is_unlocked:
			var stars := MapStars.new()
			stars.name = "Stars%03d" % level_id
			stars.z_index = 3
			stars.earned = clampi(star_count, 0, 3)
			stars.position = Vector2(x - 78, y + 58)
			map.add_child(stars)



func _make_white_key_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = WHITE_KEY_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _add_david_progress_marker(map: Control) -> void:
	var current_level := _highest_unlocked_level
	if not _level_positions.has(current_level) and current_level < int(_level_positions.keys().min()):
		return
	if not _level_positions.has(current_level) and not _level_positions.is_empty():
		current_level = int(_level_positions.keys().max())
	var current_position: Vector2 = _level_positions.get(current_level, Vector2(_map_width * 0.5, 225.0))
	var prior_level := current_level - 1
	var has_arrival := current_level == _highest_unlocked_level and prior_level >= 1 and int(_completed_levels.get(str(prior_level), 0)) > 0 and _level_positions.has(prior_level)
	var start_position: Vector2 = _level_positions.get(prior_level, current_position) if has_arrival else current_position
	var portrait := TextureRect.new()
	portrait.name = "DavidProgressPortrait"
	portrait.texture = ResourceManager.load_portrait(DAVID_PORTRAIT_PATH)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.position = start_position + Vector2(78.0, -58.0)
	portrait.size = Vector2(54.0, 64.0)
	portrait.z_index = 10
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.add_child(portrait)
	var outline := Panel.new()
	outline.name = "DavidMarkerFrame"
	outline.position = portrait.position - Vector2(3.0, 3.0)
	outline.size = portrait.size + Vector2(6.0, 6.0)
	outline.z_index = 9
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	outline_style.border_color = Color("#f5d27d")
	outline_style.set_border_width_all(3)
	outline_style.set_corner_radius_all(18)
	outline.add_theme_stylebox_override("panel", outline_style)
	map.add_child(outline)
	call_deferred("scroll_to_level", current_level)
	if has_arrival:
		await get_tree().process_frame
		await get_tree().create_timer(0.18).timeout
		var move := create_tween()
		move.tween_property(portrait, "position", current_position + Vector2(78.0, -58.0), 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		move.parallel().tween_property(outline, "position", current_position + Vector2(75.0, -61.0), 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _draw_trail(map: Control, points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	var shadow := Line2D.new()
	shadow.z_index = 1
	shadow.points = points
	shadow.width = 13
	shadow.default_color = Color("#50391e")
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	map.add_child(shadow)
	var center := Line2D.new()
	center.z_index = 1
	center.points = points
	center.width = 6
	center.default_color = Color("#f0d88a")
	center.begin_cap_mode = Line2D.LINE_CAP_ROUND
	center.end_cap_mode = Line2D.LINE_CAP_ROUND
	center.joint_mode = Line2D.LINE_JOINT_ROUND
	map.add_child(center)


func _node_position(chapter: int, step: int, count: int) -> Vector2:
	var progress := 0.0 if count <= 1 else float(step) / float(count - 1)
	return Vector2(_map_width * (0.50 + 0.31 * sin(progress * TAU + chapter * 0.72)), chapter * _chapter_height + 225 + progress * (_chapter_height - 420))


func _refresh_visible_chapters() -> void:
	if _map_canvas == null or _map_scroll == null: return
	var first := maxi(0, int(_map_scroll.scroll_vertical / _chapter_height) - 1)
	var last := mini(_chapter_records.size() - 1, int((_map_scroll.scroll_vertical + _map_scroll.size.y) / _chapter_height) + 1)
	for index in _visible_chapters.keys():
		if index < first or index > last:
			var old: Control = _visible_chapters[index]
			_map_canvas.remove_child(old)
			old.queue_free()
			_visible_chapters.erase(index)
	for index in range(first, last + 1):
		if _visible_chapters.has(index): continue
		var chunk := Control.new()
		chunk.name = "Chapter%d" % index
		chunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_map_canvas.add_child(chunk)
		_visible_chapters[index] = chunk
		var chapter: Dictionary = _chapter_records[index]
		var levels := _as_typed_levels(chapter.get("levels", []))
		_build_chapter_art(chunk, index, chapter, levels)
		_add_chapter_nodes(chunk, index, chapter, levels)


func scroll_to_level(level_id: int) -> void:
	if not _level_positions.has(level_id): return
	_map_scroll.scroll_vertical = maxi(0, int(_level_positions[level_id].y - _map_scroll.size.y * 0.48))
	_refresh_visible_chapters()


func scroll_chapters(direction: int) -> void:
	_map_scroll.scroll_vertical = maxi(0, _map_scroll.scroll_vertical + int(_chapter_height) * direction)
	_refresh_visible_chapters()
