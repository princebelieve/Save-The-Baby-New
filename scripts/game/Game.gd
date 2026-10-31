extends Node2D
class_name Game

const DISPLAY_FONT: FontFile = preload("res://assets/fonts/Baloo2-Variable.ttf")

const OPENING_STORY_PATH := "res://stories/opening_story.json"
const CAMPAIGN_PROGRESS_PATH := "user://campaign_progress.cfg"

var _board_manager: Node
var _economy_manager: EconomyManager
var _reward_manager: RewardManager
var _board: Board
var _story: Dictionary = {}
var _story_manager: StoryManager
var _story_layer: CanvasLayer
var _tutorial_overlay: TutorialOverlay
var _dialogue_label: Label
var _speaker_label: Label
var _story_continue_button: Button
var _story_skip_button: Button
var _story_previous_button: Button
var _launch_layer: CanvasLayer
var _story_portrait: TextureRect
var _pause_layer: CanvasLayer
var _briefing_layer: CanvasLayer
var _campaign_layer: CanvasLayer
var _campaign_map: Control
var _pending_level_id := 0
var _pending_route_id := ""
var _pending_story_id := ""
var _chosen_route_label: String = "Go after Victor alone"
var _dialogue_tween: Tween
var _is_dialogue_typing: bool = false
var _choice_box: VBoxContainer
var _moves_label: Label
var _objective_label: Label
var _objective_title_label: Label
var _blocker_label: Label
var _reward_label: Label
var _lives_label: Label
var _level_reward_label: Label
var _star_reward_label: Label
var _objective_target_icon: TextureRect
var _objective_target_name: Label
var _level_number_label: Label
var _objective_description_label: Label
var _hint_label: Label
var _pause_button: TextureButton
var _case_file_button: TextureButton
var _case_file_layer: CanvasLayer
var _case_file_was_board_locked := false
var _booster_dock: PanelContainer
var _booster_buttons: Dictionary = {}
var _result_layer: CanvasLayer
var _evidence_count: int = 0
var _evidence_goal: int = 10
var _objective_target := "KEY"
var _objective_type := "COLLECT_ITEMS"
var _moves_remaining: int = 0
var _current_level_id := 1
var _current_route_id := "alone"
var _booster_inventory: Dictionary = {}
var _obstacles_goal := 0
var _obstacles_cleared := 0
var _displayed_coins := 0
var _coin_count_tween: Tween
var _selected_booster := ""
var _booster_confirm: ConfirmationDialog
var _tutorial_active := false
var _tutorial_action := ""
var _tutorial_mechanic := ""
var _tutorial_pause_open := false
var _tutorial_booster_kind := ""
var _tutorial_target_cell := Vector2i(-1, -1)
var _campaign_coach_shown := false
var _campaign_progress := ConfigFile.new()
var _highest_unlocked_level := 1
var _completed_levels: Dictionary = {}
var _match_streak := 0
var _special_moves_created := 0
var _objective_complete_sound_played := false
var _story_objective_sound_pending := false


func _ready() -> void:
	_load_campaign_progress()
	_special_moves_created = int(_campaign_progress.get_value("campaign", "special_moves_created", 0))
	_economy_manager = get_node_or_null("Managers/EconomyManager") as EconomyManager
	_reward_manager = get_node_or_null("Managers/RewardManager") as RewardManager
	if _economy_manager != null:
		var game_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.GAME)
		_economy_manager.set_coins(int(_campaign_progress.get_value("campaign", "coins", int(game_config.get("starting_coins", 0)))))
		var initial_lives := int(_campaign_progress.get_value("campaign", "lives", int(game_config.get("max_lives", 5))))
		_economy_manager.set_lives(initial_lives)
		var economy_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.ECONOMY)
		var saved_boosters: Dictionary = _campaign_progress.get_value("campaign", "boosters", {})
		var starting_boosters: Dictionary = economy_config.get("starting_boosters", {})
		for kind in ["rocket", "bomb", "thunder"]:
			var count := int(saved_boosters.get(kind, starting_boosters.get(kind, 0)))
			_economy_manager.set_booster_count(kind, count)
		_economy_manager.set_ethan_count(int(_campaign_progress.get_value("campaign", "ethan", economy_config.get("starting_ethan", 0))))
	_board_manager = get_node_or_null("Managers/BoardManager")
	if _board_manager != null:
		if not _board_manager.board_created.is_connected(_on_board_created):
			_board_manager.board_created.connect(_on_board_created)
		# Child managers can load Level 001 before this parent node enters _ready.
		# Hook that already-created board as well as future board_created signals.
		if _board_manager.get_board() != null:
			_on_board_created()
	_build_gameplay_hud()
	if _economy_manager != null:
		_economy_manager.coins_changed.connect(_on_coins_changed)
		_economy_manager.lives_changed.connect(_on_lives_changed)
		_economy_manager.boosters_changed.connect(_on_boosters_changed)
		_economy_manager.ethan_changed.connect(_on_ethan_changed)
		_on_coins_changed(_economy_manager.get_coins())
		_on_lives_changed(_economy_manager.get_lives())
		_on_ethan_changed(_economy_manager.get_ethan_count())
	_load_game_art()
	_prepare_opening_story()
	_show_loading_screen()
	if _board != null:
		_board.lock()


func _load_game_art() -> void:
	var background := get_node_or_null("BackgroundLayer/Background") as ColorRect
	if background == null:
		return
	var art := TextureRect.new()
	art.name = "InvestigationBackground"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = _load_full_bleed_background("res://assets/sprites/backgrounds/riverside_landscape.jpeg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_child(art)
	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.015, 0.045, 0.055, 0.38)
	background.add_child(tint)


func _load_full_bleed_background(path: String) -> Texture2D:
	var source := ResourceManager.load_texture(path)
	if source == null:
		return null
	var filename := path.get_file()
	var crop_regions := {
		"riverside_landscape.jpeg": Rect2(90, 90, 900, 900),
		"garden_map_tile.jpeg": Rect2(170, 130, 750, 830)
	}
	if not crop_regions.has(filename):
		return source
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = crop_regions[filename]
	return cropped


func _show_loading_screen() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LoadingScreen"
	layer.layer = 9
	add_child(layer)
	var background := TextureRect.new()
	background.texture = _load_full_bleed_background("res://assets/sprites/backgrounds/riverside_landscape.jpeg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	var wash := ColorRect.new()
	wash.color = Color(0.015, 0.055, 0.075, 0.56)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(wash)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.position = Vector2(-170, -175)
	stack.size = Vector2(340, 350)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	wash.add_child(stack)
	var logo := TextureRect.new()
	logo.texture = ResourceManager.load_texture("res://assets/sprites/ui/game_logo_cutout.png")
	logo.custom_minimum_size = Vector2(220, 220)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(logo)
	var loading := _make_label("PREPARING THE SEARCH", 20)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(loading)
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(270, 22)
	progress.show_percentage = false
	progress.max_value = 100
	progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(progress)
	var tween := create_tween()
	tween.tween_property(progress, "value", 100.0, 0.8)
	tween.tween_callback(func():
		layer.queue_free()
		_show_launch_screen()
	)


func _show_launch_screen() -> void:
	_launch_layer = CanvasLayer.new()
	_launch_layer.name = "LaunchScreen"
	_launch_layer.layer = 10
	add_child(_launch_layer)
	var background := TextureRect.new()
	background.texture = _load_full_bleed_background("res://assets/sprites/backgrounds/riverside_landscape.jpeg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.add_child(background)
	var veil := ColorRect.new()
	veil.color = Color(0.008, 0.025, 0.055, 0.48)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.add_child(veil)
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(content)
	var viewport_size := get_viewport_rect().size
	var logo := TextureRect.new()
	logo.position = Vector2(viewport_size.x * 0.20, viewport_size.y * 0.055)
	logo.size = Vector2(viewport_size.x * 0.60, viewport_size.y * 0.25)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture = ResourceManager.load_texture("res://assets/sprites/ui/game_logo_cutout.png")
	content.add_child(logo)
	var family := TextureRect.new()
	family.position = Vector2(viewport_size.x * 0.18, viewport_size.y * 0.32)
	family.size = Vector2(viewport_size.x * 0.64, viewport_size.y * 0.30)
	family.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	family.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	family.texture = ResourceManager.load_texture("res://assets/sprites/characters/amara_and_ethan_portrait_cutout.png")
	content.add_child(family)
	var quest_title := _make_label("THE QUEST FOR ETHAN", 21)
	quest_title.position = Vector2(viewport_size.x * 0.08, viewport_size.y * 0.68)
	quest_title.size = Vector2(viewport_size.x * 0.84, 48)
	quest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(quest_title)
	var tagline := _make_label("ONE NIGHT. THREE CHOICES. FIND ETHAN.", 15)
	tagline.position = Vector2(viewport_size.x * 0.08, viewport_size.y * 0.725)
	tagline.size = Vector2(viewport_size.x * 0.84, 36)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", Color("#f2ce7c"))
	content.add_child(tagline)
	var start := _make_texture_button("play", Vector2(minf(300.0, get_viewport_rect().size.x * 0.66), 92))
	start.position = Vector2((viewport_size.x - minf(300.0, viewport_size.x * 0.66)) * 0.5, viewport_size.y * 0.78)
	start.size = Vector2(minf(300.0, viewport_size.x * 0.66), 92)
	start.pressed.connect(_start_opening_story)
	content.add_child(start)
	var settings_size := Vector2(minf(116.0, viewport_size.x * 0.30), 40.0)
	var settings_button := _make_texture_button("settings", settings_size)
	settings_button.position = Vector2(viewport_size.x - settings_size.x - 18.0, 18.0)
	settings_button.size = settings_size
	settings_button.pressed.connect(_show_title_settings)
	content.add_child(settings_button)
	family.modulate.a = 0.0
	family.scale = Vector2(0.97, 0.97)
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(family, "modulate:a", 1.0, 0.55)
	entrance.tween_property(family, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	logo.modulate.a = 0.0
	var logo_tween := create_tween()
	logo_tween.tween_property(logo, "modulate:a", 1.0, 0.4)
	start.modulate.a = 0.0
	var button_entrance := create_tween()
	button_entrance.tween_interval(0.3)
	button_entrance.tween_property(start, "modulate:a", 1.0, 0.3)
	var idle := _launch_layer.create_tween().set_loops()
	idle.tween_property(family, "position:y", family.position.y - 7.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(family, "position:y", family.position.y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show_title_settings() -> void:
	_show_audio_settings(_launch_layer)


func _start_opening_story() -> void:
	if _launch_layer != null:
		_launch_layer.queue_free()
	_show_story_overlay()
	if _story_manager != null:
		SignalBus.play_sfx.emit("case_open")
		var music_id := str(_story.get("background_music", ""))
		if not music_id.is_empty():
			SignalBus.play_music.emit(music_id)
		_story_manager.start_story("opening_story")


func _build_gameplay_hud() -> void:
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "HUD"
		add_child(hud)
	hud.layer = 2
	hud.visible = true
	var header := Control.new()
	var hud_scale := clampf(get_viewport_rect().size.x / 720.0, 0.52, 1.0)
	header.name = "MissionHeader"
	header.anchor_left = 0.0
	header.anchor_right = 1.0
	header.anchor_top = 0.0
	# Objective artwork values are positioned against the full viewport, so this
	# overlay must occupy the full screen rather than a short header strip.
	header.anchor_bottom = 1.0
	hud.add_child(header)
	_build_dynamic_objective_hud(header)
	var status_row := HBoxContainer.new()
	status_row.name = "StatusRow"
	status_row.anchor_left = 0.035
	status_row.anchor_right = 0.965
	status_row.anchor_top = 0.145
	status_row.anchor_bottom = 0.205
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", roundi(4 * hud_scale))
	var status_backing := Panel.new()
	status_backing.name = "StatusRowBacking"
	status_backing.anchor_left = 0.025
	status_backing.anchor_right = 0.975
	status_backing.anchor_top = 0.107
	status_backing.anchor_bottom = 0.216
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.025, 0.08, 0.105, 0.82)
	backing_style.border_color = Color("#d6b66e")
	backing_style.set_border_width_all(2)
	backing_style.set_corner_radius_all(18)
	backing_style.content_margin_left = 8
	backing_style.content_margin_right = 8
	status_backing.add_theme_stylebox_override("panel", backing_style)
	hud.add_child(status_backing)
	hud.move_child(status_backing, header.get_index() + 1)
	_build_level_objective_row(hud, hud_scale)
	hud.add_child(status_row)
	_build_objective_target_badge(status_row, hud_scale)
	_lives_label = _make_compact_hud_panel(status_row, "LifeHearts", "0/5", Vector2(150, 54) * hud_scale, roundi(21 * hud_scale), Color("#f06c9b"))
	_reward_label = _make_compact_hud_panel(status_row, "CoinCounter", "0", Vector2(154, 54) * hud_scale, roundi(21 * hud_scale), Color("#e9bd55"))
	_star_reward_label = _make_compact_hud_panel(status_row, "StarReward", "☆☆☆", Vector2(70, 54) * hud_scale, roundi(17 * hud_scale), Color("#f4ce49"))
	_level_reward_label = _make_compact_hud_panel(status_row, "LevelReward", "+0", Vector2(64, 54) * hud_scale, roundi(17 * hud_scale), Color("#e9bd55"))
	_pause_button = TextureButton.new()
	_pause_button.name = "SettingsButton"
	_pause_button.ignore_texture_size = true
	_pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_pause_button.custom_minimum_size = Vector2(46, 54) * hud_scale
	var pause_icon := _load_hud_asset("res://assets/sprites/ui/hud/pause_button.png")
	_pause_button.texture_normal = pause_icon
	_pause_button.texture_hover = pause_icon
	_pause_button.texture_pressed = pause_icon
	_pause_button.tooltip_text = "PAUSE AND SETTINGS"
	_pause_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pause_button.pressed.connect(_play_ui_click)
	_pause_button.pressed.connect(_show_pause_menu)
	status_row.add_child(_pause_button)
	_case_file_button = TextureButton.new()
	_case_file_button.name = "CaseFileButton"
	_case_file_button.ignore_texture_size = true
	_case_file_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_case_file_button.custom_minimum_size = Vector2(88, 54) * hud_scale
	_case_file_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var case_file_icon := _load_hud_asset("res://assets/casefile_hud.png")
	var case_file_art := AtlasTexture.new()
	case_file_art.atlas = case_file_icon
	case_file_art.region = Rect2(405, 475, 1110, 350)
	_case_file_button.texture_normal = case_file_art
	_case_file_button.texture_hover = case_file_art
	_case_file_button.texture_pressed = case_file_art
	_case_file_button.tooltip_text = "OPEN CASE FILE"
	_case_file_button.pressed.connect(_show_case_file)
	status_row.add_child(_case_file_button)

	_hint_label = _make_label("INVESTIGATION 01 | THE FIRST CLUE", 22)
	_hint_label.anchor_left = 0.08
	_hint_label.anchor_right = 0.92
	_hint_label.anchor_top = 0.205
	_hint_label.anchor_bottom = 0.235
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color("#fff3d5"))
	_hint_label.add_theme_color_override("font_shadow_color", Color("#302012"))
	_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(_hint_label)
	_hint_label.hide()
	_build_booster_dock(hud)

	_story_layer = CanvasLayer.new()
	_story_layer.name = "OpeningStory"
	_story_layer.layer = 5
	add_child(_story_layer)


func _build_dynamic_objective_hud(parent: Control) -> void:
	var art := TextureRect.new()
	art.name = "DynamicObjectiveArtwork"
	art.anchor_left = 0.025
	art.anchor_right = 0.975
	art.anchor_top = 0.0
	art.anchor_bottom = 0.145
	var objective_texture := _load_hud_asset("res://assets/objective_hud_dynamic.png")
	var cropped_objective := AtlasTexture.new()
	cropped_objective.atlas = objective_texture
	# The supplied art has large magenta margins. Crop to the actual pill so it
	# renders at HUD size rather than shrinking its visible contents.
	cropped_objective.region = Rect2(205, 210, 2230, 310)
	art.texture = cropped_objective
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chroma := Shader.new()
	chroma.code = "shader_type canvas_item;\nuniform vec3 key_color = vec3(1.0, 0.0, 1.0);\nvoid fragment() { vec4 c = texture(TEXTURE, UV) * COLOR; if (distance(c.rgb, key_color) < 0.16) { discard; } COLOR = c; }"
	var material := ShaderMaterial.new()
	material.shader = chroma
	art.material = material
	parent.add_child(art)
	var values := Control.new()
	values.name = "ObjectiveValues"
	values.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	values.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(values)
	var screen_scale := get_viewport_rect().size.x * 0.95 / 2230.0
	_objective_label = _make_label("0", 17)
	# The artwork's value windows sit below the heading, around source y=335.
	# Keep the live values inside those cutouts instead of above the pill.
	_objective_label.position = Vector2(1075, 335) * screen_scale
	_objective_label.size = Vector2(300, 105) * screen_scale
	_objective_label.add_theme_font_size_override("font_size", 20)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_label.add_theme_color_override("font_color", Color("#123d9b"))
	values.add_child(_objective_label)
	_moves_label = _make_label("0", 17)
	_moves_label.position = Vector2(1685, 335) * screen_scale
	_moves_label.size = Vector2(245, 105) * screen_scale
	_moves_label.add_theme_font_size_override("font_size", 20)
	_moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_moves_label.add_theme_color_override("font_color", Color("#123d9b"))
	values.add_child(_moves_label)
	_blocker_label = _make_label("", 12)
	_blocker_label.position = Vector2(1050, 220) * screen_scale
	_blocker_label.size = Vector2(650, 30) * screen_scale
	_blocker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocker_label.add_theme_color_override("font_color", Color("#123d9b"))
	values.add_child(_blocker_label)


func _build_objective_target_badge(parent: Control, hud_scale: float) -> void:
	var badge := PanelContainer.new()
	badge.name = "ObjectiveTargetBadge"
	badge.custom_minimum_size = Vector2(66, 64) * hud_scale
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.08, 0.105, 0.92)
	style.border_color = Color("#e3c275")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(2)
	badge.add_theme_stylebox_override("panel", style)
	parent.add_child(badge)
	var contents := VBoxContainer.new()
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", 0)
	badge.add_child(contents)
	_objective_target_icon = TextureRect.new()
	_objective_target_icon.name = "ObjectiveTargetIcon"
	_objective_target_icon.custom_minimum_size = Vector2(38, 38) * hud_scale
	_objective_target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_objective_target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_objective_target_icon.texture = ResourceManager.load_texture(_objective_icon_path(_objective_target))
	_objective_target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(_objective_target_icon)
	_objective_target_name = _make_label(_objective_hud_title(), maxi(10, roundi(12 * hud_scale)))
	_objective_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_target_name.add_theme_color_override("font_color", Color("#fff3d5"))
	contents.add_child(_objective_target_name)


func _build_level_objective_row(parent: CanvasLayer, hud_scale: float) -> void:
	var row := HBoxContainer.new()
	row.name = "LevelObjectiveRow"
	row.anchor_left = 0.055
	row.anchor_right = 0.945
	row.anchor_top = 0.108
	row.anchor_bottom = 0.145
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", roundi(8 * hud_scale))
	parent.add_child(row)
	var level_chip := Control.new()
	level_chip.name = "LevelNumber"
	level_chip.custom_minimum_size = Vector2(150, 38) * hud_scale
	level_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	level_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	level_chip.clip_contents = true
	var level_art := TextureRect.new()
	level_art.name = "LevelArtwork"
	var level_source := _load_hud_asset("res://assets/level_no.png")
	if level_source != null:
		var level_crop := AtlasTexture.new()
		level_crop.atlas = level_source
		level_crop.region = Rect2(200, 480, 1510, 400)
		level_art.texture = level_crop
	level_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	level_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_hud_chroma_key(level_art)
	level_chip.add_child(level_art)
	_level_number_label = _make_label("01", roundi(20 * hud_scale))
	_level_number_label.anchor_left = 0.65
	_level_number_label.anchor_right = 0.94
	_level_number_label.anchor_top = 0.18
	_level_number_label.anchor_bottom = 0.82
	_level_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_number_label.add_theme_color_override("font_color", Color("#172b49"))
	level_chip.add_child(_level_number_label)
	row.add_child(level_chip)
	_objective_description_label = _make_label("COLLECT THE CLUES", roundi(19 * hud_scale))
	_objective_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_objective_description_label.add_theme_color_override("font_color", Color("#fff5dc"))
	_objective_description_label.add_theme_color_override("font_shadow_color", Color("#14202c"))
	_objective_description_label.add_theme_constant_override("shadow_offset_x", 1)
	_objective_description_label.add_theme_constant_override("shadow_offset_y", 2)
	row.add_child(_objective_description_label)


func _make_compact_hud_panel(parent: Control, panel_name: String, text: String, minimum_size: Vector2, font_size: int, accent: Color) -> Label:
	var uses_generated_art := panel_name in ["MovesCounter", "CoinCounter", "LifeHearts", "StarReward", "LevelReward"]
	var panel: Control = Control.new() if uses_generated_art else PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var content := Control.new()
	if uses_generated_art:
		panel.clip_contents = true
		var panel_art := TextureRect.new()
		panel_art.name = "PanelArt"
		var art_path := "res://assets/moves_template.png"
		match panel_name:
			"CoinCounter":
				art_path = "res://assets/sprites/ui/hud/coin_counter.png"
			"LifeHearts":
				art_path = "res://assets/sprites/ui/hud/lives_counter.png"
			"StarReward":
				art_path = "res://assets/moves_template.png"
			"LevelReward":
				art_path = "res://assets/dollar_sack.png"
		panel_art.texture = _get_cropped_hud_art(panel_name, art_path)
		if panel_name in ["CoinCounter", "LifeHearts", "LevelReward"]:
			panel_art.anchor_left = 0.0
			panel_art.anchor_right = 1.0
			panel_art.anchor_top = 0.05
			panel_art.anchor_bottom = 0.95
		else:
			panel_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_hud_chroma_key(panel_art)
		panel.add_child(panel_art)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#10283d")
		style.border_color = accent
		style.set_border_width_all(2)
		style.set_corner_radius_all(15)
		style.set_content_margin_all(4)
		(panel as PanelContainer).add_theme_stylebox_override("panel", style)
		content.custom_minimum_size = minimum_size - Vector2(8, 8)
	parent.add_child(panel)
	panel.add_child(content)
	var label := Label.new()
	label.name = "Value"
	label.text = text
	if uses_generated_art:
		label.anchor_left = 0.58 if panel_name in ["CoinCounter", "LifeHearts"] else (0.48 if panel_name in ["MovesCounter", "LevelReward"] else 0.12)
		label.anchor_right = 0.94
		label.anchor_top = 0.24 if panel_name in ["CoinCounter", "LifeHearts"] else (0.32 if panel_name in ["StarReward", "LevelReward"] else (0.43 if panel_name == "MovesCounter" else 0.24))
		label.anchor_bottom = 0.80 if panel_name in ["MovesCounter", "StarReward", "LevelReward"] else 0.76
	else:
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#fff5dc"))
	label.add_theme_color_override("font_shadow_color", Color("#14202c"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if uses_generated_art:
		if panel_name in ["LifeHearts", "CoinCounter"]:
			label.add_theme_color_override("font_color", Color("#102640"))
			label.add_theme_color_override("font_outline_color", Color("#fff8df"))
			label.add_theme_constant_override("outline_size", 1)
		else:
			label.add_theme_color_override("font_color", Color("#60401c"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	content.add_child(label)
	if panel_name == "CoinCounter":
		var shop_hitbox := Button.new()
		shop_hitbox.name = "OpenLifeShop"
		shop_hitbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shop_hitbox.flat = true
		shop_hitbox.tooltip_text = "Spend Ethan Coins on lives"
		shop_hitbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		shop_hitbox.pressed.connect(_show_life_shop)
		content.add_child(shop_hitbox)
	return label


func _get_cropped_hud_art(panel_name: String, path: String) -> Texture2D:
	var source := _load_hud_asset(path)
	if source == null:
		return null
	if path.begins_with("res://assets/sprites/ui/hud/"):
		return source
	var regions := {
		"StarReward": Rect2(250, 345, 1420, 570),
		"MovesCounter": Rect2(120, 210, 1680, 760)
	}
	if not regions.has(panel_name):
		return source
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = regions[panel_name]
	return cropped


func _apply_hud_chroma_key(target: TextureRect) -> void:
	var chroma := Shader.new()
	chroma.code = "shader_type canvas_item;\nuniform vec3 key_color = vec3(1.0, 0.0, 1.0);\nvoid fragment() { vec4 c = texture(TEXTURE, UV) * COLOR; if (distance(c.rgb, key_color) < 0.16) { discard; } COLOR = c; }"
	var material := ShaderMaterial.new()
	material.shader = chroma
	target.material = material


func _build_moves_panel(parent: Control, ui_scale: float) -> Label:
	return _make_compact_hud_panel(parent, "MovesCounter", "30", Vector2(112, 64) * ui_scale, roundi(24 * ui_scale), Color("#38c8e5"))


func _build_objective_panel(parent: Control, ui_scale: float) -> Label:
	var panel := Control.new()
	panel.name = "ObjectiveCard"
	panel.custom_minimum_size = Vector2(150, 88) * ui_scale
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.clip_contents = true
	parent.add_child(panel)
	var objective_body := PanelContainer.new()
	objective_body.position = Vector2(4, 42) * ui_scale
	objective_body.size = Vector2(142, 44) * ui_scale
	var body_style := StyleBoxFlat.new()
	body_style.bg_color = Color("#512c7d")
	body_style.border_color = Color("#e2bf72")
	body_style.set_border_width_all(maxi(1, roundi(2 * ui_scale)))
	body_style.set_corner_radius_all(roundi(11 * ui_scale))
	objective_body.add_theme_stylebox_override("panel", body_style)
	panel.add_child(objective_body)
	var title_art := TextureRect.new()
	title_art.name = "ObjectiveTitleArt"
	title_art.texture = _load_hud_asset("res://assets/sprites/ui/hud/objective_title.png")
	title_art.position = Vector2.ZERO
	title_art.size = Vector2(150, 48) * ui_scale
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_art)
	_objective_label = _make_label("0 / 10", roundi(27 * ui_scale))
	_objective_label.position = Vector2(34, 54) * ui_scale
	_objective_label.size = Vector2(108, 24) * ui_scale
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(_objective_label)
	_blocker_label = _make_label("", roundi(13 * ui_scale))
	_blocker_label.position = Vector2(0, 78) * ui_scale
	_blocker_label.size = Vector2(150, 12) * ui_scale
	_blocker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocker_label.add_theme_color_override("font_color", Color("#ffe279"))
	panel.add_child(_blocker_label)
	return _objective_label


func _set_objective_icon(target: String) -> void:
	if _objective_label == null:
		return
	var panel := _objective_label.get_parent() as Control
	var previous := panel.get_node_or_null("ObjectiveIcon")
	if previous != null:
		previous.queue_free()
	var icon := TextureRect.new()
	icon.name = "ObjectiveIcon"
	icon.size = Vector2(26, 26) * clampf(panel.custom_minimum_size.x / 150.0, 0.88, 1.0)
	icon.position = Vector2(7, 55) * clampf(panel.custom_minimum_size.x / 150.0, 0.88, 1.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = ResourceManager.load_texture(_objective_icon_path(target))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)


func _load_hud_asset(path: String) -> Texture2D:
	return ResourceManager.load_texture(path)


func _build_booster_dock(parent: CanvasLayer) -> void:
	var dock := PanelContainer.new()
	dock.name = "BoosterDock"
	dock.anchor_left = 0.08
	dock.anchor_right = 0.92
	dock.anchor_top = 0.80
	dock.anchor_bottom = 0.91
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.055, 0.08, 0.92)
	style.border_color = Color("#e3c275")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(6)
	dock.add_theme_stylebox_override("panel", style)
	parent.add_child(dock)
	var booster_row := HBoxContainer.new()
	booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	booster_row.add_theme_constant_override("separation", 12)
	dock.add_child(booster_row)
	_booster_dock = dock
	var icon_paths := {
		"rocket": "res://assets/sprites/powerups/rocket_powerup_icon.jpeg",
		"bomb": "res://assets/sprites/powerups/bomb_powerup_icon.jpeg",
		"thunder": "res://assets/sprites/powerups/thunder_powerup_icon.jpeg",
		"ethan": "res://assets/sprites/characters/ethan_portrait_cutout.png"
	}
	for kind in ["rocket", "bomb", "thunder", "ethan"]:
		var wrapper := VBoxContainer.new()
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_theme_constant_override("separation", 0)
		booster_row.add_child(wrapper)
		var button := TextureButton.new()
		button.name = "%sPowerup" % kind.capitalize()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(78, 70)
		button.texture_normal = ResourceManager.load_texture(icon_paths[kind])
		button.texture_hover = button.texture_normal
		button.texture_pressed = button.texture_normal
		button.pressed.connect(_on_booster_pressed.bind(kind))
		wrapper.add_child(button)
		var name_label := _make_label(kind.to_upper(), 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wrapper.add_child(name_label)
		var count_label := _make_label("0", 22)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wrapper.add_child(count_label)
		_booster_buttons[kind] = {"button": button, "count": count_label}
	dock.show()


func _make_texture_button(name: String, button_size: Vector2, folder: String = "buttons") -> TextureButton:
	var button := TextureButton.new()
	button.name = name.capitalize() + "Button"
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = button_size
	button.texture_normal = ResourceManager.load_texture("res://assets/sprites/ui/%s/%s_normal.png" % [folder, name])
	button.texture_hover = ResourceManager.load_texture("res://assets/sprites/ui/%s/%s_hover.png" % [folder, name])
	button.texture_pressed = ResourceManager.load_texture("res://assets/sprites/ui/%s/%s_pressed.png" % [folder, name])
	button.pressed.connect(_play_ui_click)
	return button


func _show_pause_menu() -> void:
	if _pause_layer != null:
		return
	if _tutorial_active and _tutorial_action != "pause":
		return
	if _tutorial_active:
		_tutorial_pause_open = true
		_tutorial_action = "pause_open"
		if _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()
	get_tree().paused = true
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager != null:
		audio_manager.pause_music()
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseMenuLayer"
	_pause_layer.layer = 12
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.035, 0.82)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(minf(520.0, get_viewport_rect().size.x * 0.9), 580 if _tutorial_active else 470)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#102338")
	panel_style.border_color = Color("#d6b66e")
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(28)
	panel_style.set_content_margin_all(28)
	frame.add_theme_stylebox_override("panel", panel_style)
	center.add_child(frame)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	frame.add_child(actions)
	var heading := _make_label("PAUSED", 34)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(heading)
	if _tutorial_active:
		var pause_guide := _make_label("RESUME returns to this board. MUSIC and SOUND FX toggle independently. SETTINGS has separate volume sliders. RETURN TO TITLE exits this investigation.", 17)
		pause_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pause_guide.custom_minimum_size = Vector2(0, 88)
		pause_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		actions.add_child(pause_guide)
	var resume := _make_menu_button("RESUME")
	resume.pressed.connect(_close_pause_menu)
	actions.add_child(resume)
	var settings := _make_menu_button("SETTINGS")
	settings.pressed.connect(_show_settings_popup)
	actions.add_child(settings)
	var music := _make_menu_button("MUSIC: ON")
	music.pressed.connect(_toggle_audio_bus.bind(music, "music"))
	actions.add_child(music)
	var effects := _make_menu_button("SOUND FX: ON")
	effects.pressed.connect(_toggle_audio_bus.bind(effects, "sfx"))
	actions.add_child(effects)
	var title := _make_menu_button("RETURN TO TITLE")
	title.pressed.connect(_return_to_title)
	actions.add_child(title)
	if audio_manager != null:
		music.text = "MUSIC: OFF" if not audio_manager.is_music_enabled() else "MUSIC: ON"
		effects.text = "SOUND FX: OFF" if not audio_manager.is_sfx_enabled() else "SOUND FX: ON"


func _make_menu_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(350, 66)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_color_override("font_color", Color("#fff3d5"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#21466a")
	normal.border_color = Color("#d6b66e")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#2f628f")
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(_play_ui_click)
	return button


func _play_ui_click() -> void:
	SignalBus.play_sfx.emit("ui_click")


func _play_ui_confirm() -> void:
	SignalBus.play_sfx.emit("ui_confirm")


func _close_pause_menu() -> void:
	get_tree().paused = false
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager != null:
		audio_manager.resume_music()
	if _pause_layer != null:
		_pause_layer.queue_free()
	_pause_layer = null
	if _tutorial_pause_open:
		_tutorial_pause_open = false
		_tutorial_action = "field_guide"
		if _board != null:
			_board.lock()
		_refresh_tutorial_controls()
		_show_tutorial_tip(
			"Amara's case file explains each piece of evidence. Open it before you continue the search.",
			_button_screen_rect(_case_file_button),
			"DAVID",
			"res://assets/sprites/characters/david_portrait_cutout.png"
		)


func _show_case_file() -> void:
	if _case_file_layer != null or (_tutorial_active and _tutorial_action != "field_guide"):
		return
	if _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	_case_file_was_board_locked = _board != null and _board.is_locked()
	if _board != null:
		_board.cancel_booster_mode()
		_board.clear_required_swap()
		_board.lock()
	_case_file_layer = CanvasLayer.new()
	_case_file_layer.name = "EvidenceCaseFile"
	_case_file_layer.layer = 20
	_case_file_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_case_file_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.008, 0.025, 0.05, 0.88)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_case_file_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(minf(650.0, get_viewport_rect().size.x * 0.92), minf(820.0, get_viewport_rect().size.y * 0.88))
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#10263d")
	card_style.border_color = Color("#e2bf72")
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(26)
	card_style.set_content_margin_all(24)
	card_style.shadow_color = Color(0, 0, 0, 0.58)
	card_style.shadow_size = 16
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation", 18)
	content.add_child(intro)
	var amara := TextureRect.new()
	amara.custom_minimum_size = Vector2(94, 108)
	amara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	amara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	amara.texture = ResourceManager.load_texture("res://assets/sprites/characters/amara_police_portrait_cutout.png")
	intro.add_child(amara)
	var intro_copy := VBoxContainer.new()
	intro_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(intro_copy)
	var title := _make_label("AMARA'S EVIDENCE BOARD", 24)
	intro_copy.add_child(title)
	var explanation := _make_label("Any three matching pieces clear. Only the evidence type shown in the goal card advances this case.", 17)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_copy.add_child(explanation)
	var entries: Array[Dictionary] = [
		{"name": "KEY", "icon": "key_objective_icon.jpeg", "meaning": "A lock or gate Victor opened. Match keys when the case goal asks for them."},
		{"name": "PHONE", "icon": "phone_evidence_icon.svg", "meaning": "A call or location trace that can point toward Victor."},
		{"name": "FINGERPRINT", "icon": "fingerprint_evidence_icon.jpeg", "meaning": "A trace that can connect an object to the person who handled it."},
		{"name": "RECORDER", "icon": "recorder_evidence_icon.jpeg", "meaning": "A recording that may reveal a voice or a hidden clue."},
		{"name": "CLOCK", "icon": "timer_objective_icon.jpeg", "meaning": "A timestamp that helps the team reconstruct when the trail moved."}
	]
	for entry in entries:
		var row := PanelContainer.new()
		row.custom_minimum_size.y = 76
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color("#193a56")
		row_style.border_color = Color("#52708a")
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(14)
		row_style.set_content_margin_all(8)
		row.add_theme_stylebox_override("panel", row_style)
		content.add_child(row)
		var row_content := HBoxContainer.new()
		row_content.add_theme_constant_override("separation", 14)
		row.add_child(row_content)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(58, 58)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ResourceManager.load_texture("res://assets/sprites/tiles/" + str(entry["icon"]))
		row_content.add_child(icon)
		var copy := VBoxContainer.new()
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 1)
		row_content.add_child(copy)
		var tile_name := _make_label(str(entry["name"]), 16)
		tile_name.add_theme_color_override("font_color", Color("#f2ce7c"))
		copy.add_child(tile_name)
		var meaning := _make_label(str(entry["meaning"]), 15)
		meaning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(meaning)
	var close := _make_story_action_button("BACK TO SEARCH", 240)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_case_file)
	content.add_child(close)
	card.modulate.a = 0.0
	var entrance := create_tween()
	entrance.tween_property(card, "modulate:a", 1.0, 0.2)


func _close_case_file() -> void:
	SignalBus.play_sfx.emit("case_close")
	if _case_file_layer != null and is_instance_valid(_case_file_layer):
		_case_file_layer.queue_free()
	_case_file_layer = null
	if _tutorial_active and _tutorial_action == "field_guide":
		_finish_tutorial()
	elif _board != null and not _case_file_was_board_locked:
		_board.unlock()


func _toggle_audio_bus(button: Button, kind: String) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null:
		return
	if kind == "music":
		audio_manager.set_music_enabled(not audio_manager.is_music_enabled())
		button.text = "MUSIC: ON" if audio_manager.is_music_enabled() else "MUSIC: OFF"
	else:
		audio_manager.set_sfx_enabled(not audio_manager.is_sfx_enabled())
		button.text = "SOUND FX: ON" if audio_manager.is_sfx_enabled() else "SOUND FX: OFF"


func _show_settings_popup() -> void:
	_show_audio_settings(_pause_layer)


func _show_gameplay_audio_settings() -> void:
	if _tutorial_active and _tutorial_action != "settings":
		return
	_show_audio_settings(get_node_or_null("HUD"))


func _show_audio_settings(parent_layer: Node) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null or parent_layer == null:
		return
	var popup := AcceptDialog.new()
	popup.title = "AUDIO SETTINGS"
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	parent_layer.add_child(popup)
	if _tutorial_active and _tutorial_action == "settings" and _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	var settings := VBoxContainer.new()
	settings.custom_minimum_size = Vector2(minf(420.0, get_viewport_rect().size.x * 0.78), 190)
	for bus_kind in ["music", "sfx"]:
		var volume_label := Label.new()
		volume_label.text = "Background music" if bus_kind == "music" else "Sound effects"
		settings.add_child(volume_label)
		var volume := HSlider.new()
		volume.min_value = 0.0
		volume.max_value = 1.0
		volume.step = 0.01
		volume.value = audio_manager.get_music_volume() if bus_kind == "music" else audio_manager.get_sfx_volume()
		volume.value_changed.connect(_set_audio_volume.bind(bus_kind))
		settings.add_child(volume)
		var enabled := CheckButton.new()
		enabled.button_pressed = audio_manager.is_music_enabled() if bus_kind == "music" else audio_manager.is_sfx_enabled()
		enabled.text = "Enabled" if enabled.button_pressed else "Disabled"
		enabled.toggled.connect(_set_audio_enabled.bind(bus_kind, enabled))
		settings.add_child(enabled)
	popup.add_child(settings)
	if _tutorial_active and _tutorial_action == "settings":
		popup.confirmed.connect(_on_tutorial_settings_confirmed, CONNECT_ONE_SHOT)
	popup.popup_centered()


func _on_tutorial_settings_confirmed() -> void:
	if not _tutorial_active or _tutorial_action != "settings":
		return
	_tutorial_action = "pause"
	_refresh_tutorial_controls()
	_show_tutorial_tip(
		"Music and sound effects each have separate controls. The gear also opens the pause menu so you can resume or leave the investigation.",
		_button_screen_rect(_pause_button),
		"DAVID",
		"res://assets/sprites/characters/david_portrait_cutout.png"
	)


func _set_audio_volume(value: float, kind: String) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null:
		return
	if kind == "music":
		audio_manager.set_music_volume(value)
		audio_manager.set_music_enabled(value > 0.0)
	else:
		audio_manager.set_sfx_volume(value)
		audio_manager.set_sfx_enabled(value > 0.0)


func _set_audio_enabled(enabled: bool, kind: String, indicator: CheckButton) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null:
		return
	indicator.text = "Enabled" if enabled else "Disabled"
	if kind == "music":
		audio_manager.set_music_enabled(enabled)
	else:
		audio_manager.set_sfx_enabled(enabled)


func _return_to_title() -> void:
	SignalBus.play_sfx.emit("ui_back")
	SignalBus.stop_music.emit()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", Color("#fff3d5"))
	label.add_theme_color_override("font_shadow_color", Color("#102238"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("font_outline_color", Color("#182538"))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", font_size)
	if font_size >= 24:
		label.add_theme_font_override("font", DISPLAY_FONT)
		label.add_theme_constant_override("outline_size", 4)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _prepare_opening_story() -> void:
	_story_manager = get_node_or_null("Managers/StoryManager") as StoryManager
	if _story_manager == null or not _story_manager.load_story("opening_story"):
		DebugLogger.error("Game: Opening story could not be loaded by StoryManager.")
		return
	_story = _story_manager.get_story_data()
	if not _story_manager.dialogue_started.is_connected(_on_dialogue_started):
		_story_manager.dialogue_started.connect(_on_dialogue_started)
	if not _story_manager.story_finished.is_connected(_on_story_finished):
		_story_manager.story_finished.connect(_on_story_finished)
	if not SignalBus.story_choice_presented.is_connected(_present_route_choices):
		SignalBus.story_choice_presented.connect(_present_route_choices)
	if not SignalBus.choice_selected.is_connected(_on_route_selected):
		SignalBus.choice_selected.connect(_on_route_selected)


func _show_story_overlay() -> void:
	var viewport_size := get_viewport_rect().size
	var background := _story_layer.get_node_or_null("StoryBackground") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "StoryBackground"
		_story_layer.add_child(background)
	background.texture = _load_full_bleed_background(str(_story.get("default_background", "")))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var veil := ColorRect.new()
	veil.name = "StoryVeil"
	veil.color = Color(0.008, 0.02, 0.045, 0.54)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_layer.add_child(veil)
	var title := _make_label(str(_story.get("title", "The Night Ethan Vanished")), 24)
	title.anchor_left = 0.06
	title.anchor_right = 0.94
	title.anchor_top = 0.025
	title.anchor_bottom = 0.075
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 2
	veil.add_child(title)
	_story_portrait = TextureRect.new()
	_story_portrait.position = Vector2(viewport_size.x * 0.17, viewport_size.y * 0.075)
	_story_portrait.size = Vector2(viewport_size.x * 0.66, viewport_size.y * 0.47)
	_story_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_story_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_story_portrait.z_index = 1
	_story_portrait.texture = ResourceManager.load_texture(str(_story.get("portrait", "")))
	veil.add_child(_story_portrait)
	var dialogue_panel := PanelContainer.new()
	dialogue_panel.name = "StoryDialoguePanel"
	dialogue_panel.anchor_left = 0.045
	dialogue_panel.anchor_right = 0.955
	dialogue_panel.anchor_top = 0.565
	dialogue_panel.anchor_bottom = 0.97
	dialogue_panel.offset_top = 58.0
	dialogue_panel.offset_bottom = 58.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.065, 0.115, 0.97)
	panel_style.border_color = Color("#d9b86f")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.set_content_margin_all(22)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 14
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	veil.add_child(dialogue_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(content)
	_speaker_label = _make_label("", 23)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speaker_label.add_theme_color_override("font_color", Color("#f2ce7c"))
	content.add_child(_speaker_label)
	_dialogue_label = _make_label("", 23)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.custom_minimum_size = Vector2(0, 112)
	_dialogue_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.add_theme_color_override("font_color", Color("#fff8e8"))
	_dialogue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	content.add_child(_dialogue_label)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 8)
	content.add_child(_choice_box)
	var story_actions := HBoxContainer.new()
	story_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	story_actions.add_theme_constant_override("separation", 10)
	content.add_child(story_actions)
	_story_previous_button = _make_story_action_button("BACK", 112)
	_story_previous_button.pressed.connect(_previous_story_dialogue)
	_story_previous_button.hide()
	story_actions.add_child(_story_previous_button)
	_story_skip_button = _make_story_action_button("SKIP", 112)
	_story_skip_button.pressed.connect(_skip_opening_story)
	story_actions.add_child(_story_skip_button)
	_story_continue_button = _make_story_action_button("CONTINUE", 190)
	_story_continue_button.pressed.connect(_advance_story)
	story_actions.add_child(_story_continue_button)
	_dialogue_label.text = ""
	_speaker_label.text = ""
	dialogue_panel.modulate.a = 0.0
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(dialogue_panel, "modulate:a", 1.0, 0.28)
	entrance.tween_property(dialogue_panel, "offset_top", 0.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(dialogue_panel, "offset_bottom", 0.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_story_action_button(caption: String, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(width, 54)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_color_override("font_color", Color("#fff5db"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#244d70")
	normal.border_color = Color("#d9b86f")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#3475a2")
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(_play_ui_click)
	return button


func _advance_story() -> void:
	if _is_dialogue_typing:
		_finish_dialogue_typing()
		return
	if _story_manager != null:
		_story_manager.next_dialogue()


func _finish_dialogue_typing() -> void:
	if _dialogue_label != null:
		_dialogue_label.visible_characters = -1
	_is_dialogue_typing = false
	if _story_continue_button != null:
		_story_continue_button.disabled = false
		_story_continue_button.text = "CONTINUE"


func _animate_choice_button(button: Control, target_scale: float) -> void:
	if not is_instance_valid(button):
		return
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, 0.1)


func _previous_story_dialogue() -> void:
	if _story_manager != null:
		_story_manager.previous_dialogue()


func _on_dialogue_started(_dialogue_id: Variant) -> void:
	if _story_manager == null:
		return
	var line := _story_manager.get_current_dialogue()
	var story_sound := str(line.get("sfx", ""))
	if not story_sound.is_empty():
		SignalBus.play_sfx.emit(story_sound)
	_speaker_label.text = str(line.get("speaker", ""))
	_dialogue_label.text = str(line.get("text", ""))
	var portrait_path := str(line.get("portrait", ""))
	if portrait_path.is_empty():
		var portraits := {
			"Amara": "amara_and_ethan_portrait_cutout.png",
			"David": "david_portrait_cutout.png",
			"Ethan": "ethan_portrait_cutout.png",
			"Victor": "victor_portrait_dark_cutout.png",
			"Detective Morris": "detective_portrait_cutout.png",
			"Unknown number": "victor_portrait_dark_cutout.png"
		}
		portrait_path = "res://assets/sprites/characters/" + str(portraits.get(str(line.get("speaker", "")), "amara_and_ethan_portrait_cutout.png"))
	if not portrait_path.is_empty():
		_story_portrait.texture = ResourceManager.load_texture(portrait_path)
	_dialogue_label.visible_characters = 0
	_is_dialogue_typing = true
	_story_continue_button.disabled = false
	_story_continue_button.text = "TAP TO REVEAL"
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_label, "visible_characters", _dialogue_label.text.length(), maxf(0.65, _dialogue_label.text.length() * 0.028))
	_dialogue_tween.finished.connect(_finish_dialogue_typing)
	_story_previous_button.visible = int(_dialogue_id) > 0
	_story_portrait.modulate.a = 0.0
	_story_portrait.scale = Vector2(0.94, 0.94)
	var portrait_tween := create_tween().set_parallel(true)
	portrait_tween.tween_property(_story_portrait, "modulate:a", 1.0, 0.3)
	portrait_tween.tween_property(_story_portrait, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _present_route_choices(choices: Array) -> void:
	if not _choice_box.get_children().is_empty():
		return
	_speaker_label.text = "CHOOSE DAVID'S FIRST MOVE"
	_dialogue_label.text = "Each choice sets the team's approach. See the immediate consequence before you decide."
	_dialogue_label.custom_minimum_size.y = 58
	_dialogue_label.visible_characters = -1
	_is_dialogue_typing = false
	_story_continue_button.hide()
	_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/david_portrait_cutout.png")
	_story_portrait.position = Vector2(get_viewport_rect().size.x * 0.36, get_viewport_rect().size.y * 0.12)
	_story_portrait.size = Vector2(get_viewport_rect().size.x * 0.28, get_viewport_rect().size.y * 0.36)
	_story_skip_button.hide()
	_story_previous_button.hide()
	for choice in choices:
		var button := Button.new()
		button.text = "%s\n%s" % [str(choice.get("label", "Choose")).to_upper(), str(choice.get("impact", choice.get("response", "Begin the search.")))]
		button.custom_minimum_size = Vector2(0, 82)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("#fff7e6"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_constant_override("h_separation", 12)
		var choice_style := StyleBoxFlat.new()
		choice_style.bg_color = Color("#1c3f5f")
		choice_style.border_color = Color("#c9a865")
		choice_style.set_border_width_all(2)
		choice_style.set_corner_radius_all(14)
		choice_style.set_content_margin(SIDE_LEFT, 14)
		choice_style.set_content_margin(SIDE_RIGHT, 14)
		choice_style.set_content_margin(SIDE_TOP, 8)
		choice_style.set_content_margin(SIDE_BOTTOM, 8)
		button.add_theme_stylebox_override("normal", choice_style)
		var choice_hover := choice_style.duplicate() as StyleBoxFlat
		choice_hover.bg_color = Color("#2d628e")
		button.add_theme_stylebox_override("hover", choice_hover)
		button.pressed.connect(_select_route.bind(choice))
		button.pressed.connect(_play_ui_confirm)
		button.mouse_entered.connect(_animate_choice_button.bind(button, 1.04))
		button.mouse_exited.connect(_animate_choice_button.bind(button, 1.0))
		_choice_box.add_child(button)
		button.modulate.a = 0.0
		var choice_tween := create_tween()
		choice_tween.tween_interval(0.08 * (_choice_box.get_child_count() - 1))
		choice_tween.tween_property(button, "modulate:a", 1.0, 0.18)


func _select_route(choice: Dictionary) -> void:	
	var route_id := str(choice.get("id", "alone"))
	if _story_manager != null:
		_story_manager.select_choice(choice)
		_story_manager.record_choice(route_id)


func _skip_opening_story() -> void:
	if _pending_level_id > 0:
		if _story_manager != null:
			_story_manager.skip_story()
		return
	_show_campaign_map("alone")


func _on_route_selected(choice: Dictionary) -> void:
	for button in _choice_box.get_children():
		button.disabled = true
		button.queue_free()
	var route_id := str(choice.get("id", "alone"))
	if route_id == "police":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/detective_portrait_cutout.png")
	elif route_id == "signal":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/amara_police_portrait_cutout.png")
	else:
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/david_portrait_cutout.png")
	_speaker_label.text = str(choice.get("label", ""))
	_dialogue_label.text = str(choice.get("response", "The search begins."))
	_story_continue_button.text = "CAMPAIGN MAP"
	_story_continue_button.show()
	_story_continue_button.pressed.disconnect(_advance_story)
	_chosen_route_label = str(choice.get("label", "Begin the search"))
	_story_continue_button.pressed.connect(_show_campaign_map.bind(route_id), CONNECT_ONE_SHOT)
	set_meta("chosen_route", route_id)


func _show_campaign_map(route_id: String) -> void:
	if _story_layer != null and is_instance_valid(_story_layer):
		_story_layer.queue_free()
		_story_layer = null
	if _campaign_layer != null and is_instance_valid(_campaign_layer):
		_campaign_layer.queue_free()
	_campaign_layer = CanvasLayer.new()
	_campaign_layer.name = "CampaignMapLayer"
	_campaign_layer.layer = 9
	add_child(_campaign_layer)
	var campaign_script := load("res://scripts/ui/CampaignMap.gd") as Script
	if campaign_script == null:
		DebugLogger.error("Game: Campaign map screen could not be loaded.")
		return
	_campaign_map = campaign_script.new() as Control
	_campaign_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_campaign_map.configure(_chosen_route_label, _load_campaign_level_records(), _highest_unlocked_level, _completed_levels)
	_campaign_map.level_selected.connect(_on_campaign_level_selected.bind(route_id))
	_campaign_map.back_requested.connect(_show_launch_screen)
	_campaign_layer.add_child(_campaign_map)
	_campaign_map.modulate.a = 0.0
	var entrance := create_tween()
	entrance.tween_property(_campaign_map, "modulate:a", 1.0, 0.3)
	if not _campaign_coach_shown:
		_campaign_coach_shown = true
		call_deferred("_show_campaign_map_coach")


func _show_campaign_map_coach() -> void:
	if _campaign_map == null or not is_instance_valid(_campaign_map):
		return
	var target_rect: Rect2 = _campaign_map.get_level_screen_rect(1)
	if target_rect.size == Vector2.ZERO:
		return
	_tutorial_action = "campaign_map_intro"
	_show_tutorial_tip(
		"This is the campaign trail. Each marker opens an investigation; chapters show where the search moves next. Start with the glowing first case.",
		target_rect,
		"DAVID",
		"res://assets/sprites/characters/david_portrait_cutout.png",
		true
	)


func _load_campaign_level_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var level_directory := DirAccess.open("res://levels")
	if level_directory == null:
		DebugLogger.error("Game: Could not read campaign level data.")
		return records
	for file_name in level_directory.get_files():
		if not file_name.begins_with("level") or not file_name.ends_with(".json"):
			continue
		var record: Dictionary = JsonLoader.load_file("res://levels/" + file_name)
		if not record.is_empty():
			records.append(record)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("level_id", 0)) < int(b.get("level_id", 0)))
	return records


func _on_campaign_level_selected(level_id: int, route_id: String) -> void:
	if level_id > _highest_unlocked_level:
		return
	if _economy_manager != null and _economy_manager.get_lives() <= 0:
		_show_life_shop()
		return
	SignalBus.play_sfx.emit("door_open")
	if _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	if _tutorial_action == "campaign_map_intro":
		_tutorial_action = ""
	var level_manager := get_node_or_null("Managers/LevelManager")
	if level_manager == null or not level_manager.load_level(level_id):
		DebugLogger.error("Game: Could not load selected level %03d." % level_id)
		return
	if _campaign_layer != null and is_instance_valid(_campaign_layer):
		_campaign_layer.queue_free()
	_campaign_layer = null
	_campaign_map = null
	var level_data: Dictionary = level_manager.get_level_data()
	var story_data: Dictionary = level_data.get("story", {})
	var story_id := str(story_data.get("before_level", ""))
	if not story_id.is_empty() and JsonLoader.file_exists("res://stories/" + story_id + ".json"):
		_pending_level_id = level_id
		_pending_route_id = route_id
		_pending_story_id = story_id
		_start_campaign_story(story_id)
	else:
		_show_level_briefing(route_id)


func _start_campaign_story(story_id: String) -> void:
	if _story_manager == null or not _story_manager.load_story(story_id):
		DebugLogger.error("Game: Campaign story could not be loaded -> %s" % story_id)
		_pending_level_id = 0
		_pending_story_id = ""
		_show_level_briefing(_pending_route_id)
		return
	_story = _story_manager.get_story_data()
	SignalBus.play_sfx.emit("case_open")
	_story_layer = CanvasLayer.new()
	_story_layer.name = "CampaignStory"
	_story_layer.layer = 5
	add_child(_story_layer)
	_show_story_overlay()
	_story_manager.start_story(story_id)


func _on_story_finished(story_id: String) -> void:
	if _pending_level_id <= 0 or story_id != _pending_story_id:
		return
	var route_id := _pending_route_id
	_pending_level_id = 0
	_pending_route_id = ""
	_pending_story_id = ""
	_show_level_briefing(route_id)


func _show_level_briefing(route_id: String) -> void:
	SignalBus.play_sfx.emit("case_open")
	if _story_layer != null and is_instance_valid(_story_layer):
		_story_layer.queue_free()
		_story_layer = null

	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	if level_data.is_empty():
		DebugLogger.error("Game: Cannot show briefing because no level data is loaded.")
		return

	_briefing_layer = CanvasLayer.new()
	_briefing_layer.name = "LevelBriefing"
	_briefing_layer.layer = 10
	add_child(_briefing_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.008, 0.02, 0.035, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_briefing_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MissionCard"
	panel.custom_minimum_size = Vector2(minf(590.0, get_viewport_rect().size.x * 0.9), minf(790.0, get_viewport_rect().size.y * 0.88))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#102238")
	panel_style.border_color = Color("#d0ac67")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(24)
	panel_style.set_content_margin_all(28)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(panel, "modulate:a", 1.0, 0.28)
	entrance.tween_property(panel, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	var level_id := int(level_data.get("level_id", 1))
	var level_title := _make_label("INVESTIGATION %02d" % level_id, 18)
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(level_title)
	var title := _make_label(str(level_data.get("name", "The First Clue")), 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(154, 154)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_paths := {
		"police": "res://assets/sprites/characters/detective_portrait_cutout.png",
		"signal": "res://assets/sprites/characters/amara_police_portrait_cutout.png",
		"alone": "res://assets/sprites/characters/david_portrait_cutout.png"
	}
	portrait.texture = ResourceManager.load_texture(str(portrait_paths.get(route_id, portrait_paths["alone"])))
	content.add_child(portrait)
	var route_label := _make_label("APPROACH | " + _chosen_route_label.to_upper(), 17)
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_label)
	var description := _make_label(str(level_data.get("description", "")), 19)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 480
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(description)
	var route_briefings := {
		"police": "Detective Morris is securing the house while you gather evidence for his team.",
		"signal": "Amara is tracing Victor's phone. The clues you collect will narrow her search.",
		"alone": "David is following the trail alone. Every clue must point him toward Ethan."
	}
	var route_detail := _make_label(str(route_briefings.get(route_id, route_briefings["alone"])), 17)
	route_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail.custom_minimum_size.x = 480
	route_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_detail)

	var objective := _get_primary_objective(level_data)
	var objective_panel := PanelContainer.new()
	var objective_style := StyleBoxFlat.new()
	objective_style.bg_color = Color("#1b3952")
	objective_style.border_color = Color("#bb985d")
	objective_style.set_border_width_all(2)
	objective_style.set_corner_radius_all(16)
	objective_style.set_content_margin_all(14)
	objective_panel.add_theme_stylebox_override("panel", objective_style)
	content.add_child(objective_panel)
	var objective_row := HBoxContainer.new()
	objective_row.alignment = BoxContainer.ALIGNMENT_CENTER
	objective_row.add_theme_constant_override("separation", 16)
	objective_panel.add_child(objective_row)
	var objective_icon := TextureRect.new()
	objective_icon.custom_minimum_size = Vector2(82, 82)
	objective_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	objective_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	objective_icon.texture = ResourceManager.load_texture(_objective_icon_path(str(objective.get("target", ""))))
	objective_row.add_child(objective_icon)
	var objective_copy := VBoxContainer.new()
	objective_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	var objective_heading := _make_label("MISSION OBJECTIVE", 15)
	objective_copy.add_child(objective_heading)
	var objective_text := _make_label(_format_objective(objective), 22)
	objective_copy.add_child(objective_text)
	objective_row.add_child(objective_copy)

	var moves_total := int(level_data.get("moves", {}).get("total", 0))
	var difficulty := str(level_data.get("difficulty", "NORMAL")).replace("_", " ")
	var difficulty_label := _make_label("DIFFICULTY | " + difficulty, 17)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_color_override("font_color", Color("#f2ce7c"))
	content.add_child(difficulty_label)
	var moves := _make_label("MATCH THE GOAL | %d MOVES" % moves_total, 18)
	moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(moves)
	var play := _make_texture_button("play", Vector2(250, 112))
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_play_ui_confirm)
	play.pressed.connect(_begin_level.bind(route_id), CONNECT_ONE_SHOT)
	content.add_child(play)


func _get_primary_objective(level_data: Dictionary) -> Dictionary:
	var objectives = level_data.get("objectives", [])
	if typeof(objectives) == TYPE_ARRAY and not objectives.is_empty() and typeof(objectives[0]) == TYPE_DICTIONARY:
		return objectives[0]
	return {}


func _format_objective(objective: Dictionary) -> String:
	var target := str(objective.get("target", "evidence")).replace("_", " ").to_lower().capitalize()
	var amount := int(objective.get("amount", 1))
	if str(objective.get("type", "")).to_upper() == "DESTROY_OBSTACLES":
		return "Break %d obstacles" % amount
	return "Collect %d %s" % [amount, target]


func _format_hud_objective_summary(level_data: Dictionary) -> String:
	var summaries: Array[String] = []
	var objectives = level_data.get("objectives", [])
	if typeof(objectives) == TYPE_ARRAY:
		for objective_value in objectives:
			if typeof(objective_value) != TYPE_DICTIONARY:
				continue
			var objective: Dictionary = objective_value
			var amount := int(objective.get("amount", 1))
			if str(objective.get("type", "")).to_upper() == "DESTROY_OBSTACLES":
				summaries.append("CLEAR %d OBSTACLES" % amount)
			else:
				var target := str(objective.get("target", "CLUES")).replace("_", " ").to_upper()
				var plural := target + "S"
				if target == "KEY":
					plural = "KEYS"
				elif target == "PHONE":
					plural = "PHONES"
				summaries.append("COLLECT %d %s" % [amount, plural])
	if _obstacles_goal > 0 and _objective_type != "DESTROY_OBSTACLES":
		summaries.append("CLEAR %d BLOCKERS" % _obstacles_goal)
	if summaries.is_empty():
		return str(level_data.get("description", "COMPLETE THE INVESTIGATION")).to_upper()
	var summary := ""
	for entry in summaries:
		if not summary.is_empty():
			summary += "  |  "
		summary += entry
	return "OBJECTIVE: " + summary


func _objective_icon_path(target: String) -> String:
	var icons := {
		"KEY": "key_objective_icon.jpeg",
		"PHONE": "phone_evidence_icon.svg",
		"FINGERPRINT": "fingerprint_evidence_icon.jpeg",
		"RECORDER": "recorder_evidence_icon.jpeg",
		"CLOCK": "timer_objective_icon.jpeg"
	}
	var file_name := str(icons.get(target.to_upper(), "evidence_document_icon.jpeg"))
	return "res://assets/sprites/tiles/" + file_name


func _objective_hud_title() -> String:
	match _objective_target:
		"FINGERPRINT":
			return "PRINT"
		"RECORDER":
			return "REC"
		_:
			return _objective_target.replace("_", " ")


func _begin_level(_route_id: String) -> void:
	SignalBus.play_sfx.emit("door_close")
	var gameplay_hud := get_node_or_null("HUD") as CanvasLayer
	if gameplay_hud != null:
		gameplay_hud.visible = true
	if _campaign_layer != null and is_instance_valid(_campaign_layer):
		_campaign_layer.queue_free()
	_campaign_layer = null
	_campaign_map = null
	if _briefing_layer != null and is_instance_valid(_briefing_layer):
		_briefing_layer.queue_free()
	_briefing_layer = null
	if _story_manager != null:
		_story_manager.end_story()
	if _story_layer != null and is_instance_valid(_story_layer):
		_story_layer.queue_free()
	_story_layer = null
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	_booster_dock.visible = true
	_current_level_id = int(level_data.get("level_id", 1))
	_current_route_id = _route_id
	var objective := _get_primary_objective(level_data)
	_evidence_count = 0
	_objective_complete_sound_played = false
	_story_objective_sound_pending = false
	_evidence_goal = int(objective.get("amount", 10))
	var level_rewards: Dictionary = level_data.get("rewards", {})
	_star_reward_label.text = "★ %d" % int(level_rewards.get("stars", 3))
	_level_reward_label.text = "+%d" % int(level_rewards.get("coins", 0))
	var obstacle_items: Array = level_data.get("obstacles", {}).get("items", [])
	_objective_target = str(objective.get("target", "KEY")).to_upper()
	_objective_type = str(objective.get("type", "COLLECT_ITEMS")).to_upper()
	if _objective_target_icon != null:
		_objective_target_icon.texture = ResourceManager.load_texture(_objective_icon_path(_objective_target))
	if _objective_target_name != null:
		_objective_target_name.text = _objective_hud_title()
	_obstacles_goal = obstacle_items.size() if _objective_type != "DESTROY_OBSTACLES" else 0
	_obstacles_cleared = 0
	if _level_number_label != null:
		_level_number_label.text = "%02d" % _current_level_id
	if _objective_description_label != null:
		_objective_description_label.text = _format_hud_objective_summary(level_data)
	_update_objective_hud()
	_reward_label.text = str(_economy_manager.get_coins() if _economy_manager != null else int(_campaign_progress.get_value("campaign", "coins", 0)))
	for kind in ["rocket", "bomb", "thunder"]:
		_booster_inventory[kind] = _economy_manager.get_booster_count(kind) if _economy_manager != null else int(_campaign_progress.get_value("campaign", "boosters", {}).get(kind, 0))
	_booster_inventory["ethan"] = _economy_manager.get_ethan_count() if _economy_manager != null else int(_campaign_progress.get_value("campaign", "ethan", 0))
	_selected_booster = ""
	_tutorial_booster_kind = ""
	_tutorial_mechanic = ""
	_tutorial_target_cell = Vector2i(-1, -1)
	if _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	if _board != null:
		_board.cancel_booster_mode()
		_board.clear_required_swap()
	for kind in _booster_buttons:
		var entry: Dictionary = _booster_buttons[kind]
		(entry["count"] as Label).text = "%s\n%d" % [kind.to_upper(), int(_booster_inventory[kind])]
		(entry["button"] as BaseButton).disabled = false
	var tutorial: Dictionary = level_data.get("tutorial", {})
	var tutorial_steps: Array = tutorial.get("steps", [])
	if bool(tutorial.get("enabled", false)) and not tutorial_steps.is_empty():
		_tutorial_active = true
		_tutorial_action = "guided_swap"
		_tutorial_mechanic = str(tutorial_steps[0].get("mechanic", ""))
		_tutorial_pause_open = false
		_tutorial_booster_kind = str(tutorial_steps[0].get("booster", "")).to_lower()
		if not _tutorial_booster_kind.is_empty():
			_tutorial_action = "booster_select"
			_board.lock()
			_hint_label.text = "BOOSTER TRAINING | " + _tutorial_booster_kind.to_upper()
			_refresh_tutorial_controls()
			_show_tutorial_tip(
				_hint_label.text,
				_button_screen_rect(_booster_buttons[_tutorial_booster_kind]["button"]),
				"DAVID",
				"res://assets/sprites/characters/david_portrait_cutout.png"
			)
		else:
			var guided_swap: Array[Vector2i] = []
			var guided_move_hits_obstacle := false
			var tutorial_mechanic_unavailable := false
			if _board != null:
				if _tutorial_mechanic == "create_rocket":
					var objective_type := int(Constants.TileType.get(_objective_target, -1))
					guided_swap = _board.find_valid_swap_for_type(objective_type, 4)
					if guided_swap.is_empty():
						guided_swap = _board.find_valid_swap_for_type(-1, 4)
				elif _current_level_id == 1 and _objective_type == "COLLECT_ITEMS":
					guided_swap = _board.find_valid_swap_for_type(int(Constants.TileType.get(_objective_target, -1)))
				if guided_swap.is_empty() and not obstacle_items.is_empty() and _tutorial_mechanic == "damage_obstacle":
					guided_swap = _board.find_valid_swap_near_obstacle()
					guided_move_hits_obstacle = not guided_swap.is_empty()
				if _tutorial_mechanic == "damage_obstacle" and not guided_move_hits_obstacle:
					_tutorial_mechanic = ""
					tutorial_mechanic_unavailable = true
				if guided_swap.is_empty():
					guided_swap = _board.find_valid_swap()
					if _tutorial_mechanic == "create_rocket":
						_tutorial_mechanic = ""
						tutorial_mechanic_unavailable = true
			if _board != null:
				_board.set_required_swap(guided_swap)
			var base_message := str(tutorial_steps[0].get("message", "Swap the highlighted neighboring pieces to make a match."))
			if tutorial_mechanic_unavailable:
				if _current_level_id == 16:
					base_message = "This board has no safe four-piece setup yet. Make the glowing match; we will show you a rocket when one appears."
				else:
					base_message = "No safe match beside the obstacle is available yet. Follow the glow; nearby matches are what damage it."
			if _tutorial_mechanic == "damage_obstacle" and not guided_move_hits_obstacle:
				base_message = "Swipe the highlighted neighboring tiles to make a match."
			_hint_label.text = "DAVID'S FIELD COACHING | FOLLOW THE GLOW"
			if guided_swap.size() == 2:
				var first_rect := _board.get_cell_screen_rect(guided_swap[0])
				var second_rect := _board.get_cell_screen_rect(guided_swap[1])
				_show_tutorial_tip(base_message, first_rect.merge(second_rect), "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png")
	else:
		_tutorial_active = false
		_tutorial_action = ""
		var mission_hint := "MATCH %s | COLLECT %d CLUES IN %d MOVES" % [
			_objective_target.replace("_", " "), _evidence_goal, int(level_data.get("moves", {}).get("total", 0))
		]
		if _obstacles_goal > 0:
			mission_hint += " | CLEAR %d BLOCKERS" % _obstacles_goal
		_hint_label.text = mission_hint
	_refresh_tutorial_controls()
	if level_manager != null:
		level_manager.start_level()
	if _board != null:
		if not (_tutorial_active and _tutorial_action == "booster_select"):
			_board.unlock()
	var active_hud := get_node_or_null("HUD") as CanvasLayer
	if active_hud != null:
		active_hud.visible = true


func _on_board_created() -> void:
	var created_board: Board = _board_manager.get_board()
	if created_board == null or created_board == _board:
		return
	_board = created_board
	_board.moves_changed.connect(_on_moves_changed)
	_board.match_collected.connect(_on_tiles_matched)
	_board.move_rejected.connect(_on_move_rejected)
	_board.turn_resolved.connect(_on_board_turn_resolved)
	_board.special_created.connect(_on_special_created)
	_board.special_activated.connect(_on_special_activated)
	_board.booster_used.connect(_on_booster_used)
	_board.obstacles_cleared.connect(_on_obstacles_cleared)
	_board.obstacle_damaged.connect(_on_obstacle_damaged)
	_board.tiles_matched_with_cells.connect(_animate_matched_tiles)
	_board.lock()
	_on_moves_changed(_board.get_remaining_moves())


func _on_moves_changed(remaining: int) -> void:
	_moves_remaining = remaining
	_moves_label.text = str(remaining)


func _on_coins_changed(coins: int) -> void:
	if _reward_label != null:
		var from := _displayed_coins
		if _coin_count_tween != null and _coin_count_tween.is_running():
			_coin_count_tween.kill()
		_coin_count_tween = create_tween()
		_coin_count_tween.tween_method(_set_displayed_coin_count, from, coins, 0.55)
	_campaign_progress.set_value("campaign", "coins", coins)
	_persist_campaign_progress()


func _set_displayed_coin_count(value: int) -> void:
	_displayed_coins = value
	if _reward_label != null:
		_reward_label.text = str(value)


func _on_lives_changed(lives: int) -> void:
	if _lives_label != null:
		var game_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.GAME)
		var maximum_lives := int(game_config.get("max_lives", 5))
		_lives_label.text = "%d/%d" % [lives, maximum_lives]
	_campaign_progress.set_value("campaign", "lives", lives)
	_persist_campaign_progress()


func _on_ethan_changed(count: int) -> void:
	_booster_inventory["ethan"] = count
	if _booster_buttons.has("ethan"):
		var count_label := _booster_buttons["ethan"]["count"] as Label
		count_label.text = str(count)
		count_label.scale = Vector2(1.15, 1.15)
		var pop := create_tween()
		pop.tween_property(count_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_campaign_progress.set_value("campaign", "ethan", count)
	_persist_campaign_progress()


func _on_boosters_changed(boosters: Dictionary) -> void:
	for kind in ["rocket", "bomb", "thunder"]:
		_booster_inventory[kind] = int(boosters.get(kind, 0))
		if _booster_buttons.has(kind):
			var count_label := _booster_buttons[kind]["count"] as Label
			count_label.text = str(int(_booster_inventory[kind]))
			count_label.scale = Vector2(1.15, 1.15)
			var pop := create_tween()
			pop.tween_property(count_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_tutorial_controls()
	_save_inventory_progress()


func _save_inventory_progress() -> void:
	var saved: Dictionary = {}
	for kind in ["rocket", "bomb", "thunder"]:
		saved[kind] = _economy_manager.get_booster_count(kind) if _economy_manager != null else int(_booster_inventory.get(kind, 0))
	_campaign_progress.set_value("campaign", "boosters", saved)
	if _economy_manager != null:
		_campaign_progress.set_value("campaign", "ethan", _economy_manager.get_ethan_count())
	_persist_campaign_progress()


func _open_booster_shop(kind: String) -> void:
	if _economy_manager == null:
		return
	var item_id := "ethan_assist" if kind == "ethan" else "%s_booster" % kind
	var item: Dictionary = _economy_manager.get_shop_item(item_id)
	if item.is_empty():
		return
	var amount := int(item.get("amount", 1))
	var cost := int(item.get("price", 0))
	var dialog := ConfirmationDialog.new()
	dialog.title = "FIELD SUPPLIES"
	dialog.dialog_text = "Buy %s for %d Ethan Coins? You have %d." % [str(item.get("name", kind.capitalize())), cost, _economy_manager.get_coins()]
	dialog.ok_button_text = "BUY"
	var layer := CanvasLayer.new()
	layer.layer = 24
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	layer.add_child(dialog)
	dialog.confirmed.connect(func():
		var purchase := Purchase.new()
		purchase.initialize()
		purchase.set_item(item_id)
		purchase.set_currency(str(item.get("currency", "coins")))
		purchase.set_price(cost)
		if _economy_manager.purchase(purchase):
			if kind == "ethan":
				_economy_manager.add_ethan(amount)
			else:
				_economy_manager.add_booster(kind, amount)
				_booster_inventory[kind] = _economy_manager.get_booster_count(kind)
				var entry: Dictionary = _booster_buttons.get(kind, {})
				if not entry.is_empty():
					(entry["count"] as Label).text = str(int(_booster_inventory[kind]))
			_save_inventory_progress()
		else:
			_show_shop_notice("You need %d Ethan Coins for this supply." % cost)
	)
	dialog.confirmed.connect(layer.queue_free, CONNECT_ONE_SHOT)
	dialog.canceled.connect(layer.queue_free, CONNECT_ONE_SHOT)
	dialog.popup_centered()


func _update_objective_hud() -> void:
	if _objective_label == null:
		return
	_objective_label.text = "%d / %d" % [mini(_evidence_count, _evidence_goal), _evidence_goal]
	_blocker_label.text = "BLOCKERS %d / %d" % [_obstacles_cleared, _obstacles_goal] if _obstacles_goal > 0 else ""


func _mission_objectives_complete() -> bool:
	return _evidence_count >= _evidence_goal and _obstacles_cleared >= _obstacles_goal


func _animate_matched_tiles(tile_types: Array, cells: Array) -> void:
	var target_enum := int(Constants.TileType.get(_objective_target, -1))
	for index in range(mini(tile_types.size(), cells.size())):
		var tile_type := int(tile_types[index])
		var character_types: Array = [int(Constants.TileType.ETHAN), int(Constants.TileType.DETECTIVE), int(Constants.TileType.VICTOR)]
		if tile_type != target_enum and not character_types.has(tile_type):
			continue
		var cell: Vector2i = cells[index]
		var source := _board.get_cell_screen_rect(cell)
		var panel := _objective_label.get_parent() as Control
		var target := panel.get_node_or_null("ObjectiveIcon") as Control
		if [int(Constants.TileType.ETHAN), int(Constants.TileType.DETECTIVE)].has(tile_type) and _booster_buttons.has("ethan"):
			target = _booster_buttons["ethan"]["button"] as Control
		elif tile_type == int(Constants.TileType.VICTOR):
			# Victor matches grant coins directly; don't fly an oversized coin graphic
			# across the board. The counter updates independently via coins_changed.
			continue
		if target == null:
			target = _objective_label
		var token := TextureRect.new()
		var icon_path := _objective_icon_path(_objective_target) if tile_type == target_enum else "res://assets/sprites/characters/ethan_portrait_cutout.png"
		if tile_type == int(Constants.TileType.DETECTIVE):
			icon_path = "res://assets/sprites/characters/detective_portrait_cutout.png"
		elif tile_type == int(Constants.TileType.VICTOR):
			icon_path = "res://assets/sprites/characters/victor_portrait_badge_cutout.png"
		token.texture = ResourceManager.load_texture(icon_path)
		token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		token.size = Vector2(30, 30)
		token.position = source.get_center() - token.size * 0.5
		get_node("HUD").add_child(token)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(token, "position", target.get_global_rect().get_center() - token.size * 0.5, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(token, "scale", Vector2(0.55, 0.55), 0.38)
		tween.tween_property(token, "modulate:a", 0.25, 0.38)
		tween.finished.connect(token.queue_free)


func _persist_campaign_progress() -> void:
	_campaign_progress.set_value("campaign", "highest_unlocked_level", _highest_unlocked_level)
	_campaign_progress.set_value("campaign", "completed_levels", _completed_levels)
	var error := _campaign_progress.save(CAMPAIGN_PROGRESS_PATH)
	if error != OK:
		push_error("Could not save campaign progress: %s" % error_string(error))


func _on_tiles_matched(tile_types: Array) -> void:
	_match_streak += 1
	var objective_match := false
	var feedback_caption := ""
	var feedback_sound := ""
	var shake_board := false
	var special_reward_text := ""
	var target_enum := int(Constants.TileType.get(_objective_target, -1))
	for tile_type in tile_types:
		if _objective_type == "COLLECT_ITEMS" and int(tile_type) == target_enum:
			_evidence_count += 1
			objective_match = true
		if int(tile_type) == int(Constants.TileType.ETHAN) and _economy_manager != null:
			_economy_manager.add_ethan(1)
			special_reward_text = "ETHAN FOUND | +1 RESCUE ASSIST"
		elif int(tile_type) == int(Constants.TileType.DETECTIVE) and _economy_manager != null:
			_economy_manager.add_ethan(1)
			special_reward_text = "DETECTIVE FOUND | +1 RESCUE ASSIST"
		elif int(tile_type) == int(Constants.TileType.VICTOR) and _economy_manager != null:
			_economy_manager.add_coins(10)
			special_reward_text = "VICTOR CAUGHT | +10 ETHAN COINS"
		if [int(Constants.TileType.ETHAN), int(Constants.TileType.DETECTIVE), int(Constants.TileType.VICTOR)].has(int(tile_type)):
			objective_match = true
	SignalBus.play_sfx.emit("clue_collected" if objective_match else "tile_match")
	if tile_types.size() >= 5 or _match_streak >= 4:
		feedback_caption = "WONDERFUL!"
		feedback_sound = "match_wonderful"
		shake_board = true
	elif tile_types.size() >= 4 or _match_streak >= 3:
		feedback_caption = "GREAT!"
		feedback_sound = "match_great"
	elif _match_streak >= 2:
		feedback_caption = "NICE!"
		feedback_sound = "match_nice"
	_evidence_count = mini(_evidence_count, _evidence_goal)
	_update_objective_hud()
	if _mission_objectives_complete():
		_hint_label.text = "GOAL REACHED | Wrapping up the investigation..."
		_play_objective_complete_sound()
	elif not special_reward_text.is_empty() and not _tutorial_active:
		_hint_label.text = special_reward_text
	elif not _tutorial_active:
		_hint_label.text = "CLUES | %d of %d %s collected" % [_evidence_count, _evidence_goal, _objective_target.replace("_", " ").to_lower()]
	if not feedback_caption.is_empty():
		_show_match_feedback(feedback_caption, feedback_sound, shake_board)


func _on_move_rejected() -> void:
	SignalBus.play_sfx.emit("invalid_move")
	_hint_label.text = "NO MATCH | Swap neighboring pieces to make a set of 3."


func _show_match_feedback(caption: String, sound_id: String, shake_board: bool) -> void:
	SignalBus.play_sfx.emit(sound_id)
	_hint_label.text = caption
	_hint_label.add_theme_color_override("font_color", Color("#ffe279"))
	var feedback_layer := CanvasLayer.new()
	feedback_layer.name = "MatchFeedback"
	feedback_layer.layer = 3
	add_child(feedback_layer)
	var shout := Label.new()
	shout.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	shout.position = Vector2(-250.0, -55.0)
	shout.size = Vector2(500.0, 110.0)
	shout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shout.text = caption
	shout.add_theme_font_override("font", DISPLAY_FONT)
	shout.add_theme_font_size_override("font_size", 40)
	shout.add_theme_color_override("font_color", Color("#ffe278"))
	shout.add_theme_color_override("font_outline_color", Color("#39213f"))
	shout.add_theme_constant_override("outline_size", 7)
	shout.add_theme_color_override("font_shadow_color", Color(0.04, 0.04, 0.1, 0.85))
	shout.add_theme_constant_override("shadow_offset_x", 4)
	shout.add_theme_constant_override("shadow_offset_y", 6)
	feedback_layer.add_child(shout)
	shout.scale = Vector2(0.4, 0.4)
	shout.modulate.a = 0.0
	var pop := create_tween().set_parallel(true)
	pop.tween_property(shout, "modulate:a", 1.0, 0.1)
	pop.tween_property(shout, "scale", Vector2(1.12, 1.12), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.chain().tween_property(shout, "scale", Vector2.ONE, 0.1)
	pop.finished.connect(
		func():
			if not is_instance_valid(feedback_layer):
				return
			var fade := create_tween()
			fade.tween_interval(0.55)
			fade.tween_property(shout, "modulate:a", 0.0, 0.2)
			fade.tween_callback(feedback_layer.queue_free)
	)
	if shake_board and _board != null:
		_board.play_celebration_shake(1.0)


func _on_special_created(kind: String) -> void:
	SignalBus.play_sfx.emit("special_created")
	_special_moves_created += 1
	var rewards: Array = []
	if _reward_manager != null:
		rewards = _reward_manager.grant_special_move(kind, _special_moves_created)
	var coin_reward := 0
	var earned_booster := false
	var milestone := _reward_manager.get_special_move_milestone() if _reward_manager != null else 0
	for reward in rewards:
		if int(reward.get("type", -1)) == int(Constants.RewardType.COINS):
			coin_reward += int(reward.get("amount", 0))
		elif int(reward.get("type", -1)) == int(Constants.RewardType.BOOSTER):
			earned_booster = true
	if _reward_manager == null and _economy_manager != null:
		var reward_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.REWARDS).get("special_move", {})
		coin_reward = maxi(0, int(reward_config.get("coins_per_creation", 0)))
		_economy_manager.add_coins(coin_reward)
		milestone = maxi(0, int(reward_config.get("booster_every", 0)))
		earned_booster = milestone > 0 and _special_moves_created % milestone == 0
		if earned_booster:
			_economy_manager.add_booster(kind, maxi(1, int(reward_config.get("milestone_booster_amount", 1))))
	_campaign_progress.set_value("campaign", "special_moves_created", _special_moves_created)
	_persist_campaign_progress()
	var supply_progress := _special_moves_created % milestone if milestone > 0 else 0
	var reward_note := ""
	if earned_booster:
		reward_note = " | AMARA SUPPLY: +1 %s" % kind.to_upper()
	elif milestone > 0:
		reward_note = " | SUPPLY %d / %d" % [supply_progress, milestone]
	_hint_label.text = "SPECIAL MOVE | +%d COINS%s" % [coin_reward, reward_note]
	_hint_label.add_theme_color_override("font_color", Color("#8df4ff"))
	_hint_label.scale = Vector2(0.75, 0.75)
	var pop := create_tween()
	pop.tween_property(_hint_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_special_activated(kind: String) -> void:
	if _board != null:
		_board.play_celebration_shake(1.5 if kind == "thunder" else 0.8)


func _on_board_turn_resolved() -> void:
	_match_streak = 0
	if _result_layer != null:
		return
	var tutorial_result_pending := _tutorial_active and ["guided_swap", "booster_resolving", "activate_special"].has(_tutorial_action)
	if (_mission_objectives_complete() or _moves_remaining <= 0) and not tutorial_result_pending:
		_evaluate_level_end()
		return
	if _tutorial_active:
		if _tutorial_action == "guided_swap":
			if _tutorial_mechanic == "create_rocket":
				_show_tutorial_special_created()
			elif _tutorial_mechanic == "damage_obstacle":
				_show_tutorial_obstacle_result()
			elif _current_level_id == 1:
				_show_tutorial_goal_feedback()
			else:
				_finish_tutorial()
		elif _tutorial_action == "booster_resolving":
			_show_tutorial_booster_result()
		elif _tutorial_action == "activate_special":
			_show_tutorial_special_result()
	if not tutorial_result_pending:
		_evaluate_level_end()


func _show_tutorial_goal_feedback() -> void:
	_tutorial_action = "explain_goal"
	if _board != null:
		_board.lock()
	var hud_target := _moves_label.get_global_rect().merge(_objective_label.get_global_rect())
	var message := "That match used one move and refilled the board. MOVES shows %d turns left; GOAL tracks %d of %d keys. Other symbols clear space but do not add key evidence."
	_show_tutorial_tip(
		message % [_moves_remaining, _evidence_count, _evidence_goal],
		hud_target,
		"DAVID",
		"res://assets/sprites/characters/david_portrait_cutout.png",
		true
	)
	_refresh_tutorial_controls()


func _show_tutorial_obstacle_result() -> void:
	_tutorial_action = "explain_obstacle"
	if _board != null:
		_board.lock()
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	var obstacles: Array = level_data.get("obstacles", {}).get("items", [])
	var target_rect := _objective_label.get_global_rect()
	var message := "That match damaged the marked obstacle. Match beside each layer until it breaks; only the clue shown on the goal card advances the evidence count."
	if not obstacles.is_empty():
		var obstacle: Dictionary = obstacles[0]
		var cell := Vector2i(int(obstacle.get("x", -1)), int(obstacle.get("y", -1)))
		target_rect = _board.get_cell_screen_rect(cell)
		var obstacle_name := str(obstacle.get("type", "obstacle")).replace("_", " ").to_upper()
		message = "You hit the %s. Matches beside it remove one health layer; clear it completely to finish the BLOCKERS mission. Watch its health fly up after each hit." % obstacle_name
	_tutorial_action = "explain_obstacle"
	_show_tutorial_tip(message, target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png", true)


func _show_tutorial_special_created() -> void:
	var special_cell := _board.find_powerup_cell() if _board != null else Vector2i(-1, -1)
	if special_cell.x < 0:
		_finish_tutorial()
		return
	var neighbor := special_cell + Vector2i.RIGHT
	if not _board.is_inside(neighbor):
		neighbor = special_cell + Vector2i.LEFT
	if not _board.is_inside(neighbor):
		neighbor = special_cell + Vector2i.DOWN
	if not _board.is_inside(neighbor):
		neighbor = special_cell + Vector2i.UP
	if not _board.is_inside(neighbor):
		_finish_tutorial()
		return
	_tutorial_action = "activate_special"
	_board.set_required_swap([special_cell, neighbor])
	_board.unlock()
	var target_rect := _board.get_cell_screen_rect(special_cell).merge(_board.get_cell_screen_rect(neighbor))
	_show_tutorial_tip("Four in a line made a rocket. Swap it with the glowing neighbor to fire its row and column. Special pieces activate through a swap.", target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png")


func _show_tutorial_special_result() -> void:
	_tutorial_action = "explain_special_result"
	if _board != null:
		_board.lock()
	_show_tutorial_tip("The rocket cleared its row and column in one move. Creating special pieces also earns Ethan Coins; Amara sends a matching booster after the configured milestone. Use specials to clear a blocked path or reach mission evidence.", _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png", true)


func _show_tutorial_booster_result() -> void:
	_tutorial_action = "explain_booster_result"
	if _board != null:
		_board.lock()
	var consequence := "The rocket clears its row and column."
	match _tutorial_booster_kind:
		"bomb": consequence = "The bomb clears pieces around the target."
		"thunder": consequence = "Thunder clears every piece of the chosen type."
	_show_tutorial_tip("%s The booster count dropped by one; boosters are limited. Save the next one for a useful obstacle or hard-to-reach clue." % consequence, _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png", true)


func _on_tutorial_acknowledged() -> void:
	if _tutorial_action == "campaign_map_intro":
		_tutorial_action = ""
		if _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()
		return
	if not _tutorial_active:
		return
	if _tutorial_action == "explain_goal":
		_tutorial_action = "pause"
		if _board != null:
			_board.lock()
		_refresh_tutorial_controls()
		_show_tutorial_tip(
			"Tap the gear to adjust music and sound effects separately. You can change them again whenever you need.",
		_button_screen_rect(_pause_button),
			"DAVID",
			"res://assets/sprites/characters/david_portrait_cutout.png"
		)
	elif _tutorial_action == "explain_obstacle":
		_finish_tutorial()
	elif _tutorial_action == "explain_special_created":
		_show_tutorial_special_created()
	elif _tutorial_action == "explain_special_result" or _tutorial_action == "explain_booster_result":
		_finish_tutorial()


func _finish_tutorial() -> void:
	_tutorial_active = false
	_tutorial_action = ""
	_tutorial_pause_open = false
	_tutorial_booster_kind = ""
	_tutorial_mechanic = ""
	_tutorial_target_cell = Vector2i(-1, -1)
	if _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	_hint_label.text = "FIELD BRIEFING COMPLETE | Follow the goal card, David."
	_refresh_tutorial_controls()
	if _board != null:
		_board.clear_required_swap()
		_board.unlock()
	call_deferred("_evaluate_level_end")


func _refresh_tutorial_controls() -> void:
	if _pause_button != null:
		_pause_button.disabled = _tutorial_active and _tutorial_action != "pause"
	if _case_file_button != null:
		_case_file_button.disabled = _tutorial_active and _tutorial_action != "field_guide"
	for kind in _booster_buttons:
		var entry: Dictionary = _booster_buttons[kind]
		var button := entry["button"] as BaseButton
		button.visible = true
		var tutorial_allows: bool = not _tutorial_active or (_tutorial_action == "booster_select" and kind == _tutorial_booster_kind)
		button.disabled = not tutorial_allows


func _on_booster_pressed(kind: String) -> void:
	if _tutorial_active and not (_tutorial_action == "booster_select" and kind == _tutorial_booster_kind):
		return
	if _board == null:
		return
	if int(_booster_inventory.get(kind, 0)) <= 0:
		_open_booster_shop(kind)
		return
	if _selected_booster == kind:
		_cancel_booster_targeting()
		return
	_selected_booster = kind
	if _tutorial_active:
		_tutorial_action = "booster_target"
		_tutorial_target_cell = Vector2i(_board.get_width() / 2, _board.get_height() / 2)
		_board.set_required_booster_target(_tutorial_target_cell)
		_board.set_booster_mode(kind)
		_board.unlock()
		var target_rect := _board.get_cell_screen_rect(_tutorial_target_cell)
		var message := "Tap the glowing piece to use %s. This clears nearby evidence." % kind.capitalize()
		_hint_label.text = "BOOSTER TRAINING | TARGET THE GLOWING PIECE"
		_show_tutorial_tip(message, target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png")
		_refresh_tutorial_controls()
		return
	_show_booster_confirmation(kind)


func _show_booster_confirmation(kind: String) -> void:
	var descriptions := {
		"rocket": "Choose a tile. Rocket clears its full row and column.",
		"bomb": "Choose a tile. Bomb clears the tiles around it.",
		"thunder": "Choose a tile. Thunder clears every tile of that type.",
		"ethan": "Choose a tile. Ethan clears a 5 by 5 rescue area."
	}
	var dialog := ConfirmationDialog.new()
	dialog.name = "BoosterUseConfirmation"
	dialog.title = "%s | %d available" % [kind.capitalize(), int(_booster_inventory.get(kind, 0))]
	dialog.dialog_text = "%s\n\nUse one now? After you choose Use, tap a tile on the board to set the target." % descriptions.get(kind, "Choose a board tile to use this booster.")
	dialog.size = Vector2i(380, 230)
	dialog.get_ok_button().text = "USE BOOSTER"
	dialog.get_cancel_button().text = "CANCEL"
	dialog.get_ok_button().custom_minimum_size = Vector2(160, 48)
	dialog.get_cancel_button().custom_minimum_size = Vector2(140, 48)
	dialog.get_ok_button().add_theme_font_size_override("font_size", 20)
	dialog.get_cancel_button().add_theme_font_size_override("font_size", 20)
	for dialog_label in dialog.find_children("*", "Label", true, false):
		dialog_label.add_theme_font_override("font", DISPLAY_FONT)
		dialog_label.add_theme_font_size_override("font_size", 22)
	dialog.confirmed.connect(_confirm_booster_use.bind(kind))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(_cancel_booster_dialog)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	_booster_confirm = dialog
	_booster_confirm.popup_centered(Vector2i(380, 230))


func _confirm_booster_use(kind: String) -> void:
	_booster_confirm = null
	_selected_booster = kind
	_board.unlock()
	_board.set_booster_mode(kind)
	_hint_label.text = "TAP A TILE TO USE %s  |  TAP THE BOOSTER AGAIN TO CANCEL" % kind.to_upper()


func _cancel_booster_dialog() -> void:
	_booster_confirm = null
	_selected_booster = ""


func _cancel_booster_targeting() -> void:
	if _board != null:
		_board.cancel_booster_mode()
		_board.lock()
	_selected_booster = ""
	_hint_label.text = "BOOSTER CANCELLED | No item was used."


func _on_booster_used(kind: String) -> void:
	_selected_booster = ""
	_hint_label.text = "%s USED" % kind.to_upper()
	_booster_inventory[kind] = maxi(0, int(_booster_inventory.get(kind, 0)) - 1)
	if _economy_manager != null:
		if kind == "ethan":
			_economy_manager.use_ethan()
		else:
			_economy_manager.use_booster(kind)
	_save_inventory_progress()
	var entry: Dictionary = _booster_buttons.get(kind, {})
	if not entry.is_empty():
		(entry["count"] as Label).text = str(int(_booster_inventory[kind]))
	_refresh_tutorial_controls()
	if _tutorial_active and _tutorial_action == "booster_target":
		_tutorial_action = "booster_resolving"
		if _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()


func _show_tutorial_tip(message: String, target_rect: Rect2, speaker: String = "DAVID", portrait_path: String = "", needs_acknowledgement: bool = false) -> void:
	if target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
		return
	if _tutorial_overlay == null or not is_instance_valid(_tutorial_overlay):
		var layer := CanvasLayer.new()
		layer.name = "GuidedTutorial"
		layer.layer = 18
		add_child(layer)
		_tutorial_overlay = TutorialOverlay.new()
		_tutorial_overlay.acknowledged.connect(_on_tutorial_acknowledged)
		layer.add_child(_tutorial_overlay)
	var board_action := ["guided_swap", "activate_special", "booster_target"].has(_tutorial_action)
	var tap_action := board_action or ["campaign_map_intro", "settings", "pause", "field_guide"].has(_tutorial_action)
	_tutorial_overlay.show_tip(message, target_rect, speaker, portrait_path, needs_acknowledgement, board_action, tap_action)


func _button_screen_rect(button: Control) -> Rect2:
	return button.get_global_rect()


func _on_obstacles_cleared(amount: int) -> void:
	if _objective_type == "DESTROY_OBSTACLES":
		_evidence_count = mini(_evidence_goal, _evidence_count + amount)
	else:
		_obstacles_cleared = mini(_obstacles_goal, _obstacles_cleared + amount)
	_update_objective_hud()
	if _mission_objectives_complete():
		_hint_label.text = "ALL GOALS REACHED | Wrapping up the investigation..."
		_play_objective_complete_sound()


func _on_obstacle_damaged(cell: Vector2i, remaining_health: int, destroyed: bool) -> void:
	if _board == null:
		return
	var rect := _board.get_cell_screen_rect(cell)
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null or rect.size == Vector2.ZERO:
		return
	var center := rect.get_center()
	var particles := CPUParticles2D.new()
	particles.position = center
	particles.amount = 18
	particles.lifetime = 0.48
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 9.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 48.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 70)
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color = Color("#ffe279")
	hud.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
	var burst := Label.new()
	burst.text = "✦  ✦  ✦"
	burst.position = center - Vector2(42, 16)
	burst.size = Vector2(84, 32)
	burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst.add_theme_font_size_override("font_size", 22)
	burst.add_theme_color_override("font_color", Color("#ffe279"))
	hud.add_child(burst)
	var pop := create_tween().set_parallel(true)
	pop.tween_property(burst, "position", burst.position - Vector2(0, 30), 0.42)
	pop.tween_property(burst, "modulate:a", 0.0, 0.42)
	pop.finished.connect(burst.queue_free)
	var health := Label.new()
	health.text = "BROKEN!" if destroyed else "%d LEFT" % remaining_health
	health.position = center - Vector2(48, 2)
	health.size = Vector2(96, 28)
	health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health.add_theme_font_size_override("font_size", 16)
	health.add_theme_color_override("font_color", Color("#fff2c7"))
	health.add_theme_color_override("font_outline_color", Color("#182c43"))
	health.add_theme_constant_override("outline_size", 3)
	hud.add_child(health)
	var fly := create_tween().set_parallel(true)
	fly.tween_property(health, "position", health.position - Vector2(0, 38), 0.55)
	fly.tween_property(health, "modulate:a", 0.0, 0.55)
	fly.finished.connect(health.queue_free)


func _play_objective_complete_sound() -> void:
	if _objective_complete_sound_played:
		return
	_objective_complete_sound_played = true
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	_story_objective_sound_pending = _is_story_final_level(level_data)


func _evaluate_level_end() -> void:
	if _result_layer != null or _current_level_id <= 0:
		return
	if _mission_objectives_complete():
		var level_manager := get_node_or_null("Managers/LevelManager")
		if level_manager != null:
			level_manager.complete_level()
		_show_level_result(true)
	elif _moves_remaining <= 0:
		var level_manager := get_node_or_null("Managers/LevelManager")
		if level_manager != null:
			level_manager.fail_level()
		if _economy_manager != null:
			_economy_manager.lose_life(1)
		_show_level_result(false)


func _show_level_result(won: bool) -> void:
	if _board != null:
		_board.lock()
	_tutorial_active = false
	_tutorial_action = ""
	var first_clear := false
	if won:
		first_clear = _record_level_completion()
	_result_layer = CanvasLayer.new()
	_result_layer.name = "LevelResult"
	_result_layer.layer = 22
	_result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_result_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.025, 0.05, 0.82)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(minf(500.0, get_viewport_rect().size.x * 0.88), 380)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#10263d")
	card_style.border_color = Color("#e2bf72")
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(26)
	card_style.set_content_margin_all(28)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	card.scale = Vector2(0.72, 0.72)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	card.add_child(content)
	var heading := _make_label("MISSION COMPLETED!" if won else "THE TRAIL WENT COLD", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var result_manager := get_node_or_null("Managers/LevelManager")
	var result_data: Dictionary = result_manager.get_level_data() if result_manager != null else {}
	if won and _is_story_final_level(result_data):
		var story_complete := _make_label("STORY OBJECTIVE COMPLETE!", 22)
		story_complete.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story_complete.add_theme_color_override("font_color", Color("#ffe279"))
		content.add_child(story_complete)
	var reward_info: Dictionary = result_data.get("rewards", {})
	var detail_text: String
	if not won:
		detail_text = "The remaining moves ran out. You lost one life. Try again or visit the Life Shop."
	elif first_clear:
		detail_text = "Case %03d unlocked. +%d Ethan Coins and %d stars added." % [mini(_highest_unlocked_level, _current_level_id + 1), int(reward_info.get("coins", 0)), maxi(1, int(reward_info.get("stars", 3)))]
	else:
		detail_text = "Case %03d unlocked. First-clear rewards were already collected." % mini(_highest_unlocked_level, _current_level_id + 1)
	if won and _is_story_final_level(result_data):
		detail_text = "Story objective achieved. " + detail_text
		if first_clear:
			detail_text += " A chapter booster was added to your field kit."
	var detail := _make_label(detail_text, 19)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(detail)
	if won:
		var next := _make_menu_button("NEXT LEVEL")
		next.pressed.connect(_next_level_after_win)
		content.add_child(next)
	else:
		if _economy_manager == null or _economy_manager.get_lives() > 0:
			var retry := _make_menu_button("RETRY LEVEL")
			retry.pressed.connect(_retry_current_level)
			content.add_child(retry)
		var life_shop := _make_menu_button("LIFE SHOP")
		life_shop.pressed.connect(_show_life_shop)
		content.add_child(life_shop)
	var map_button := _make_menu_button("CAMPAIGN MAP")
	map_button.pressed.connect(_return_to_campaign_map)
	content.add_child(map_button)
	card.modulate.a = 0.0
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(card, "modulate:a", 1.0, 0.3)
	entrance.tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if won:
		SignalBus.play_sfx.emit("level_victory")
		if _story_objective_sound_pending:
			_story_objective_sound_pending = false
			_play_story_objective_sound_after_mission()
	else:
		SignalBus.play_sfx.emit("level_failure")


func _play_story_objective_sound_after_mission() -> void:
	await get_tree().create_timer(2.0).timeout
	if _result_layer != null and is_instance_valid(_result_layer):
		SignalBus.play_sfx.emit("objective_achieved")


func _show_life_shop() -> void:
	if _economy_manager == null:
		return
	var item: Dictionary = _economy_manager.get_shop_item("life_refill")
	var price := int(item.get("price", 300))
	var amount := int(item.get("amount", 5))
	var game_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.GAME)
	var maximum_lives := int(game_config.get("max_lives", 5))
	if _economy_manager.get_lives() >= maximum_lives:
		_show_shop_notice("Your life meter is already full.")
		return
	var purchase_dialog := ConfirmationDialog.new()
	purchase_dialog.title = "LIFE SHOP"
	purchase_dialog.dialog_text = "Refill %d lives for %d Ethan Coins? You have %d." % [amount, price, _economy_manager.get_coins()]
	purchase_dialog.ok_button_text = "BUY LIVES"
	var shop_layer := CanvasLayer.new()
	shop_layer.layer = 24
	shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_layer)
	shop_layer.add_child(purchase_dialog)
	purchase_dialog.confirmed.connect(func():
		var purchase := Purchase.new()
		purchase.initialize()
		purchase.set_item("life_refill")
		purchase.set_currency(str(item.get("currency", "coins")))
		purchase.set_price(price)
		if _economy_manager.purchase(purchase):
			_economy_manager.add_life(amount)
			var result_was_open := _result_layer != null
			if result_was_open:
				_dismiss_level_result()
				get_tree().paused = false
				_show_campaign_map(_current_route_id)
				_show_shop_notice("Lives restored. Choose a case from the campaign map.")
		else:
			_show_shop_notice("You need %d Ethan Coins for this refill." % price)
	)
	purchase_dialog.confirmed.connect(shop_layer.queue_free, CONNECT_ONE_SHOT)
	purchase_dialog.canceled.connect(shop_layer.queue_free, CONNECT_ONE_SHOT)
	purchase_dialog.popup_centered()


func _show_shop_notice(message: String) -> void:
	var notice := AcceptDialog.new()
	notice.title = "ETHAN COINS"
	notice.dialog_text = message
	var notice_layer := CanvasLayer.new()
	notice_layer.layer = 25
	notice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(notice_layer)
	notice_layer.add_child(notice)
	notice.confirmed.connect(notice_layer.queue_free)
	notice.canceled.connect(notice_layer.queue_free)
	notice.popup_centered()


func _is_story_final_level(level_data: Dictionary) -> bool:
	var metadata: Dictionary = level_data.get("metadata", {})
	return int(metadata.get("chapter_end_level", 0)) == int(level_data.get("level_id", -1))


func _dismiss_level_result() -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
	_result_layer = null


func _next_level_after_win() -> void:
	var next_id := _current_level_id + 1
	var path := "res://levels/level%03d.json" % next_id
	_dismiss_level_result()
	get_tree().paused = false
	if JsonLoader.file_exists(path):
		_on_campaign_level_selected(next_id, _current_route_id)
	else:
		_show_campaign_map(_current_route_id)


func _retry_current_level() -> void:
	var level_id := _current_level_id
	_dismiss_level_result()
	get_tree().paused = false
	_on_campaign_level_selected(level_id, _current_route_id)


func _return_to_campaign_map() -> void:
	_dismiss_level_result()
	get_tree().paused = false
	_show_campaign_map(_current_route_id)


func _load_campaign_progress() -> void:
	var error := _campaign_progress.load(CAMPAIGN_PROGRESS_PATH)
	if error != OK:
		_highest_unlocked_level = 1
		_completed_levels.clear()
		return
	_highest_unlocked_level = maxi(1, int(_campaign_progress.get_value("campaign", "highest_unlocked_level", 1)))
	var completed: Variant = _campaign_progress.get_value("campaign", "completed_levels", {})
	_completed_levels = completed if typeof(completed) == TYPE_DICTIONARY else {}


func _record_level_completion() -> bool:
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	var rewards: Dictionary = level_data.get("rewards", {})
	var stars_earned := maxi(1, int(rewards.get("stars", 3)))
	var old_stars := int(_completed_levels.get(str(_current_level_id), 0))
	_completed_levels[str(_current_level_id)] = maxi(stars_earned, old_stars)
	_highest_unlocked_level = maxi(_highest_unlocked_level, _current_level_id + 1)
	if old_stars == 0:
		if _reward_manager != null:
			_reward_manager.calculate_level_rewards({"level": _current_level_id})
			_reward_manager.claim_rewards()
		elif _economy_manager != null:
			_economy_manager.add_coins(int(rewards.get("coins", 0)))
			_economy_manager.add_stars(stars_earned)
		_campaign_progress.set_value("campaign", "total_stars", int(_campaign_progress.get_value("campaign", "total_stars", 0)) + stars_earned)
	_persist_campaign_progress()
	return old_stars == 0
