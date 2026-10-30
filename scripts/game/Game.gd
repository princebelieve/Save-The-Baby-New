extends Node2D
class_name Game

const OPENING_STORY_PATH := "res://stories/opening_story.json"
const CAMPAIGN_PROGRESS_PATH := "user://campaign_progress.cfg"

var _board_manager: Node
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
var _reward_label: Label
var _hint_label: Label
var _pause_button: TextureButton
var _settings_button: TextureButton
var _case_file_button: Button
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
var _selected_booster := ""
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


func _ready() -> void:
	_load_campaign_progress()
	_board_manager = get_node_or_null("Managers/BoardManager")
	if _board_manager != null:
		if not _board_manager.board_created.is_connected(_on_board_created):
			_board_manager.board_created.connect(_on_board_created)
		# Child managers can load Level 001 before this parent node enters _ready.
		# Hook that already-created board as well as future board_created signals.
		if _board_manager.get_board() != null:
			_on_board_created()
	_build_gameplay_hud()
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
	tint.color = Color(0.015, 0.045, 0.055, 0.68)
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
	var top_bar := ColorRect.new()
	top_bar.name = "MissionTopBar"
	top_bar.color = Color(0.012, 0.035, 0.055, 0.82)
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.155
	hud.add_child(top_bar)

	var header := HBoxContainer.new()
	header.name = "MissionHeader"
	header.anchor_left = 0.04
	header.anchor_right = 0.96
	header.anchor_top = 0.025
	header.anchor_bottom = 0.112
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 10)
	hud.add_child(header)
	_moves_label = _make_hud_panel(header, "moves_panel.png", "MOVES\n30", Vector2(102, 66))
	_objective_label = _make_hud_panel(header, "score_panel.png", "GOAL\n0 / 10", Vector2(140, 66))
	_reward_label = _make_hud_panel(header, "score_panel.png", "REWARD\n0 COINS", Vector2(100, 66))
	_pause_button = _make_texture_button("pause", Vector2(84, 36))
	_pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pause_button.pressed.connect(_show_pause_menu)
	header.add_child(_pause_button)
	_settings_button = _make_texture_button("settings", Vector2(84, 36))
	_settings_button.name = "GameplaySettingsButton"
	_settings_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_settings_button.pressed.connect(_show_gameplay_audio_settings)
	header.add_child(_settings_button)
	_case_file_button = Button.new()
	_case_file_button.name = "CaseFileButton"
	_case_file_button.text = "CASE\nFILE"
	_case_file_button.custom_minimum_size = Vector2(70, 54)
	_case_file_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_case_file_button.add_theme_font_size_override("font_size", 12)
	_case_file_button.add_theme_color_override("font_color", Color("#fff3d5"))
	var case_file_style := StyleBoxFlat.new()
	case_file_style.bg_color = Color("#21466a")
	case_file_style.border_color = Color("#d6b66e")
	case_file_style.set_border_width_all(2)
	case_file_style.set_corner_radius_all(14)
	_case_file_button.add_theme_stylebox_override("normal", case_file_style)
	_case_file_button.pressed.connect(_show_case_file)
	header.add_child(_case_file_button)

	_hint_label = _make_label("INVESTIGATION 01 | THE FIRST CLUE", 16)
	_hint_label.anchor_left = 0.05
	_hint_label.anchor_right = 0.95
	_hint_label.anchor_top = 0.115
	_hint_label.anchor_bottom = 0.165
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_hint_label)
	_build_booster_dock(hud)

	_story_layer = CanvasLayer.new()
	_story_layer.name = "OpeningStory"
	_story_layer.layer = 5
	add_child(_story_layer)


func _make_hud_panel(parent: Control, file_name: String, initial_text: String, requested_size: Vector2 = Vector2.ZERO) -> Label:
	var panel := TextureRect.new()
	panel.texture = ResourceManager.load_texture("res://assets/sprites/ui/panels/" + file_name)
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.custom_minimum_size = requested_size if requested_size != Vector2.ZERO else (Vector2(142, 82) if file_name == "moves_panel.png" else Vector2(196, 82))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)
	var label := _make_label(initial_text, 22)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color("#fff8df"))
	label.add_theme_color_override("font_shadow_color", Color("#3a1737"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	return label


func _build_booster_dock(parent: CanvasLayer) -> void:
	var dock := PanelContainer.new()
	dock.name = "BoosterDock"
	dock.anchor_left = 0.08
	dock.anchor_right = 0.92
	dock.anchor_top = 0.86
	dock.anchor_bottom = 0.965
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
		"thunder": "res://assets/sprites/powerups/thunder_powerup_icon.jpeg"
	}
	for kind in ["rocket", "bomb", "thunder"]:
		var wrapper := VBoxContainer.new()
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_theme_constant_override("separation", 0)
		booster_row.add_child(wrapper)
		var button := TextureButton.new()
		button.name = "%sPowerup" % kind.capitalize()
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = Vector2(62, 56)
		button.texture_normal = ResourceManager.load_texture(icon_paths[kind])
		button.texture_hover = button.texture_normal
		button.texture_pressed = button.texture_normal
		button.pressed.connect(_on_booster_pressed.bind(kind))
		wrapper.add_child(button)
		var count := _make_label("1", 14)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wrapper.add_child(count)
		_booster_buttons[kind] = {"button": button, "count": count}
	dock.hide()


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
		enabled.text = "Enabled"
		enabled.button_pressed = audio_manager.is_music_enabled() if bus_kind == "music" else audio_manager.is_sfx_enabled()
		enabled.toggled.connect(_set_audio_enabled.bind(bus_kind))
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
		"Music and sound effects each have their own volume and on/off controls. Tap Pause to review the menu next.",
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


func _set_audio_enabled(enabled: bool, kind: String) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null:
		return
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
	var entrance := create_tween()
	entrance.tween_property(dialogue_panel, "modulate:a", 1.0, 0.28)


func _make_story_action_button(caption: String, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(width, 54)
	button.add_theme_font_size_override("font_size", 18)
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
	var moves := _make_label("MAKE YOUR MOVES COUNT | %d MOVES" % moves_total, 18)
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


func _begin_level(_route_id: String) -> void:
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
	var booster_config: Dictionary = level_data.get("powerups", {})
	var available_boosters: Array = booster_config.get("available", [])
	var boosters_allowed := bool(level_data.get("settings", {}).get("allow_boosters", false)) and bool(booster_config.get("enabled", false))
	_booster_dock.get_parent().visible = boosters_allowed
	_current_level_id = int(level_data.get("level_id", 1))
	_current_route_id = _route_id
	var objective := _get_primary_objective(level_data)
	var reward_data: Dictionary = level_data.get("rewards", {})
	_evidence_count = 0
	_evidence_goal = int(objective.get("amount", 10))
	_objective_target = str(objective.get("target", "KEY")).to_upper()
	_objective_type = str(objective.get("type", "COLLECT_ITEMS")).to_upper()
	if _objective_type == "DESTROY_OBSTACLES":
		_objective_label.text = "OBSTACLES\n0 / %d" % _evidence_goal
	else:
		_objective_label.text = "%s\n0 / %d" % [_objective_target.replace("_", " ") + "S", _evidence_goal]
	_reward_label.text = "REWARD\n%d COINS" % int(reward_data.get("coins", 0))
	_booster_inventory = {
		"rocket": 1 if available_boosters.has("ROCKET") else 0,
		"bomb": 1 if available_boosters.has("BOMB") else 0,
		"thunder": 1 if available_boosters.has("THUNDER") else 0
	}
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
		(entry["count"] as Label).text = str(_booster_inventory[kind])
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
			var obstacle_items: Array = level_data.get("obstacles", {}).get("items", [])
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
		_hint_label.text = "INVESTIGATION %02d | %s" % [
			int(level_data.get("level_id", 1)),
			str(level_data.get("name", "The Search Continues"))
		]
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
	_board.booster_used.connect(_on_booster_used)
	_board.obstacles_cleared.connect(_on_obstacles_cleared)
	_board.lock()
	_on_moves_changed(_board.get_remaining_moves())


func _on_moves_changed(remaining: int) -> void:
	_moves_remaining = remaining
	_moves_label.text = "MOVES\n%d" % remaining


func _on_tiles_matched(tile_types: Array) -> void:
	SignalBus.play_sfx.emit("tile_match")
	var target_enum := int(Constants.TileType.get(_objective_target, -1))
	for tile_type in tile_types:
		if _objective_type == "COLLECT_ITEMS" and int(tile_type) == target_enum:
			_evidence_count += 1
	_evidence_count = mini(_evidence_count, _evidence_goal)
	if _objective_type == "COLLECT_ITEMS":
		_objective_label.text = "%s\n%d / %d" % [_objective_target.replace("_", " ") + "S", _evidence_count, _evidence_goal]
	if _evidence_count >= _evidence_goal and _objective_type == "COLLECT_ITEMS":
		_hint_label.text = "CLUE SECURED | The evidence points toward Victor's route."
	elif not _tutorial_active:
		_hint_label.text = "CLUES | %d of %d %s collected" % [_evidence_count, _evidence_goal, _objective_target.replace("_", " ").to_lower()]


func _on_move_rejected() -> void:
	SignalBus.play_sfx.emit("invalid_move")
	_hint_label.text = "NO MATCH | Swap neighboring pieces to make a set of 3."


func _on_board_turn_resolved() -> void:
	if _result_layer != null:
		return
	var tutorial_result_pending := _tutorial_active and ["guided_swap", "booster_resolving", "activate_special"].has(_tutorial_action)
	if (_evidence_count >= _evidence_goal or _moves_remaining <= 0) and not tutorial_result_pending:
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
		message = "You hit the %s. Matches beside an obstacle remove one layer; clear every layer to open the route. The goal card still tracks the evidence." % obstacle_name
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
	_show_tutorial_tip("The rocket cleared its row and column in one move. Use a special piece when it can clear a blocked path or reach the mission evidence.", _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_cutout.png", true)


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
		_tutorial_action = "settings"
		if _board != null:
			_board.lock()
		_refresh_tutorial_controls()
		_show_tutorial_tip(
			"Tap the gear to adjust music and sound effects separately. You can change them again whenever you need.",
			_button_screen_rect(_settings_button),
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
	if _settings_button != null:
		_settings_button.disabled = _tutorial_active and _tutorial_action != "settings"
	for kind in _booster_buttons:
		var entry: Dictionary = _booster_buttons[kind]
		var button := entry["button"] as BaseButton
		var has_stock := int(_booster_inventory.get(kind, 0)) > 0
		button.visible = has_stock or (_tutorial_active and _tutorial_action == "booster_select" and kind == _tutorial_booster_kind)
		var tutorial_allows: bool = not _tutorial_active or (_tutorial_action == "booster_select" and kind == _tutorial_booster_kind)
		button.disabled = not has_stock or not tutorial_allows


func _on_booster_pressed(kind: String) -> void:
	if _tutorial_active and not (_tutorial_action == "booster_select" and kind == _tutorial_booster_kind):
		return
	if int(_booster_inventory.get(kind, 0)) <= 0 or _board == null:
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
	_board.unlock()
	_board.set_booster_mode(kind)
	_hint_label.text = "POWERUP | Tap a tile to use %s." % kind.capitalize()


func _on_booster_used(kind: String) -> void:
	_booster_inventory[kind] = maxi(0, int(_booster_inventory.get(kind, 0)) - 1)
	var entry: Dictionary = _booster_buttons.get(kind, {})
	if not entry.is_empty():
		(entry["count"] as Label).text = str(_booster_inventory[kind])
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
	if _objective_type != "DESTROY_OBSTACLES":
		return
	_evidence_count = mini(_evidence_goal, _evidence_count + amount)
	_objective_label.text = "OBSTACLES\n%d / %d" % [_evidence_count, _evidence_goal]
	if _evidence_count >= _evidence_goal:
		_hint_label.text = "OBJECTIVE COMPLETE | The route is clear."


func _evaluate_level_end() -> void:
	if _result_layer != null or _current_level_id <= 0:
		return
	if _evidence_count >= _evidence_goal:
		var level_manager := get_node_or_null("Managers/LevelManager")
		if level_manager != null:
			level_manager.complete_level()
		_show_level_result(true)
	elif _moves_remaining <= 0:
		var level_manager := get_node_or_null("Managers/LevelManager")
		if level_manager != null:
			level_manager.fail_level()
		_show_level_result(false)


func _show_level_result(won: bool) -> void:
	if _board != null:
		_board.lock()
	_tutorial_active = false
	_tutorial_action = ""
	if won:
		_record_level_completion()
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
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	card.add_child(content)
	var heading := _make_label("CLUE SECURED!" if won else "THE TRAIL WENT COLD", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var result_manager := get_node_or_null("Managers/LevelManager")
	var result_data: Dictionary = result_manager.get_level_data() if result_manager != null else {}
	var reward_info: Dictionary = result_data.get("rewards", {})
	var detail_text := "Case %03d is unlocked. +%d coins and %d stars saved." % [mini(_highest_unlocked_level, _current_level_id + 1), int(reward_info.get("coins", 0)), maxi(1, int(reward_info.get("stars", 3)))] if won else "The remaining moves ran out. No case was unlocked. Try the investigation again."
	var detail := _make_label(detail_text, 19)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(detail)
	if won:
		var next := _make_menu_button("NEXT LEVEL")
		next.pressed.connect(_next_level_after_win)
		content.add_child(next)
	else:
		var retry := _make_menu_button("RETRY LEVEL")
		retry.pressed.connect(_retry_current_level)
		content.add_child(retry)
	var map_button := _make_menu_button("CAMPAIGN MAP")
	map_button.pressed.connect(_return_to_campaign_map)
	content.add_child(map_button)
	card.modulate.a = 0.0
	var entrance := create_tween()
	entrance.tween_property(card, "modulate:a", 1.0, 0.28)
	if won:
		SignalBus.play_sfx.emit("level_victory")
	else:
		SignalBus.play_sfx.emit("level_failure")


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


func _record_level_completion() -> void:
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	var rewards: Dictionary = level_data.get("rewards", {})
	var stars_earned := maxi(1, int(rewards.get("stars", 3)))
	var old_stars := int(_completed_levels.get(str(_current_level_id), 0))
	_completed_levels[str(_current_level_id)] = maxi(stars_earned, old_stars)
	_highest_unlocked_level = maxi(_highest_unlocked_level, _current_level_id + 1)
	_campaign_progress.set_value("campaign", "highest_unlocked_level", _highest_unlocked_level)
	_campaign_progress.set_value("campaign", "completed_levels", _completed_levels)
	if old_stars == 0:
		_campaign_progress.set_value("campaign", "coins", int(_campaign_progress.get_value("campaign", "coins", 0)) + int(rewards.get("coins", 0)))
		_campaign_progress.set_value("campaign", "total_stars", int(_campaign_progress.get_value("campaign", "total_stars", 0)) + stars_earned)
	var error := _campaign_progress.save(CAMPAIGN_PROGRESS_PATH)
	if error != OK:
		push_error("Could not save campaign progress: %s" % error_string(error))
