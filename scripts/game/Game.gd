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
	family.custom_minimum_size = Vector2(320, 485)
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
	return button


func _show_pause_menu() -> void:
	if _pause_layer != null:
		return
	get_tree().paused = true
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
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(460, 340)
	center.add_child(frame)
	var art := TextureRect.new()
	art.texture = ResourceManager.load_texture("res://assets/sprites/ui/screens/pause_screen.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(art)
	var resume := _make_texture_button("play", Vector2(150, 70))
	resume.anchor_left = 0.3
	resume.anchor_right = 0.7
	resume.anchor_top = 0.015
	resume.anchor_bottom = 0.22
	resume.pressed.connect(_close_pause_menu)
	frame.add_child(resume)
	var actions := VBoxContainer.new()
	actions.anchor_left = 0.18
	actions.anchor_right = 0.82
	actions.anchor_top = 0.37
	actions.anchor_bottom = 0.94
	actions.add_theme_constant_override("separation", 5)
	frame.add_child(actions)
	var settings := _make_texture_button("settings", Vector2(190, 70))
	settings.pressed.connect(_show_settings_popup)
	actions.add_child(settings)
	var sound := Button.new()
	sound.text = "SOUND: ON"
	sound.custom_minimum_size.y = 44
	sound.pressed.connect(_toggle_sound.bind(sound))
	actions.add_child(sound)
	var title := _make_texture_button("back", Vector2(190, 70))
	title.pressed.connect(_return_to_title)
	actions.add_child(title)


func _close_pause_menu() -> void:
	get_tree().paused = false
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
	_story_continue_button.pressed.connect(_begin_level.bind(route_id), CONNECT_ONE_SHOT)
	set_meta("chosen_route", route_id)


func _begin_level(_route_id: String) -> void:
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
	for tile_type in tile_types:
		if int(tile_type) == Constants.TileType.KEY:
			_evidence_count += 1
	_objective_label.text = "EVIDENCE\n%d / %d keys" % [_evidence_count, _evidence_goal]
	if _evidence_count >= _evidence_goal:
		_hint_label.text = "CLUE SECURED  •  The evidence points toward Victor’s route."
	else:
		_hint_label.text = "EVIDENCE  •  %d of %d keys recovered" % [_evidence_count, _evidence_goal]


func _on_move_rejected() -> void:
	_hint_label.text = "That swap makes no match. Try another pair of neighboring pieces."
