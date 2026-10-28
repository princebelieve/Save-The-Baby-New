extends Node2D
class_name Game

const OPENING_STORY_PATH := "res://stories/opening_story.json"

var _board_manager: Node
var _board: Board
var _story: Dictionary = {}
var _story_manager: StoryManager
var _story_layer: CanvasLayer
var _dialogue_label: Label
var _speaker_label: Label
var _story_continue_button: TextureButton
var _story_skip_button: TextureButton
var _story_previous_button: TextureButton
var _launch_layer: CanvasLayer
var _story_portrait: TextureRect
var _pause_layer: CanvasLayer
var _briefing_layer: CanvasLayer
var _chosen_route_label: String = "Go after Victor alone"
var _dialogue_tween: Tween
var _is_dialogue_typing: bool = false
var _choice_box: VBoxContainer
var _moves_label: Label
var _objective_label: Label
var _hint_label: Label
var _evidence_count: int = 0
var _evidence_goal: int = 10
var _moves_remaining: int = 0


func _ready() -> void:
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
	_show_launch_screen()
	if _board != null:
		_board.lock()


func _load_game_art() -> void:
	var background := get_node_or_null("BackgroundLayer/Background") as ColorRect
	if background == null:
		return
	var art := TextureRect.new()
	art.name = "InvestigationBackground"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = ResourceManager.load_texture("res://assets/sprites/backgrounds/riverside_landscape.jpeg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_child(art)
	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.015, 0.045, 0.055, 0.68)
	background.add_child(tint)


func _show_launch_screen() -> void:
	_launch_layer = CanvasLayer.new()
	_launch_layer.name = "LaunchScreen"
	_launch_layer.layer = 10
	add_child(_launch_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.035, 0.92)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	center.add_child(content)
	var family := TextureRect.new()
	family.custom_minimum_size = Vector2(440, 400)
	family.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	family.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	family.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	family.texture = ResourceManager.load_texture("res://assets/sprites/ui/title_art_family.jpeg")
	content.add_child(family)
	var start := _make_texture_button("play", Vector2(230, 108))
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_start_opening_story)
	content.add_child(start)
	family.modulate.a = 0.0
	family.scale = Vector2(0.97, 0.97)
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(family, "modulate:a", 1.0, 0.55)
	entrance.tween_property(family, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	start.modulate.a = 0.0
	var button_entrance := create_tween()
	button_entrance.tween_interval(0.3)
	button_entrance.tween_property(start, "modulate:a", 1.0, 0.3)


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

	var header := HBoxContainer.new()
	header.name = "MissionHeader"
	header.anchor_left = 0.06
	header.anchor_right = 0.94
	header.anchor_top = 0.035
	header.anchor_bottom = 0.145
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	hud.add_child(header)
	_moves_label = _make_hud_panel(header, "moves_panel.png", "MOVES\n30")
	_objective_label = _make_hud_panel(header, "score_panel.png", "EVIDENCE\n0 / 10 KEYS")
	var pause_button := _make_texture_button("pause", Vector2(118, 74))
	pause_button.pressed.connect(_show_pause_menu)
	header.add_child(pause_button)

	_hint_label = _make_label("INVESTIGATION 01  •  THE FIRST CLUE", 18)
	_hint_label.anchor_left = 0.06
	_hint_label.anchor_right = 0.94
	_hint_label.anchor_top = 0.145
	_hint_label.anchor_bottom = 0.195
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(_hint_label)

	_story_layer = CanvasLayer.new()
	_story_layer.name = "OpeningStory"
	_story_layer.layer = 5
	add_child(_story_layer)


func _make_hud_panel(parent: Control, file_name: String, initial_text: String) -> Label:
	var panel := TextureRect.new()
	panel.texture = ResourceManager.load_texture("res://assets/sprites/ui/panels/" + file_name)
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.custom_minimum_size = Vector2(180, 118)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)
	var label := _make_label(initial_text, 22)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", Color("#172d4a"))
	label.add_theme_color_override("font_shadow_color", Color("#ffffff"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 19)
	panel.add_child(label)
	return label


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
	frame.custom_minimum_size = Vector2(460, 470)
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
	var resume := _make_menu_button("RESUME")
	resume.pressed.connect(_close_pause_menu)
	actions.add_child(resume)
	var settings := _make_menu_button("SETTINGS")
	settings.pressed.connect(_show_settings_popup)
	actions.add_child(settings)
	var sound := _make_menu_button("SOUND: ON")
	sound.pressed.connect(_toggle_sound.bind(sound))
	actions.add_child(sound)
	var title := _make_menu_button("RETURN TO TITLE")
	title.pressed.connect(_return_to_title)
	actions.add_child(title)
	var sound_bus := AudioServer.get_bus_index("Master")
	if sound_bus != -1 and AudioServer.is_bus_mute(sound_bus):
		sound.text = "SOUND: OFF"


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


func _toggle_sound(button: Button) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
	button.text = "SOUND: OFF" if AudioServer.is_bus_mute(bus) else "SOUND: ON"


func _show_settings_popup() -> void:
	var popup := AcceptDialog.new()
	popup.title = "Settings"
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_layer.add_child(popup)
	var settings := VBoxContainer.new()
	settings.custom_minimum_size = Vector2(320, 72)
	var volume_label := Label.new()
	volume_label.text = "Master volume"
	settings.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.01
	var bus := AudioServer.get_bus_index("Master")
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	volume.value_changed.connect(_set_master_volume)
	settings.add_child(volume)
	popup.add_child(settings)
	popup.popup_centered()


func _set_master_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus, is_zero_approx(value))


func _return_to_title() -> void:
	SignalBus.play_sfx.emit("ui_back")
	SignalBus.stop_music.emit()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", Color("#fff3d5"))
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
	if not SignalBus.story_choice_presented.is_connected(_present_route_choices):
		SignalBus.story_choice_presented.connect(_present_route_choices)
	if not SignalBus.choice_selected.is_connected(_on_route_selected):
		SignalBus.choice_selected.connect(_on_route_selected)


func _show_story_overlay() -> void:
	var story_background := TextureRect.new()
	story_background.name = "StoryBackground"
	story_background.texture = ResourceManager.load_texture(str(_story.get("default_background", "")))
	story_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_story_layer.add_child(story_background)

	var veil := ColorRect.new()
	veil.name = "StoryVeil"
	veil.color = Color(0.015, 0.025, 0.035, 0.45)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_layer.add_child(veil)
	veil.modulate.a = 0.0
	var veil_tween := create_tween()
	veil_tween.tween_property(veil, "modulate:a", 1.0, 0.35)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var panel := PanelContainer.new()
	var viewport_size := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(minf(560.0, viewport_size.x * 0.9), minf(760.0, viewport_size.y * 0.9))
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.07, 0.13, 0.94)
	panel_style.border_color = Color("#c49a5a")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	panel.modulate.a = 0.0
	var panel_entrance := create_tween()
	panel_entrance.tween_interval(0.12)
	panel_entrance.tween_property(panel, "modulate:a", 1.0, 0.28)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var title := _make_label(str(_story.get("title", "The Night Ethan Vanished")), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	_story_portrait = TextureRect.new()
	_story_portrait.custom_minimum_size = Vector2(180, 180)
	_story_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_story_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_story_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path := str(_story.get("portrait", ""))
	if not portrait_path.is_empty():
		_story_portrait.texture = ResourceManager.load_texture(portrait_path)
	content.add_child(_story_portrait)

	_speaker_label = _make_label("", 22)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_speaker_label)
	_dialogue_label = _make_label("", 22)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.custom_minimum_size = Vector2(520, 140)
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_dialogue_label)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 10)
	content.add_child(_choice_box)
	var story_actions := HBoxContainer.new()
	story_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	story_actions.add_theme_constant_override("separation", 10)
	content.add_child(story_actions)
	_story_previous_button = _make_texture_button("previous", Vector2(106, 58), "story_buttons")
	_story_previous_button.pressed.connect(_previous_story_dialogue)
	_story_previous_button.hide()
	story_actions.add_child(_story_previous_button)
	_story_skip_button = _make_texture_button("skip", Vector2(145, 58), "story_buttons")
	_story_skip_button.pressed.connect(_skip_opening_story)
	story_actions.add_child(_story_skip_button)
	_story_continue_button = _make_texture_button("continue", Vector2(225, 58), "story_buttons")
	_story_continue_button.pressed.connect(_advance_story)
	story_actions.add_child(_story_continue_button)
	_dialogue_label.text = ""
	_speaker_label.text = ""


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
	_dialogue_label.visible_characters = 0
	_is_dialogue_typing = true
	_story_continue_button.disabled = true
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_label, "visible_characters", _dialogue_label.text.length(), maxf(0.65, _dialogue_label.text.length() * 0.028))
	_dialogue_tween.finished.connect(_finish_dialogue_typing)
	_story_previous_button.visible = int(_dialogue_id) > 0
	var speaker := str(line.get("speaker", ""))
	if speaker == "Amara":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/amara_police_portrait.jpeg")
	elif speaker == "Unknown number":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/victor_portrait_dark.jpeg")
	_story_portrait.modulate.a = 0.0
	_story_portrait.scale = Vector2(0.94, 0.94)
	var portrait_tween := create_tween().set_parallel(true)
	portrait_tween.tween_property(_story_portrait, "modulate:a", 1.0, 0.3)
	portrait_tween.tween_property(_story_portrait, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _present_route_choices(choices: Array) -> void:
	if not _choice_box.get_children().is_empty():
		return
	_speaker_label.text = "A choice must be made before the trail goes cold."
	_dialogue_label.text = "How will David begin the search?"
	_dialogue_label.visible_characters = -1
	_is_dialogue_typing = false
	_story_continue_button.disabled = false
	_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/david_portrait.jpeg")
	_story_portrait.custom_minimum_size = Vector2(110, 110)
	_story_continue_button.hide()
	_story_skip_button.hide()
	_story_previous_button.hide()
	for choice in choices:
		var filenames := {"police": "call_police.png", "signal": "trace_signal.png", "alone": "go_alone.png"}
		var image_file := str(filenames.get(str(choice.get("id", "")), ""))
		var button: BaseButton
		if not image_file.is_empty():
			var image_button := TextureButton.new()
			image_button.texture_normal = ResourceManager.load_texture("res://assets/sprites/ui/story_choices/" + image_file)
			image_button.texture_hover = image_button.texture_normal
			image_button.texture_pressed = image_button.texture_normal
			image_button.ignore_texture_size = true
			image_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			image_button.custom_minimum_size = Vector2(420, 68)
			button = image_button
		else:
			var text_button := Button.new()
			text_button.text = str(choice.get("label", "Choose"))
			text_button.custom_minimum_size = Vector2(420, 54)
			button = text_button
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
	_begin_level("skipped")


func _on_route_selected(choice: Dictionary) -> void:
	for button in _choice_box.get_children():
		button.disabled = true
		button.queue_free()
	var route_id := str(choice.get("id", "alone"))
	if route_id == "police":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/detective_portrait.jpeg")
	elif route_id == "signal":
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/amara_police_portrait.jpeg")
	else:
		_story_portrait.texture = ResourceManager.load_texture("res://assets/sprites/characters/david_portrait.jpeg")
	_speaker_label.text = str(choice.get("label", ""))
	_dialogue_label.text = str(choice.get("response", "The search begins."))
	_story_continue_button.texture_normal = ResourceManager.load_texture("res://assets/sprites/ui/story_buttons/next_normal.png")
	_story_continue_button.texture_hover = ResourceManager.load_texture("res://assets/sprites/ui/story_buttons/next_hover.png")
	_story_continue_button.texture_pressed = ResourceManager.load_texture("res://assets/sprites/ui/story_buttons/next_pressed.png")
	_story_continue_button.show()
	_story_continue_button.pressed.disconnect(_advance_story)
	_chosen_route_label = str(choice.get("label", "Begin the search"))
	_story_continue_button.pressed.connect(_show_level_briefing.bind(route_id), CONNECT_ONE_SHOT)
	set_meta("chosen_route", route_id)


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
		"police": "res://assets/sprites/characters/detective_portrait.jpeg",
		"signal": "res://assets/sprites/characters/amara_police_portrait.jpeg",
		"alone": "res://assets/sprites/characters/david_portrait.jpeg"
	}
	portrait.texture = ResourceManager.load_texture(str(portrait_paths.get(route_id, portrait_paths["alone"])))
	content.add_child(portrait)
	var route_label := _make_label("APPROACH  •  " + _chosen_route_label.to_upper(), 17)
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_label)
	var description := _make_label(str(level_data.get("description", "")), 19)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 480
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(description)

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
	var moves := _make_label("MAKE YOUR MOVES COUNT  •  %d MOVES" % moves_total, 18)
	moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(moves)
	var settings: Dictionary = level_data.get("settings", {})
	if not bool(settings.get("allow_boosters", false)):
		var booster_note := _make_label("BOOSTERS UNLOCK ON A LATER INVESTIGATION", 14)
		booster_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(booster_note)

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
	if _briefing_layer != null and is_instance_valid(_briefing_layer):
		_briefing_layer.queue_free()
	_briefing_layer = null
	if _story_manager != null:
		_story_manager.end_story()
	_story_layer.queue_free()
	_hint_label.text = "TUTORIAL  •  DRAG between adjacent pieces to make a match of three"
	if _board != null:
		_board.unlock()


func _on_board_created() -> void:
	var created_board: Board = _board_manager.get_board()
	if created_board == null or created_board == _board:
		return
	_board = created_board
	_board.moves_changed.connect(_on_moves_changed)
	_board.match_collected.connect(_on_tiles_matched)
	_board.move_rejected.connect(_on_move_rejected)
	_board.lock()
	_on_moves_changed(_board.get_remaining_moves())


func _on_moves_changed(remaining: int) -> void:
	_moves_remaining = remaining
	_moves_label.text = "MOVES\n%d" % remaining


func _on_tiles_matched(tile_types: Array) -> void:
	SignalBus.play_sfx.emit("tile_match")
	for tile_type in tile_types:
		if int(tile_type) == Constants.TileType.KEY:
			_evidence_count += 1
	_objective_label.text = "EVIDENCE\n%d / %d keys" % [_evidence_count, _evidence_goal]
	if _evidence_count >= _evidence_goal:
		_hint_label.text = "CLUE SECURED  •  The evidence points toward Victor’s route."
	else:
		_hint_label.text = "EVIDENCE  •  %d of %d keys recovered" % [_evidence_count, _evidence_goal]


func _on_move_rejected() -> void:
	SignalBus.play_sfx.emit("invalid_move")
	_hint_label.text = "That swap makes no match. Try another pair of neighboring pieces."
