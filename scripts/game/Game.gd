extends Node2D
class_name Game

const DISPLAY_FONT: FontFile = preload("res://assets/fonts/Baloo2-Variable.ttf")

const OPENING_STORY_PATH := "res://stories/opening_story.json"
const CAMPAIGN_PROGRESS_PATH := "user://campaign_progress.cfg"

var _ads: AdManager
var _ad_attempt := 0
var _ad_revived := false
var _result_ad_shown := false

var _account_panel: Node

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
var _story_dialogue_panel: PanelContainer
var _story_scroll_top_roll: Panel
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
var _last_typing_tick_character: int = 0
var _choice_box: VBoxContainer
var _moves_label: Label
var _objective_label: Label
var _objective_title_label: Label
var _blocker_label: Label
var _reward_label: Label
var _lives_label: Label
var _objective_target_icon: TextureRect
var _level_number_label: Label
var _objective_description_label: Label
var _hint_label: Label
var _pause_button: TextureButton
var _case_file_button: BaseButton
var _case_file_layer: CanvasLayer
var _case_file_was_board_locked := false
var _booster_dock: PanelContainer
var _booster_buttons: Dictionary = {}
var _result_layer: CanvasLayer
var _result_in_progress := false
var _result_stars_earned := 1
var _current_level_points := 0
var _clear_bonus_coins := 0
var _evidence_count: int = 0
var _evidence_goal: int = 10
var _objective_target := "KEY"
var _objective_type := "COLLECT_ITEMS"
var _hud_profile := "investigation"
var _status_panel: Panel
var _mission_panel: Panel
var _moves_remaining: int = 0
var _current_level_id := 1
var _current_route_id := "alone"
var _booster_inventory: Dictionary = {}
var _obstacles_goal := 0
var _obstacles_cleared := 0
var _displayed_coins := 0
var _coin_count_tween: Tween
var _selected_booster := ""
var _booster_confirm: IllustratedPopup
var _booster_confirm_layer: CanvasLayer
var _academy_pending_level: Dictionary = {}
var _academy_lesson_id := ""
var _detail_layer: CanvasLayer
var _tutorial_active := false
var _tutorial_skip_pending := false
var _tutorial_action := ""
var _tutorial_mechanic := ""
var _tutorial_pause_open := false
var _tutorial_booster_kind := ""
var _tutorial_target_cell := Vector2i(-1, -1)
var _campaign_coach_shown := false
var _idle_hint_timer: Timer
var _campaign_progress := ConfigFile.new()
var _highest_unlocked_level := 1
var _completed_levels: Dictionary = {}
var _gameplay_effects: GameplayEffects
var _turn_praise_rank := 0
var _suppress_character_rewards_this_turn := false
var _last_character_rewards := {"ethan": 0, "detective": 0, "victor": 0}
var _waiting_for_collection := false
var _special_moves_created := 0
var _objective_complete_sound_played := false
var _story_objective_sound_pending := false
var _restore_tutorial_after_pause := false


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# A screen switch can cancel a touch while a board tween is still active.
		# Always clear that gesture and persist, even when a full-screen ad owns
		# the foreground; only the ad provider should manage its own pause UI.
		if _board != null:
			_board.cancel_pointer_gesture()
		_persist_campaign_progress()
		if (_ads == null or not _ads.busy) and not CloudAccount.login_in_progress() and _board != null and _launch_layer == null and _story_layer == null and _campaign_layer == null and _result_layer == null:
			_show_pause_menu(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if _board != null:
			_board.cancel_pointer_gesture()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_request()


func _handle_back_request() -> void:
	var dialogs := find_children("*", "AcceptDialog", true, false)
	for index in range(dialogs.size() - 1, -1, -1):
		var dialog := dialogs[index] as AcceptDialog
		if dialog.visible:
			dialog.hide()
			return
	if _detail_layer != null and is_instance_valid(_detail_layer):
		_close_detail()
	elif _case_file_layer != null and is_instance_valid(_case_file_layer):
		_close_case_file()
	elif _pause_layer != null:
		_close_pause_menu()
	elif _result_layer != null and is_instance_valid(_result_layer):
		_return_to_campaign_map()
	elif _campaign_layer != null and is_instance_valid(_campaign_layer):
		if _tutorial_action == "campaign_map_intro" and _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()
			_on_tutorial_acknowledged()
		else:
			_campaign_layer.queue_free()
			_campaign_layer = null
			_campaign_map = null
			if _tutorial_overlay != null:
				_tutorial_overlay.hide_tip()
			_tutorial_action = ""
			_show_launch_screen()
	elif _story_layer != null and is_instance_valid(_story_layer):
		_story_layer.queue_free()
		_story_layer = null
		_show_launch_screen()
	elif _board != null and _launch_layer == null:
		_show_pause_menu(true)
	else:
		get_tree().quit()


func _ready() -> void:
	_ads = AdManager.new()
	add_child(_ads)
	if not SignalBus.board_shuffled.is_connected(_on_board_shuffled):
		SignalBus.board_shuffled.connect(_on_board_shuffled)
	var provider := get_node_or_null("/root/AdProvider")
	if provider != null:
		_ads.configure(provider)
	_load_campaign_progress()
	_campaign_coach_shown = bool(_campaign_progress.get_value("tutorials", "campaign_map_intro", false))
	_special_moves_created = int(_campaign_progress.get_value("campaign", "special_moves_created", 0))
	_economy_manager = get_node_or_null("Managers/EconomyManager") as EconomyManager
	_reward_manager = get_node_or_null("Managers/RewardManager") as RewardManager
	if _economy_manager != null:
		var game_config: Dictionary = ConfigLoader.load_config(Constants.ConfigPaths.GAME)
		_economy_manager.set_coins(int(_campaign_progress.get_value("campaign", "coins", int(game_config.get("starting_coins", 0)))))
		var initial_lives := int(_campaign_progress.get_value("campaign", "lives", int(game_config.get("max_lives", 5))))
		_economy_manager.set_lives(initial_lives)
		_economy_manager.restore_life_clock(int(_campaign_progress.get_value("campaign", "life_regeneration_time", TimeHelper.current_unix_time())))
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

	_account_panel = preload("res://scripts/online/AccountPanel.gd").new()
	add_child(_account_panel)
	_account_panel.initialize(self)


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
	_apply_opening_background_blur(art)
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


func _apply_opening_background_blur(target: TextureRect) -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 px = vec2(0.055);
	vec4 color = textureLod(TEXTURE, UV, 6.5) * 0.28;
	color += textureLod(TEXTURE, clamp(UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0)), 6.5) * 0.12;
	color += textureLod(TEXTURE, clamp(UV - vec2(px.x, 0.0), vec2(0.0), vec2(1.0)), 6.5) * 0.12;
	color += textureLod(TEXTURE, clamp(UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0)), 6.5) * 0.12;
	color += textureLod(TEXTURE, clamp(UV - vec2(0.0, px.y), vec2(0.0), vec2(1.0)), 6.5) * 0.12;
	color += textureLod(TEXTURE, clamp(UV + px, vec2(0.0), vec2(1.0)), 6.5) * 0.06;
	color += textureLod(TEXTURE, clamp(UV - px, vec2(0.0), vec2(1.0)), 6.5) * 0.06;
	color += textureLod(TEXTURE, clamp(UV + vec2(px.x, -px.y), vec2(0.0), vec2(1.0)), 6.5) * 0.06;
	color += textureLod(TEXTURE, clamp(UV + vec2(-px.x, px.y), vec2(0.0), vec2(1.0)), 6.5) * 0.06;
	COLOR = vec4(color.rgb, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	target.material = material
	target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


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
	_apply_opening_background_blur(background)
	layer.add_child(background)
	var wash := ColorRect.new()
	wash.color = Color(0.015, 0.055, 0.075, 0.56)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(wash)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var logo_side := minf(get_viewport_rect().size.x * 0.9, 560.0)
	stack.size = Vector2(logo_side + 40.0, logo_side + 100.0)
	stack.position = -stack.size * 0.5
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	wash.add_child(stack)
	var logo := TextureRect.new()
	logo.texture = ResourceManager.load_texture("res://assets/sprites/ui/game_logo_cutout.png")
	logo.custom_minimum_size = Vector2.ONE * logo_side
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
	_idle_hint_timer = Timer.new()
	_idle_hint_timer.name = "IdleMoveHintTimer"
	_idle_hint_timer.one_shot = true
	_idle_hint_timer.wait_time = 14.0
	_idle_hint_timer.timeout.connect(_show_idle_move_hint)
	add_child(_idle_hint_timer)
	var tween := create_tween()
	tween.tween_property(progress, "value", 100.0, 1.6)
	tween.tween_callback(func():
		layer.queue_free()
		_show_launch_screen()
	)


func _show_launch_screen() -> void:
	SignalBus.play_music.emit("suspense_opening")
	_launch_layer = CanvasLayer.new()
	_launch_layer.name = "LaunchScreen"
	_launch_layer.layer = 10
	add_child(_launch_layer)
	var background := TextureRect.new()
	background.texture = _load_full_bleed_background("res://assets/sprites/backgrounds/riverside_landscape.jpeg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_opening_background_blur(background)
	_launch_layer.add_child(background)
	var veil := ColorRect.new()
	veil.color = Color(0.008, 0.025, 0.055, 0.58)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_launch_layer.add_child(veil)
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(content)
	var viewport_size := get_viewport_rect().size
	var logo := TextureRect.new()
	logo.position = Vector2(viewport_size.x * 0.14, viewport_size.y * 0.035)
	logo.size = Vector2(viewport_size.x * 0.72, viewport_size.y * 0.28)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture = ResourceManager.load_texture("res://assets/sprites/ui/game_logo_cutout.png")
	content.add_child(logo)
	var family := TextureRect.new()
	family.position = Vector2(viewport_size.x * 0.13, viewport_size.y * 0.33)
	family.size = Vector2(viewport_size.x * 0.74, viewport_size.y * 0.33)
	family.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	family.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	family.texture = ResourceManager.load_portrait("res://assets/sprites/characters/amara_and_ethan_portrait_cutout.png")
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
	var settings_size := Vector2(minf(154.0, viewport_size.x * 0.30), 64.0)
	var settings_button := _make_texture_button("settings", settings_size)
	settings_button.position = Vector2(viewport_size.x - settings_size.x - 18.0, 18.0)
	settings_button.size = settings_size
	settings_button.pressed.connect(_show_title_settings)
	content.add_child(settings_button)
	var account_button := _make_menu_button("ACCOUNT & COINS")
	account_button.position = Vector2(viewport_size.x * 0.22, viewport_size.y * 0.89)
	account_button.size = Vector2(viewport_size.x * 0.56, 54)
	account_button.add_theme_font_size_override("font_size",20)
	account_button.pressed.connect(func(): _account_panel.show_account())
	content.add_child(account_button)
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
		_launch_layer = null
	var saved_route := str(_campaign_progress.get_value("campaign", "route", ""))
	if saved_route in ["alone", "police", "signal"]:
		_chosen_route_label = str(_campaign_progress.get_value("campaign", "route_label", _chosen_route_label))
		_show_campaign_map(saved_route)
		return
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
	var hud_scale := clampf(get_viewport_rect().size.x / 720.0, 0.72, 1.0)
	_build_level_objective_row(hud)
	var status_row := Control.new()
	status_row.name = "StatusRow"
	status_row.anchor_left = 0.025
	status_row.anchor_right = 0.975
	status_row.anchor_top = 0.104
	status_row.anchor_bottom = 0.216
	_status_panel = Panel.new()
	_status_panel.name = "StatusRowBacking"
	_status_panel.anchor_left = 0.025
	_status_panel.anchor_right = 0.975
	_status_panel.anchor_top = 0.101
	_status_panel.anchor_bottom = 0.219
	_apply_hud_profile_style()
	hud.add_child(_status_panel)
	hud.add_child(status_row)
	_moves_label = _make_compact_hud_panel(status_row, "MovesCounter", "0", Vector2(124, 94) * hud_scale, roundi(31 * hud_scale), Color("#38c8e5"))
	var moves_panel := _moves_label.get_parent().get_parent() as Control
	moves_panel.anchor_left = 0.0
	moves_panel.anchor_right = 0.22
	moves_panel.anchor_top = 0.0
	moves_panel.anchor_bottom = 1.0
	_lives_label = _make_compact_hud_panel(status_row, "LifeHearts", "0/5", Vector2(170, 46) * hud_scale, roundi(26 * hud_scale), Color("#f06c9b"))
	_reward_label = _make_compact_hud_panel(status_row, "CoinCounter", "0", Vector2(188, 46) * hud_scale, roundi(26 * hud_scale), Color("#e9bd55"))
	var lives_panel := _lives_label.get_parent().get_parent() as Control
	lives_panel.anchor_left = 0.22
	lives_panel.anchor_right = 0.89
	lives_panel.anchor_top = 0.035
	lives_panel.anchor_bottom = 0.49
	lives_panel.custom_minimum_size = Vector2(0, 46 * hud_scale)
	var coins_panel := _reward_label.get_parent().get_parent() as Control
	coins_panel.anchor_left = 0.22
	coins_panel.anchor_right = 0.89
	coins_panel.anchor_top = 0.51
	coins_panel.anchor_bottom = 0.965
	coins_panel.custom_minimum_size = Vector2(0, 46 * hud_scale)
	_pause_button = TextureButton.new()
	_pause_button.name = "SettingsButton"
	_pause_button.ignore_texture_size = true
	_pause_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_pause_button.custom_minimum_size = Vector2(64, 68) * hud_scale
	var pause_icon := _load_hud_asset("res://assets/sprites/ui/hud/pause_button.png")
	_pause_button.texture_normal = pause_icon
	_pause_button.texture_hover = pause_icon
	_pause_button.texture_pressed = pause_icon
	_pause_button.tooltip_text = "PAUSE AND SETTINGS"
	_pause_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pause_button.pressed.connect(_play_ui_click)
	_pause_button.pressed.connect(_show_pause_menu)
	_pause_button.anchor_left = 0.90
	_pause_button.anchor_right = 1.0
	_pause_button.anchor_top = 0.0
	_pause_button.anchor_bottom = 1.0
	status_row.add_child(_pause_button)
	_hint_label = _make_label("INVESTIGATION 01 | THE FIRST CLUE", 22)
	_hint_label.anchor_left = 0.08
	_hint_label.anchor_right = 0.92
	_hint_label.anchor_top = 0.219
	_hint_label.anchor_bottom = 0.249
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


func _build_level_objective_row(parent: CanvasLayer) -> void:
	var hud_scale := clampf(get_viewport_rect().size.x / 720.0, 0.72, 1.0)
	var panel := Panel.new()
	panel.name = "MissionHeader"
	panel.anchor_left = 0.025
	panel.anchor_right = 0.975
	panel.anchor_top = 0.014
	panel.anchor_bottom = 0.099
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.08, 0.105, 0.94)
	style.border_color = Color("#d6b66e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 10
	style.content_margin_right = 10
	panel.add_theme_stylebox_override("panel", style)
	_mission_panel = panel
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.name = "LevelObjectiveRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var level_box := Control.new()
	level_box.name = "LevelNumber"
	level_box.custom_minimum_size = Vector2(102, 70) * hud_scale
	row.add_child(level_box)
	var level_card := Panel.new()
	level_card.name = "LevelCard"
	level_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var level_card_style := StyleBoxFlat.new()
	level_card_style.bg_color = Color("#17314a")
	level_card_style.border_color = Color("#e9b956")
	level_card_style.set_border_width_all(2)
	level_card_style.set_corner_radius_all(13)
	level_card_style.shadow_color = Color(0.01, 0.025, 0.04, 0.72)
	level_card_style.shadow_size = 3
	level_card_style.shadow_offset = Vector2(0, 2)
	level_card_style.content_margin_left = 6
	level_card_style.content_margin_right = 6
	level_card_style.content_margin_top = 4
	level_card_style.content_margin_bottom = 4
	level_card.add_theme_stylebox_override("panel", level_card_style)
	level_box.add_child(level_card)
	var level_card_content := VBoxContainer.new()
	level_card_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_card_content.add_theme_constant_override("separation", 0)
	level_card_content.alignment = BoxContainer.ALIGNMENT_CENTER
	level_card.add_child(level_card_content)
	var level_caption := _make_label("LEVEL", roundi(16 * hud_scale))
	level_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_caption.add_theme_color_override("font_color", Color("#f0c66f"))
	level_caption.add_theme_constant_override("outline_size", 1)
	level_caption.add_theme_color_override("font_outline_color", Color("#10253b"))
	level_card_content.add_child(level_caption)
	_level_number_label = _make_label("001", roundi(38 * hud_scale))
	_level_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_level_number_label.add_theme_color_override("font_color", Color("#fff2d1"))
	_level_number_label.add_theme_color_override("font_outline_color", Color("#10253b"))
	_level_number_label.add_theme_constant_override("outline_size", 1)
	level_card_content.add_child(_level_number_label)
	_objective_target_icon = TextureRect.new()
	_objective_target_icon.name = "ObjectiveTargetIcon"
	_objective_target_icon.custom_minimum_size = Vector2(58, 58) * hud_scale
	_objective_target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_objective_target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_objective_target_icon.texture = ResourceManager.load_texture(_objective_icon_path(_objective_target))
	_objective_target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_objective_target_icon)
	var objective_copy := VBoxContainer.new()
	objective_copy.name = "ObjectiveCopy"
	objective_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	objective_copy.add_theme_constant_override("separation", 0)
	row.add_child(objective_copy)
	_objective_description_label = _make_label("COLLECT THE CLUES", roundi(26 * hud_scale))
	_objective_description_label.clip_text = false
	_objective_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_description_label.custom_minimum_size.y = 34
	_objective_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective_description_label.add_theme_color_override("font_color", Color("#fff5dc"))
	objective_copy.add_child(_objective_description_label)
	_objective_label = _make_label("0 / 0", roundi(29 * hud_scale))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective_label.add_theme_color_override("font_color", Color("#f4ce49"))
	objective_copy.add_child(_objective_label)
	_case_file_button = _make_story_action_button("CASE FILE", 142)
	_case_file_button.name = "CaseFileButton"
	_case_file_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_case_file_button.tooltip_text = "OPEN CASE FILE"
	_case_file_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_case_file_button.pressed.connect(_show_case_file)
	row.add_child(_case_file_button)
	_apply_hud_profile_style()


func _resolve_hud_profile(level_data: Dictionary) -> String:
	var hud_settings: Dictionary = level_data.get("hud", {})
	var metadata: Dictionary = level_data.get("metadata", {})
	var requested := str(hud_settings.get("profile", metadata.get("hud_profile", ""))).to_lower()
	if requested in ["investigation", "hazard", "rescue"]:
		return requested
	var objectives: Array = level_data.get("objectives", [])
	for objective_value in objectives:
		if typeof(objective_value) != TYPE_DICTIONARY:
			continue
		var kind := str(objective_value.get("type", "")).to_upper()
		if kind in ["DESTROY_OBSTACLES", "UNLOCK_DOORS", "DEFUSE_BOMBS", "CLEAR_ALL_JELLY"]:
			return "hazard"
		if kind in ["RESCUE_BABY", "SURVIVE"]:
			return "rescue"
	var obstacle_items: Array = level_data.get("obstacles", {}).get("items", [])
	if not obstacle_items.is_empty():
		return "hazard"
	return "investigation"


func _apply_hud_profile_style() -> void:
	var palette := {
		"investigation": [Color(0.025, 0.08, 0.105, 0.94), Color("#d6b66e")],
		"hazard": [Color(0.12, 0.055, 0.035, 0.96), Color("#ff9b45")],
		"rescue": [Color(0.11, 0.035, 0.065, 0.96), Color("#ff8eaa")],
	}
	var colors: Array = palette.get(_hud_profile, palette["investigation"])
	for panel in [_mission_panel, _status_panel]:
		if panel == null:
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = colors[0]
		style.border_color = colors[1]
		style.set_border_width_all(2)
		style.set_corner_radius_all(18)
		style.set_content_margin_all(8)
		panel.add_theme_stylebox_override("panel", style)
	_apply_hud_profile_layout()


func _apply_hud_profile_layout() -> void:
	if _moves_label == null or _lives_label == null or _reward_label == null:
		return
	var scale_factor := clampf(get_viewport_rect().size.x / 720.0, 0.72, 1.0)
	var sizes := {
		"investigation": [Vector2(124, 94), Vector2(0, 46), Vector2(0, 46)],
		"hazard": [Vector2(144, 94), Vector2(0, 46), Vector2(0, 46)],
		"rescue": [Vector2(116, 88), Vector2(0, 46), Vector2(0, 46)]
	}
	var profile_sizes: Array = sizes.get(_hud_profile, sizes["investigation"])
	_moves_label.get_parent().get_parent().custom_minimum_size = profile_sizes[0] * scale_factor
	_lives_label.get_parent().get_parent().custom_minimum_size = profile_sizes[1] * scale_factor
	_reward_label.get_parent().get_parent().custom_minimum_size = profile_sizes[2] * scale_factor


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
		var art_path := "res://assets/sprites/ui/hud/moves_counter_serif.png"
		match panel_name:
			"CoinCounter":
				art_path = "res://assets/sprites/ui/hud/coin_counter_serif.png"
			"LifeHearts":
				art_path = "res://assets/sprites/ui/hud/lives_counter_serif.png"
		panel_art.texture = _get_cropped_hud_art(panel_name, art_path)
		if panel_name in ["CoinCounter", "LifeHearts"]:
			panel_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			panel_art.stretch_mode = TextureRect.STRETCH_SCALE
		else:
			panel_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if panel_name not in ["CoinCounter", "LifeHearts"]:
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
		match panel_name:
			"CoinCounter", "LifeHearts":
				label.anchor_left = 0.58
				label.anchor_right = 0.96
				label.anchor_top = 0.28
				label.anchor_bottom = 0.76
			"MovesCounter":
				# Center the live move value inside the white inset of moves_counter_serif.png.
				label.anchor_left = 0.45
				label.anchor_right = 0.99
				label.anchor_top = 0.40
				label.anchor_bottom = 0.75
			_:
				label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
		match panel_name:
			"LifeHearts":
				label.add_theme_color_override("font_color", Color("#ffffff"))
				label.add_theme_color_override("font_outline_color", Color("#a51d4e"))
				label.add_theme_constant_override("outline_size", 2)
			"CoinCounter":
				label.add_theme_color_override("font_color", Color("#ffffff"))
				label.add_theme_color_override("font_outline_color", Color("#70420a"))
				label.add_theme_constant_override("outline_size", 2)
			_:
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
	var regions := {"StarReward": Rect2(250, 345, 1420, 570)}
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
	return _make_compact_hud_panel(parent, "MovesCounter", "30", Vector2(124, 94) * ui_scale, roundi(31 * ui_scale), Color("#38c8e5"))


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
		button.custom_minimum_size = Vector2(96, 88)
		button.texture_normal = ResourceManager.load_texture(icon_paths[kind])
		button.texture_hover = button.texture_normal
		button.texture_pressed = button.texture_normal
		button.pressed.connect(_on_booster_pressed.bind(kind))
		wrapper.add_child(button)
		var name_label := _make_label(kind.to_upper(), 14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wrapper.add_child(name_label)
		var count_label := _make_label("0", 26)
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


func _show_pause_menu(force_pause: bool = false) -> void:
	if _pause_layer != null:
		return
	if not force_pause and _tutorial_active and _tutorial_action != "pause":
		return
	_restore_tutorial_after_pause = force_pause and _tutorial_overlay != null and _tutorial_overlay.visible
	if _restore_tutorial_after_pause:
		_tutorial_overlay.hide()
	if _board != null:
		_board.cancel_pointer_gesture()
	if _tutorial_active and not force_pause:
		_tutorial_pause_open = true
		_tutorial_action = "pause_open"
		if _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()
	get_tree().paused = true
	var audio_manager := get_node_or_null("Managers/AudioManager")
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseMenuLayer"
	_pause_layer.layer = 12
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.12, 0.075, 0.035, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(minf(580.0, get_viewport_rect().size.x * 0.92), 700 if _tutorial_active else 620)
	frame.add_theme_stylebox_override("panel", _make_parchment_panel_style(78, 90))
	center.add_child(frame)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
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
	_apply_parchment_text(actions)
	if audio_manager != null:
		music.text = "MUSIC: OFF" if not audio_manager.is_music_enabled() else "MUSIC: ON"
		effects.text = "SOUND FX: OFF" if not audio_manager.is_sfx_enabled() else "SOUND FX: ON"


func _make_menu_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(350, 66)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_color_override("font_color", Color("#4b2d1a"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#d8b77b")
	normal.border_color = Color("#8b572b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ead09b")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#c89d5f")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#e9dfca")
	disabled.border_color = Color("#cbb994")
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_disabled_color", Color("#75634d"))
	button.pressed.connect(_play_ui_click)
	return button


func _make_parchment_panel_style(horizontal_margin: float, vertical_margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = ResourceManager.load_texture("res://assets/sprites/ui/wooden_dialogue_panel_cutout.png")
	style.texture_margin_left = 150
	style.texture_margin_right = 150
	style.texture_margin_top = 140
	style.texture_margin_bottom = 140
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


func _apply_parchment_text(parent: Node) -> void:
	for label in parent.find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", Color("#56351f"))
		label.add_theme_color_override("font_outline_color", Color("#f4e2bd"))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		label.add_theme_constant_override("outline_size", 1)


func _play_ui_click() -> void:
	SignalBus.play_sfx.emit("ui_click")


func _play_ui_confirm() -> void:
	SignalBus.play_sfx.emit("ui_confirm")


func _close_pause_menu() -> void:
	get_tree().paused = false
	if _restore_tutorial_after_pause and _tutorial_overlay != null:
		_tutorial_overlay.show()
	_restore_tutorial_after_pause = false
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
			"res://assets/sprites/characters/david_portrait_v2.png"
		)


func _show_case_file() -> void:
	if _case_file_layer != null or (_tutorial_active and _tutorial_action != "field_guide"):
		return
	if _idle_hint_timer != null:
		_idle_hint_timer.stop()
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
	veil.color = Color(0.12, 0.08, 0.04, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_case_file_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(minf(650.0, get_viewport_rect().size.x * 0.92), minf(1000.0, get_viewport_rect().size.y * 0.88))
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#fff8e8")
	card_style.border_color = Color("#c79b55")
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(26)
	card_style.set_content_margin_all(24)
	card_style.shadow_color = Color(0, 0, 0, 0.58)
	card_style.shadow_size = 16
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	card.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	var intro := HBoxContainer.new()
	intro.add_theme_constant_override("separation", 18)
	content.add_child(intro)
	var amara := TextureRect.new()
	amara.custom_minimum_size = Vector2(128, 144)
	amara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	amara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	amara.texture = ResourceManager.load_portrait("res://assets/sprites/characters/amara_police_portrait_cutout.png")
	intro.add_child(amara)
	var intro_copy := VBoxContainer.new()
	intro_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_child(intro_copy)
	var title := _make_label("AMARA'S CASE FILE", 24)
	intro_copy.add_child(title)
	var explanation := _make_label("Your discovered skills and decisions. Open a card to review exactly what you learned.", 17)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_copy.add_child(explanation)
	var discovered := CaseJournal.entries(_campaign_progress)
	if discovered.is_empty():
		var empty := _make_label("David's instructions will appear here as you uncover them. Read a lesson or practise a new skill to add it to this file.", 23)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(empty)
	else:
		content.add_child(_make_label("SKILLS YOU HAVE UNCOVERED", 23))
		for entry in discovered:
			var pages: Array = entry["facts"].values()
			_add_case_card(content, str(entry["title"]), "Discovered in level %d" % int(entry["level"]), "\n".join(pages), str(entry["illustration"]))
	var decisions: Dictionary = _campaign_progress.get_value("story_choices", "history", {})
	if not decisions.is_empty(): content.add_child(_make_label("YOUR STORY DECISIONS", 23))
	for story_id in decisions:
		var decision: Dictionary = decisions[story_id]
		_add_case_card(content, str(decision.get("label", "Decision")), "Story decision | " + str(story_id), str(decision.get("response", "")), "res://assets/sprites/props/evidence_briefcase.jpeg")
	for case_label in content.find_children("*", "Label", true, false):
		case_label.add_theme_color_override("font_color", Color("#4b3424"))
		case_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		case_label.add_theme_color_override("font_outline_color", Color("#f3e7ca"))
	var close := _make_story_action_button("BACK TO SEARCH", 240)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_case_file)
	layout.add_child(close)
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
	_reset_idle_hint_timer()


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


func _prepare_dialog(dialog: AcceptDialog) -> void:
	dialog.dialog_autowrap = true
	dialog.borderless = true
	dialog.transparent_bg = true
	dialog.add_theme_constant_override("buttons_min_width", 200)
	dialog.add_theme_constant_override("buttons_min_height", 72)
	dialog.add_theme_constant_override("buttons_separation", 18)
	dialog.about_to_popup.connect(func():
		if not dialog.has_meta("custom_heading"):
			dialog.dialog_text = dialog.title.to_upper() + ("\n\n" + dialog.dialog_text if not dialog.dialog_text.is_empty() else "")
	, CONNECT_ONE_SHOT)
	dialog.add_theme_font_override("title_font", DISPLAY_FONT)
	dialog.add_theme_font_size_override("title_font_size", 24)
	dialog.add_theme_constant_override("title_height", 48)
	dialog.add_theme_color_override("title_color", Color("#80502b"))
	var border := StyleBoxFlat.new()
	border.bg_color = Color("#f3e7ca")
	border.border_color = Color("#c79b55")
	border.set_border_width_all(2)
	border.set_corner_radius_all(18)
	border.content_margin_top = 14 if dialog.has_meta("custom_heading") else 48
	border.content_margin_left = 12
	border.content_margin_right = 12
	border.content_margin_bottom = 12
	dialog.add_theme_stylebox_override("embedded_border", border)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#fff8e8")
	panel.border_color = Color("#c79b55")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(20)
	panel.set_content_margin_all(24)
	panel.content_margin_top = 18 if dialog.has_meta("custom_heading") else 24
	dialog.add_theme_stylebox_override("panel", panel)
	var label := dialog.get_label()
	label.add_theme_font_override("font", DISPLAY_FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#4b3424"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons: Array[Button] = [dialog.get_ok_button()]
	if dialog is ConfirmationDialog:
		buttons.append(dialog.get_cancel_button())
	for button in buttons:
		button.custom_minimum_size = Vector2(200, 72)
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_font_override("font", DISPLAY_FONT)
		button.add_theme_color_override("font_color", Color("#4b2d1a"))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#d8b77b")
		style.border_color = Color("#8b572b")
		style.set_border_width_all(2)
		style.set_corner_radius_all(14)
		style.set_content_margin_all(12)
		button.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#ead09b")
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", style)
		var disabled := style.duplicate() as StyleBoxFlat
		disabled.bg_color = Color("#e9dfca")
		disabled.border_color = Color("#cbb994")
		button.add_theme_stylebox_override("disabled", disabled)
		button.add_theme_color_override("font_disabled_color", Color("#75634d"))


func _show_audio_settings(parent_layer: Node) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null or parent_layer == null:
		return
	var popup := AcceptDialog.new()
	popup.name = "AudioSettings"
	popup.set_meta("custom_heading", true)
	popup.title = "AUDIO SETTINGS"
	popup.ok_button_text = "DONE"
	_prepare_dialog(popup)
	popup.get_label().hide()
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	parent_layer.add_child(popup)
	if _tutorial_active and _tutorial_action == "settings" and _tutorial_overlay != null:
		_tutorial_overlay.hide_tip()
	var settings := VBoxContainer.new()
	settings.custom_minimum_size = Vector2(minf(480.0, get_viewport_rect().size.x * 0.78), 400)
	settings.add_theme_constant_override("separation", 12)
	var heading := _make_label("AUDIO SETTINGS", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("#f2ce7c"))
	settings.add_child(heading)
	for bus_kind in ["music", "sfx"]:
		var volume_label := Label.new()
		volume_label.add_theme_font_size_override("font_size", 23)
		volume_label.text = "Background music" if bus_kind == "music" else "Sound effects"
		settings.add_child(volume_label)
		var volume := HSlider.new()
		volume.name = "MusicVolume" if bus_kind == "music" else "EffectsVolume"
		volume.min_value = 0.0
		volume.max_value = 1.0
		volume.step = 0.01
		volume.custom_minimum_size.y = 48
		volume.value = audio_manager.get_music_volume() if bus_kind == "music" else audio_manager.get_sfx_volume()
		volume.value_changed.connect(_set_audio_volume.bind(bus_kind))
		settings.add_child(volume)
		var enabled := CheckButton.new()
		enabled.add_theme_font_size_override("font_size", 23)
		enabled.name = "MusicEnabled" if bus_kind == "music" else "EffectsEnabled"
		enabled.custom_minimum_size.y = 52
		enabled.button_pressed = audio_manager.is_music_enabled() if bus_kind == "music" else audio_manager.is_sfx_enabled()
		enabled.text = "Enabled" if enabled.button_pressed else "Disabled"
		enabled.toggled.connect(_set_audio_enabled.bind(bus_kind, enabled))
		settings.add_child(enabled)
	var legal_links := HBoxContainer.new()
	legal_links.add_theme_constant_override("separation", 10)
	for legal_page in [
		{"title": "PRIVACY POLICY", "path": "res://legal/privacy_policy.md"},
		{"title": "TERMS AND CONDITIONS", "path": "res://legal/terms_and_conditions.md"}
	]:
		var legal_button := _make_menu_button(str(legal_page["title"]))
		legal_button.custom_minimum_size = Vector2(0, 54)
		legal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		legal_button.add_theme_font_size_override("font_size", 15)
		legal_button.pressed.connect(_show_legal_document.bind(parent_layer, str(legal_page["title"]), str(legal_page["path"])))
		legal_links.add_child(legal_button)
	settings.add_child(legal_links)
	var account_button := _make_menu_button("ACCOUNT & COINS")
	account_button.disabled = _launch_layer == null and _campaign_layer == null
	account_button.tooltip_text = "Available from the title screen or campaign map."
	account_button.pressed.connect(func(): _account_panel.show_account())
	settings.add_child(account_button)
	var ad_provider := get_node_or_null("/root/AdProvider")
	if ad_provider != null and ad_provider.privacy_options_required():
		var ad_privacy := _make_menu_button("AD PRIVACY OPTIONS")
		ad_privacy.pressed.connect(ad_provider.show_privacy_options)
		settings.add_child(ad_privacy)
	popup.add_child(settings)
	if _tutorial_active and _tutorial_action == "settings":
		popup.confirmed.connect(_on_tutorial_settings_confirmed, CONNECT_ONE_SHOT)
	popup.confirmed.connect(popup.queue_free, CONNECT_ONE_SHOT)
	popup.canceled.connect(popup.queue_free, CONNECT_ONE_SHOT)
	popup.popup_centered_clamped(Vector2i(mini(580, int(get_viewport_rect().size.x * 0.9)), 520))


func _show_legal_document(parent_layer: Node, title: String, path: String) -> void:
	if parent_layer == null:
		return
	var markdown := FileAccess.get_file_as_string(path)
	if markdown.is_empty():
		DebugLogger.warning("Game: Could not load legal document -> " + path)
		return
	var viewport_size := get_viewport_rect().size
	var popup := AcceptDialog.new()
	popup.title = title
	popup.ok_button_text = "CLOSE"
	var online_url := "https://sbi.globalcreest.com/save-the-baby/privacy-policy" if path.ends_with("privacy_policy.md") else "https://sbi.globalcreest.com/save-the-baby/terms-and-conditions"
	popup.add_button("OPEN WEB PAGE", true, "open_legal_page")
	popup.custom_action.connect(func(action: String):
		if action == "open_legal_page":
			OS.shell_open(online_url)
	)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_prepare_dialog(popup)
	popup.get_label().hide()
	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.text = _legal_markdown_to_plain_text(markdown)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.scroll_active = true
	body.custom_minimum_size = Vector2(minf(500.0, viewport_size.x * 0.78), minf(600.0, viewport_size.y * 0.66))
	body.add_theme_color_override("default_color", Color("#fff3d5"))
	body.add_theme_font_size_override("normal_font_size", 17)
	popup.add_child(body)
	parent_layer.add_child(popup)
	popup.confirmed.connect(popup.queue_free, CONNECT_ONE_SHOT)
	popup.canceled.connect(popup.queue_free, CONNECT_ONE_SHOT)
	popup.popup_centered_clamped(Vector2i(mini(580, int(viewport_size.x * 0.9)), mini(760, int(viewport_size.y * 0.82))))


func _legal_markdown_to_plain_text(markdown: String) -> String:
	var lines := PackedStringArray()
	for raw_line in markdown.split("\n"):
		var line := str(raw_line).strip_edges()
		while line.begins_with("#"):
			line = line.substr(1).strip_edges()
		if line.begins_with("- "):
			line = String.chr(0x2022) + " " + line.substr(2)
		line = line.replace("**", "")
		lines.append(line)
	return "\n".join(lines)


func _on_tutorial_settings_confirmed() -> void:
	if not _tutorial_active or _tutorial_action != "settings":
		return
	_tutorial_action = "pause"
	_refresh_tutorial_controls()
	_show_tutorial_tip(
		"Music and sound effects each have separate controls. The gear also opens the pause menu so you can resume or leave the investigation.",
		_button_screen_rect(_pause_button),
		"DAVID",
		"res://assets/sprites/characters/david_portrait_v2.png"
	)


func _set_audio_volume(value: float, kind: String) -> void:
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager == null:
		return
	if kind == "music":
		audio_manager.set_music_volume(value)
	else:
		audio_manager.set_sfx_volume(value)


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
	font_size = maxi(20, font_size)
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
	_apply_opening_background_blur(background)
	var veil := ColorRect.new()
	veil.name = "StoryVeil"
	veil.color = Color(0.09, 0.07, 0.045, 0.25)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_layer.add_child(veil)
	var title := _make_label(str(_story.get("title", "The Night Ethan Vanished")), 24)
	title.anchor_left = 0.06
	title.anchor_right = 0.94
	title.anchor_top = 0.025
	title.anchor_bottom = 0.075
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 2
	title.add_theme_color_override("font_color", Color("#f4e4bd"))
	veil.add_child(title)
	_story_portrait = TextureRect.new()
	_position_story_portrait(0.15)
	_story_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_story_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_story_portrait.z_index = 1
	_story_portrait.texture = ResourceManager.load_portrait(str(_story.get("portrait", "")))
	veil.add_child(_story_portrait)
	var dialogue_panel := PanelContainer.new()
	_story_dialogue_panel = dialogue_panel
	dialogue_panel.name = "StoryDialoguePanel"
	dialogue_panel.anchor_left = 0.045
	dialogue_panel.anchor_right = 0.955
	dialogue_panel.anchor_top = 0.38
	dialogue_panel.anchor_bottom = 0.97
	dialogue_panel.offset_top = 58.0
	dialogue_panel.offset_bottom = 58.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#f4e4bd")
	panel_style.border_color = Color("#8b572b")
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(22)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 14
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	veil.add_child(dialogue_panel)
	for roll_y in [0.50, 0.95]:
		var scroll_roll := Panel.new()
		scroll_roll.anchor_left = 0.035
		scroll_roll.anchor_right = 0.965
		scroll_roll.anchor_top = roll_y
		scroll_roll.anchor_bottom = roll_y
		scroll_roll.offset_top = -7.0
		scroll_roll.offset_bottom = 9.0
		var roll_style := StyleBoxFlat.new()
		roll_style.bg_color = Color("#b27a3e")
		roll_style.border_color = Color("#70421f")
		roll_style.set_border_width_all(2)
		roll_style.set_corner_radius_all(8)
		scroll_roll.add_theme_stylebox_override("panel", roll_style)
		scroll_roll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.add_child(scroll_roll)
		if is_equal_approx(roll_y, 0.50):
			_story_scroll_top_roll = scroll_roll
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	dialogue_panel.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	_speaker_label = _make_label("", 23)
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speaker_label.add_theme_color_override("font_color", Color("#713d1e"))
	content.add_child(_speaker_label)
	_dialogue_label = _make_label("", 25)
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.custom_minimum_size = Vector2(0, 112)
	_dialogue_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_label.add_theme_color_override("font_color", Color("#4b2d1a"))
	_dialogue_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	content.add_child(_dialogue_label)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 8)
	content.add_child(_choice_box)
	var story_actions := HBoxContainer.new()
	story_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	story_actions.add_theme_constant_override("separation", 10)
	layout.add_child(story_actions)
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
	button.custom_minimum_size = Vector2(width, 64)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_color_override("font_color", Color("#4b2d1a"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#d8b77b")
	normal.border_color = Color("#8b572b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ead09b")
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
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
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
	SignalBus.play_sfx.emit("case_open")
	var story_sound := str(line.get("sfx", ""))
	if not story_sound.is_empty():
		SignalBus.play_sfx.emit(story_sound)
	_speaker_label.text = str(line.get("speaker", ""))
	_dialogue_label.text = str(line.get("text", ""))

	var portrait_path := str(line.get("portrait", ""))
	if portrait_path.is_empty():
		var portraits := {
			"Amara": "amara_and_ethan_portrait_cutout.png",
			"David": "david_portrait_v2.png",
			"Ethan": "ethan_portrait_cutout.png",
			"Victor": "victor_portrait_v2.png",
			"Detective Morris": "detective_portrait_cutout.png",
			"Unknown number": "victor_portrait_v2.png"
		}
		portrait_path = "res://assets/sprites/characters/" + str(portraits.get(str(line.get("speaker", "")), "amara_and_ethan_portrait_cutout.png"))
	if not portrait_path.is_empty():
		_story_portrait.texture = ResourceManager.load_portrait(portrait_path)
	_dialogue_label.visible_characters = 0
	_is_dialogue_typing = true
	_story_continue_button.disabled = false
	_story_continue_button.text = "TAP TO REVEAL"
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_label, "visible_characters", _dialogue_label.text.length(), maxf(0.65, _dialogue_label.text.length() * 0.028))
	_dialogue_tween.finished.connect(_finish_dialogue_typing)
	_last_typing_tick_character = 0
	_play_dialogue_typing_ticks()
	_story_previous_button.visible = int(_dialogue_id) > 0
	_story_portrait.modulate.a = 0.0
	_story_portrait.scale = Vector2(0.94, 0.94)
	var portrait_tween := create_tween().set_parallel(true)
	portrait_tween.tween_property(_story_portrait, "modulate:a", 1.0, 0.3)
	portrait_tween.tween_property(_story_portrait, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _position_story_portrait(top_ratio: float) -> void:
	if _story_portrait == null:
		return
	var viewport_size := get_viewport_rect().size
	var portrait_size := minf(236.0, minf(viewport_size.x * 0.50, viewport_size.y * 0.265))
	_story_portrait.position = Vector2((viewport_size.x - portrait_size) * 0.5, viewport_size.y * top_ratio)
	_story_portrait.size = Vector2.ONE * portrait_size


func _play_dialogue_typing_ticks() -> void:
	while _is_dialogue_typing and is_instance_valid(_dialogue_label):
		await get_tree().create_timer(0.075).timeout
		if not _is_dialogue_typing or not is_instance_valid(_dialogue_label):
			return
		var visible_count := _dialogue_label.visible_characters
		if visible_count >= 0 and visible_count - _last_typing_tick_character >= 2:
			_last_typing_tick_character = visible_count
			SignalBus.play_sfx.emit("dialogue_type")


func _present_route_choices(choices: Array) -> void:
	if not _choice_box.get_children().is_empty():
		return
	_speaker_label.text = "CHOOSE DAVID'S NEXT MOVE"
	_dialogue_label.text = "Each choice sets the team's approach. See the immediate consequence before you decide."
	_dialogue_label.custom_minimum_size.y = 58
	_dialogue_label.visible_characters = -1
	_is_dialogue_typing = false
	_story_continue_button.hide()
	_story_dialogue_panel.anchor_top = 0.36
	if is_instance_valid(_story_scroll_top_roll):
		_story_scroll_top_roll.anchor_top = 0.36
		_story_scroll_top_roll.anchor_bottom = 0.36
	_story_portrait.texture = ResourceManager.load_portrait("res://assets/sprites/characters/david_portrait_v2.png")
	_position_story_portrait(0.12)
	_story_skip_button.hide()
	_story_previous_button.hide()
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("label", "Choose")).to_upper()
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 21)
		button.add_theme_color_override("font_color", Color("#4b2d1a"))
		button.add_theme_color_override("font_hover_color", Color("#2d1d12"))
		button.add_theme_constant_override("h_separation", 12)
		var choice_style := StyleBoxFlat.new()
		choice_style.bg_color = Color("#e6cd98")
		choice_style.border_color = Color("#8b572b")
		choice_style.set_border_width_all(2)
		choice_style.set_corner_radius_all(14)
		choice_style.set_content_margin(SIDE_LEFT, 14)
		choice_style.set_content_margin(SIDE_RIGHT, 14)
		choice_style.set_content_margin(SIDE_TOP, 8)
		choice_style.set_content_margin(SIDE_BOTTOM, 8)
		button.add_theme_stylebox_override("normal", choice_style)
		var choice_hover := choice_style.duplicate() as StyleBoxFlat
		choice_hover.bg_color = Color("#f0dfb6")
		button.add_theme_stylebox_override("hover", choice_hover)
		button.pressed.connect(_preview_story_choice.bind(choice))
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
	if _pending_level_id != 0:
		if _story_manager != null:
			_story_manager.skip_story()
		return
	_campaign_progress.set_value("campaign", "route", "alone")
	_campaign_progress.set_value("campaign", "route_label", _chosen_route_label)
	_persist_campaign_progress()
	_show_campaign_map("alone")


func _on_route_selected(choice: Dictionary) -> void:
	for button in _choice_box.get_children():
		button.disabled = true
		button.queue_free()
	var route_id := str(choice.get("id", "alone"))
	if route_id == "police":
		_story_portrait.texture = ResourceManager.load_portrait("res://assets/sprites/characters/detective_portrait_cutout.png")
	elif route_id == "signal":
		_story_portrait.texture = ResourceManager.load_portrait("res://assets/sprites/characters/amara_police_portrait_cutout.png")
	else:
		_story_portrait.texture = ResourceManager.load_portrait("res://assets/sprites/characters/david_portrait_v2.png")
	_speaker_label.text = str(choice.get("speaker", choice.get("label", ""))).to_upper()
	_begin_story_typing(str(choice.get("response", "The search begins.")))
	var story_id := str(_story_manager.get_story_data().get("story_id", "opening_story"))
	var history: Dictionary = _campaign_progress.get_value("story_choices", "history", {})
	history[story_id] = choice.duplicate(true)
	_campaign_progress.set_value("story_choices", "history", history)
	_chosen_route_label = str(choice.get("label", "Continue the search"))
	_current_route_id = route_id
	_campaign_progress.set_value("campaign", "route", route_id)
	_campaign_progress.set_value("campaign", "route_label", _chosen_route_label)
	_persist_campaign_progress()
	_story_continue_button.show()
	if _story_continue_button.pressed.is_connected(_advance_story):
		_story_continue_button.pressed.disconnect(_advance_story)
	_story_continue_button.text = "CONTINUE"
	_pending_route_id = route_id
	_story_continue_button.pressed.connect(_advance_selected_story_choice.bind(route_id))
	set_meta("chosen_route", route_id)


func _advance_selected_story_choice(route_id: String) -> void:
	if _is_dialogue_typing:
		_finish_dialogue_typing()
		return
	if _pending_level_id == 0:
		if _story_manager != null:
			_story_manager.end_story()
		_show_campaign_map(route_id)
		return
	if _story_manager != null:
		_story_manager.goto_next_scene()


func _begin_story_typing(copy: String) -> void:
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
	_dialogue_label.text = copy
	SignalBus.play_sfx.emit("case_open")
	_dialogue_label.visible_characters = 0
	_is_dialogue_typing = true
	_story_continue_button.disabled = false
	_story_continue_button.text = "TAP TO REVEAL"
	_dialogue_tween = create_tween()
	_dialogue_tween.tween_property(_dialogue_label, "visible_characters", copy.length(), maxf(0.45, copy.length() * 0.028))
	_dialogue_tween.finished.connect(_finish_dialogue_typing)
	_last_typing_tick_character = 0
	_play_dialogue_typing_ticks()


func _show_campaign_map(route_id: String) -> void:
	_waiting_for_collection = false
	_turn_praise_rank = 0
	if is_instance_valid(_gameplay_effects): _gameplay_effects.clear()
	_current_route_id = route_id
	SignalBus.play_music.emit("suspense_opening")
	_is_dialogue_typing = false
	if _dialogue_tween != null and _dialogue_tween.is_running():
		_dialogue_tween.kill()
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
	if _campaign_coach_shown and bool(_campaign_progress.get_value("tutorials", "campaign_map_intro", false)):
		return
	if _campaign_map == null or not is_instance_valid(_campaign_map):
		return
	var target_rect: Rect2 = _campaign_map.get_level_screen_rect(1)
	if target_rect.size == Vector2.ZERO:
		return
	_campaign_coach_shown = true
	_campaign_progress.set_value("tutorials", "campaign_map_intro", true)
	CaseJournal.discover(_campaign_progress, "map", "Using the campaign map", "navigation", "Each marker opens an investigation; chapters show where the search moves next.", "res://assets/sprites/props/evidence_briefcase.jpeg", 1)
	_persist_campaign_progress()
	_tutorial_action = "campaign_map_intro"
	_show_tutorial_tip(
		"This is the campaign trail. Each marker opens an investigation; chapters show where the search moves next. Start with the glowing first case.",
		target_rect,
		"DAVID",
		"res://assets/sprites/characters/david_portrait_v2.png",
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
	if _story_manager != null:
		_story_manager.set_approach(_current_route_id)
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
	if _pending_level_id == -1 and story_id == _pending_story_id:
		_pending_level_id = 0
		_pending_story_id = ""
		_show_campaign_map(_current_route_id)
		return
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
	veil.color = Color(0.12, 0.075, 0.035, 0.76)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_briefing_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MissionCard"
	panel.custom_minimum_size = Vector2(minf(610.0, get_viewport_rect().size.x * 0.92), minf(1020.0, get_viewport_rect().size.y * 0.94))
	panel.add_theme_stylebox_override("panel", _make_parchment_panel_style(82, 100))
	center.add_child(panel)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(panel, "modulate:a", 1.0, 0.28)
	entrance.tween_property(panel, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	panel.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	var level_id := int(level_data.get("level_id", 1))
	var level_title := _make_label("INVESTIGATION %02d" % level_id, 18)
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(level_title)
	var title := _make_label(str(level_data.get("name", "The First Clue")), 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(220, 210)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_paths := {
		"police": "res://assets/sprites/characters/detective_portrait_cutout.png",
		"signal": "res://assets/sprites/characters/amara_police_portrait_cutout.png",
		"alone": "res://assets/sprites/characters/david_portrait_v2.png"
	}
	portrait.texture = ResourceManager.load_portrait(str(portrait_paths.get(route_id, portrait_paths["alone"])))
	content.add_child(portrait)
	var route_label := _make_label("APPROACH | " + _chosen_route_label.to_upper(), 17)
	route_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_label)
	var description := _make_label(str(level_data.get("description", "")), 19)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 0
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(description)
	var route_briefings := {
		"police": "Detective Morris is securing the house while you gather evidence for his team.",
		"signal": "Amara is tracing Victor's phone. The clues you collect will narrow her search.",
		"alone": "David is following the trail alone. Every clue must point him toward Ethan."
	}
	var route_detail := _make_label(str(route_briefings.get(route_id, route_briefings["alone"])), 17)
	route_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail.custom_minimum_size.x = 0
	route_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(route_detail)
	route_detail.hide()

	var objective := _get_primary_objective(level_data)
	var objective_panel := PanelContainer.new()
	var objective_style := StyleBoxFlat.new()
	objective_style.bg_color = Color("#f4e4bd")
	objective_style.border_color = Color("#b58a52")
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
	difficulty_label.add_theme_color_override("font_color", Color("#80502b"))
	content.add_child(difficulty_label)
	var moves := _make_label("MATCH THE GOAL | %d MOVES" % moves_total, 18)
	moves.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(moves)
	_apply_parchment_text(content)
	var play := _make_menu_button("PLAY")
	play.custom_minimum_size = Vector2(350, 82)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_play_ui_confirm)
	play.pressed.connect(_begin_level.bind(route_id), CONNECT_ONE_SHOT)
	layout.add_child(play)


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
			var target := str(objective.get("target", "CLUES")).replace("_", " ").to_upper()
			match str(objective.get("type", "")).to_upper():
				"DESTROY_OBSTACLES":
					var obstacle_name := target if not target.is_empty() else "OBSTACLE"
					if amount != 1 and not obstacle_name.ends_with("S"):
						obstacle_name += "S"
					summaries.append("CLEAR %d %s" % [amount, obstacle_name])
				"UNLOCK_DOORS":
					summaries.append("OPEN %d DOORS" % amount)
				"DEFUSE_BOMBS":
					summaries.append("DEFUSE %d BOMBS" % amount)
				"REACH_SCORE":
					summaries.append("REACH %d POINTS" % amount)
				"RESCUE_BABY":
					summaries.append("RESCUE ETHAN")
				"SURVIVE":
					summaries.append("SURVIVE THE ATTACK")
				"CLEAR_ALL_JELLY":
					summaries.append("CLEAR ALL JELLY")
				_:
					var plural := target + "S"
					if target == "KEY":
						plural = "KEYS"
					elif target == "PHONE":
						plural = "PHONES"
					elif target == "FINGERPRINT":
						plural = "FINGERPRINTS"
					elif target == "CLOCK":
						plural = "TIMESTAMPS"
					summaries.append("COLLECT %d %s" % [amount, plural])
	if summaries.is_empty():
		return str(level_data.get("description", "COMPLETE THE INVESTIGATION")).to_upper()
	var summary := ""
	for entry in summaries:
		if not summary.is_empty():
			summary += "  |  "
		summary += entry
	return summary


func _objective_icon_path(target: String) -> String:
	var icons := {
		"KEY": "key_objective_icon.jpeg",
		"PHONE": "phone_evidence_icon.svg",
		"FINGERPRINT": "fingerprint_evidence_icon.jpeg",
		"RECORDER": "recorder_evidence_icon.jpeg",
		"CLOCK": "timer_objective_icon.jpeg",
		"CHAIN": "chain_obstacle_icon.jpeg",
		"LOCK": "locked_padlock_obstacle_icon.jpeg",
		"BOMB": "missile_obstacle_icon.jpeg",
		"MISSILE": "missile_obstacle_icon.jpeg",
		"ELECTRIC_TRAP": "electric_trap_obstacle_icon.jpeg"
	}
	var normalized := target.to_upper()
	if ["CHAIN", "LOCK", "BOMB", "MISSILE", "ELECTRIC_TRAP"].has(normalized):
		return "res://assets/sprites/obstacles/" + str(icons[normalized])
	return "res://assets/sprites/powerups/tiles/" + str(icons.get(normalized, "evidence_document_icon.jpeg"))


func _begin_level(_route_id: String) -> void:
	_waiting_for_collection = false
	_turn_praise_rank = 0
	if is_instance_valid(_gameplay_effects): _gameplay_effects.clear()
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
	var level_music := str(level_data.get("audio", {}).get("music", ""))
	SignalBus.play_music.emit(level_music if not level_music.is_empty() else "suspense_opening")
	var audio_manager := get_node_or_null("Managers/AudioManager")
	if audio_manager != null:
		audio_manager.resume_music()
	_current_level_id = int(level_data.get("level_id", 1))
	_current_route_id = _route_id
	var objective := _get_primary_objective(level_data)
	_evidence_count = 0
	_objective_complete_sound_played = false
	_story_objective_sound_pending = false
	_evidence_goal = int(objective.get("amount", 10))
	var obstacle_items: Array = level_data.get("obstacles", {}).get("items", [])
	_objective_target = str(objective.get("target", "KEY")).to_upper()
	_objective_type = str(objective.get("type", "COLLECT_ITEMS")).to_upper()
	_hud_profile = _resolve_hud_profile(level_data)
	_apply_hud_profile_style()
	if _objective_target_icon != null:
		_objective_target_icon.texture = ResourceManager.load_texture(_objective_icon_path(_objective_target))
	_obstacles_goal = obstacle_items.size() if _objective_type != "DESTROY_OBSTACLES" else 0
	_obstacles_cleared = 0
	if _level_number_label != null:
		_level_number_label.text = "%03d" % _current_level_id
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
		(entry["count"] as Label).text = str(int(_booster_inventory[kind]))
		(entry["button"] as BaseButton).disabled = false
	_start_academy_lesson(level_data)
	_refresh_tutorial_controls()
	_reset_idle_hint_timer()
	if level_manager != null:
		level_manager.start_level()
	if _board != null:
		if not (_tutorial_active and ["academy_lesson", "explain_booster", "booster_select", "explain_character_tiles"].has(_tutorial_action)):
			_board.unlock()
	_reset_idle_hint_timer()
	var active_hud := get_node_or_null("HUD") as CanvasLayer
	if active_hud != null:
		active_hud.visible = true


func _on_board_created() -> void:
	var created_board: Board = _board_manager.get_board()
	if created_board == null or created_board == _board:
		return
	_ad_attempt += 1
	_current_level_points = 0
	_clear_bonus_coins = 0
	_ad_revived = false
	_result_ad_shown = false
	_board = created_board
	_board.moves_changed.connect(_on_moves_changed)
	_board.player_interacted.connect(_on_board_player_interacted)
	_board.match_collected.connect(_on_tiles_matched)
	_board.move_rejected.connect(_on_move_rejected)
	_board.turn_resolved.connect(_on_board_turn_resolved)
	_board.special_created.connect(_on_special_created)
	_board.special_activated.connect(_on_special_activated)
	_board.powerup_blast.connect(_on_powerup_blast)
	_board.rocket_combo.connect(_on_rocket_combo)
	_board.tile_burst.connect(_on_tile_burst)
	_board.booster_used.connect(_on_booster_used)
	_board.obstacles_cleared.connect(_on_obstacles_cleared)
	_board.obstacle_damaged.connect(_on_obstacle_damaged)
	_board.tiles_matched_with_cells.connect(_animate_matched_tiles)
	_board.lock()
	_on_moves_changed(_board.get_remaining_moves())


func _on_moves_changed(remaining: int) -> void:
	_moves_remaining = remaining
	_moves_label.text = str(remaining)


func _on_board_player_interacted() -> void:
	_reset_idle_hint_timer()
	if _hint_label != null and _hint_label.text.begins_with("TRY THIS SWAP"):
		_hint_label.text = "MATCH %s | PLAN YOUR NEXT MOVE" % _objective_target.replace("_", " ")


func _reset_idle_hint_timer() -> void:
	if _idle_hint_timer == null:
		return
	_idle_hint_timer.stop()
	if _board != null:
		_board.clear_suggested_move_hint()
	if _tutorial_active or _board == null or _board.is_locked() or _result_layer != null or _case_file_layer != null or _pause_layer != null or _story_layer != null or _briefing_layer != null or _launch_layer != null or (_ads != null and _ads.busy):
		return
	_idle_hint_timer.start()


func _show_idle_move_hint() -> void:
	if _board == null or _board.is_locked() or _tutorial_active or _result_layer != null or _case_file_layer != null or _pause_layer != null or (_ads != null and _ads.busy):
		return
	var target_type := int(Constants.TileType.get(_objective_target, -1)) if _objective_type == "COLLECT_ITEMS" else -1
	var suggested := _board.find_valid_swap_for_type(target_type) if target_type >= 0 else []
	if suggested.is_empty():
		suggested = _board.find_valid_swap()
	if suggested.size() != 2:
		return
	_board.show_suggested_move_hint(suggested)
	_hint_label.text = "TRY THIS SWAP | MATCH %s" % _objective_target.replace("_", " ")
	_hint_label.show()
	_idle_hint_timer.start()


func _on_board_shuffled() -> void:
	if _board == null or _result_layer != null or _launch_layer != null or _campaign_layer != null:
		return
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return
	var center := _board.get_cell_screen_rect(Vector2i(_board.get_width() / 2, _board.get_height() / 2)).get_center()
	var notice := Label.new()
	notice.name = "NoMoveNotice"
	notice.text = "NO MOVE!"
	notice.position = center - Vector2(130, 34)
	notice.size = Vector2(260, 68)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.add_theme_font_override("font", DISPLAY_FONT)
	notice.add_theme_font_size_override("font_size", 38)
	notice.add_theme_color_override("font_color", Color("#fff1b6"))
	notice.add_theme_color_override("font_outline_color", Color("#26394b"))
	notice.add_theme_constant_override("outline_size", 7)
	notice.scale = Vector2(0.65, 0.65)
	notice.pivot_offset = notice.size * 0.5
	hud.add_child(notice)
	var pop := create_tween().set_parallel(true)
	pop.tween_property(notice, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(notice, "modulate:a", 0.0, 0.68).set_delay(0.18)
	pop.chain().tween_callback(notice.queue_free)


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
		var base_size := roundi(29 * clampf(get_viewport_rect().size.x / 720.0, 0.72, 1.0))
		var digit_count := str(value).length()
		_reward_label.add_theme_font_size_override("font_size", maxi(roundi(20 * clampf(get_viewport_rect().size.x / 720.0, 0.72, 1.0)), base_size - maxi(0, digit_count - 4) * 4))


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
	if kind == "ethan" and _economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS:
		_show_shop_notice("Ethan assists are full. Use one before collecting another.")
		return
	var item_id := "ethan_assist" if kind == "ethan" else "%s_booster" % kind
	var item: Dictionary = _economy_manager.get_shop_item(item_id)
	if item.is_empty():
		return
	var amount := int(item.get("amount", 1))
	var cost := int(item.get("price", 0))
	var dialog := ConfirmationDialog.new()
	dialog.title = "FIELD SUPPLIES"
	_prepare_dialog(dialog)
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
		purchase.free()
	)
	var supplies_ad := dialog.add_button("Watch ad: +1 %s" % kind.capitalize(), false, "reward")
	if kind == "ethan" and _economy_manager.get_ethan_count() >= EthanInventory.MAX_ASSISTS:
		supplies_ad.disabled = true
	_bind_ad_button(supplies_ad, "supply_" + kind)
	dialog.custom_action.connect(func(action: String):
		if action == "reward":
			layer.queue_free()
			_request_reward("supply_" + kind, func():
				if kind == "ethan":
					_economy_manager.add_ethan(1)
				else:
					_economy_manager.add_booster(kind, 1)
				_save_inventory_progress()
			)
	)
	dialog.confirmed.connect(layer.queue_free, CONNECT_ONE_SHOT)
	dialog.canceled.connect(layer.queue_free, CONNECT_ONE_SHOT)
	dialog.popup_centered_clamped(Vector2i(mini(560, int(get_viewport_rect().size.x * 0.9)), 300))


func _update_objective_hud() -> void:
	if _objective_label == null:
		return
	var progress_text := "%d / %d" % [mini(_evidence_count, _evidence_goal), _evidence_goal]
	if _obstacles_goal > 0:
		progress_text += "  %s  %d / %d BLOCKERS" % [String.chr(0x2022), _obstacles_cleared, _obstacles_goal]
	_objective_label.text = progress_text
	if _blocker_label != null:
		_blocker_label.text = ""


func _mission_objectives_complete() -> bool:
	return _evidence_count >= _evidence_goal and _obstacles_cleared >= _obstacles_goal


func _effects() -> GameplayEffects:
	if not is_instance_valid(_gameplay_effects):
		_gameplay_effects = GameplayEffects.new()
		add_child(_gameplay_effects)
		_gameplay_effects.collections_finished.connect(func():
			if _waiting_for_collection: _evaluate_level_end())
	return _gameplay_effects


func _animate_matched_tiles(tile_types: Array, cells: Array) -> void:
	var target_enum := int(Constants.TileType.get(_objective_target, -1))
	var groups: Dictionary = {}
	for index in range(mini(tile_types.size(),cells.size())):
		var kind := int(tile_types[index])
		if kind != target_enum and not [int(Constants.TileType.ETHAN),int(Constants.TileType.DETECTIVE),int(Constants.TileType.VICTOR)].has(kind): continue
		if kind != target_enum:
			if kind == int(Constants.TileType.ETHAN) and groups.get(kind, []).size() >= int(_last_character_rewards.get("ethan",0)): continue
			if kind == int(Constants.TileType.DETECTIVE) and groups.get(kind, []).size() >= int(_last_character_rewards.get("detective",0)): continue
			if kind == int(Constants.TileType.VICTOR) and groups.get(kind, []).size() >= int(_last_character_rewards.get("victor",0)): continue
		if not groups.has(kind): groups[kind] = []
		groups[kind].append(_board.get_cell_screen_rect(cells[index]).get_center())
	for kind in groups:
		var target: Control = _objective_target_icon if _objective_target_icon != null else _objective_label
		var texture_path := _objective_icon_path(_objective_target)
		var value := 1
		if kind == int(Constants.TileType.VICTOR):
			target = _reward_label
			texture_path = "res://assets/sprites/ui/icons/coins_icon.png"
			value = 10
		elif kind in [int(Constants.TileType.ETHAN),int(Constants.TileType.DETECTIVE)]:
			target = _booster_buttons["ethan"]["button"]
			texture_path = "res://assets/sprites/characters/%s" % ("ethan_portrait_cutout.png" if kind == int(Constants.TileType.ETHAN) else "detective_portrait_cutout.png")
		var origins: Array[Vector2] = []
		for point in groups[kind]: origins.append(point)
		var arrival_sound := "objective_collected" if kind == target_enum else ""
		if kind == int(Constants.TileType.VICTOR):
			arrival_sound = "clue_collected"
		elif kind in [int(Constants.TileType.ETHAN),int(Constants.TileType.DETECTIVE)]:
			arrival_sound = "rescue_assist"
		_effects().collect(ResourceManager.load_texture(texture_path),origins,target,value,arrival_sound)
	if tile_types.size() >= 5 and not cells.is_empty():
		_effects().burst(_board.get_cell_screen_rect(cells[cells.size()/2]).get_center(),75,Color("#ffe082"))


func _on_tile_burst(cell: Vector2i) -> void:
	if _board == null or not _board.is_inside(cell):
		return
	var tile: Tile = _board.get_tile(cell)
	var tint := Color("#ffd45b")
	if tile != null:
		var colors := [Color("#ff8a65"),Color("#55d8ff"),Color("#e68aff"),Color("#9ff078"),Color("#ffd45b"),Color("#ff78a5")]
		tint = colors[posmod(int(tile.get_tile_type()),colors.size())]
	_effects().tile_burst(_board.get_cell_screen_rect(cell).get_center(),tint)
	_effects().haptic(10,0.24)
	SignalBus.play_sfx.emit("tile_burst")


func _on_rocket_combo(origins: Array, cells: Array) -> void:
	if _board == null:
		return
	var launch_points: Array[Vector2] = []
	var hit_points: Array[Vector2] = []
	for cell in origins:
		launch_points.append(_board.get_cell_screen_rect(cell).get_center())
	for cell in cells:
		hit_points.append(_board.get_cell_screen_rect(cell).get_center())
	_effects().rocket_salvo(launch_points,hit_points)
	_effects().haptic(58,0.88)
	_board.play_celebration_shake(1.8)


func _on_powerup_blast(kind: String, cell: Vector2i) -> void:
	var first := _board.get_cell_screen_rect(Vector2i.ZERO)
	var last := _board.get_cell_screen_rect(Vector2i(_board.get_width()-1,_board.get_height()-1))
	_effects().powerup("bomb" if kind == "ethan" else kind,_board.get_cell_screen_rect(cell).get_center(),first.merge(last))
	_board.play_celebration_shake(1.6 if kind in ["bomb","thunder","ethan"] else 1.2)
	_effects().haptic(38,0.68)


func _persist_campaign_progress() -> void:
	_campaign_progress.set_value("campaign", "highest_unlocked_level", _highest_unlocked_level)
	_campaign_progress.set_value("campaign", "completed_levels", _completed_levels)
	if _economy_manager != null:
		_campaign_progress.set_value("campaign", "life_regeneration_time", _economy_manager.get_life_clock())
	var error := CampaignProgressStore.write(_campaign_progress, CAMPAIGN_PROGRESS_PATH)
	if error != OK:
		push_error("Could not save campaign progress: %s" % error_string(error))
	elif is_instance_valid(_account_panel):
		_account_panel.local_changed()


func _on_tiles_matched(tile_types: Array) -> void:
	_current_level_points += tile_types.size() * 100
	_effects().haptic(30 if tile_types.size() >= 6 else 17,0.56 if tile_types.size() >= 6 else 0.34)
	var feedback_caption := ""
	var feedback_sound := ""
	var shake_board := false
	var character_rewards := {"ethan": 0, "detective": 0, "victor": 0}
	var target_enum := int(Constants.TileType.get(_objective_target, -1))
	for tile_type in tile_types:
		if _objective_type == "COLLECT_ITEMS" and int(tile_type) == target_enum:
			_evidence_count += 1
		if not _suppress_character_rewards_this_turn and _economy_manager != null:
			if int(tile_type) in [int(Constants.TileType.ETHAN), int(Constants.TileType.DETECTIVE)]:
				var assists_before := _economy_manager.get_ethan_count()
				_economy_manager.add_ethan(1)
				if _economy_manager.get_ethan_count() > assists_before:
					var character_id := "ethan" if int(tile_type) == int(Constants.TileType.ETHAN) else "detective"
					character_rewards[character_id] = int(character_rewards[character_id]) + 1
			elif int(tile_type) == int(Constants.TileType.VICTOR):
				_economy_manager.add_coins(10)
				character_rewards["victor"] = int(character_rewards["victor"]) + 1
	var reward_notices: Array[String] = []
	var ethan_matches := int(character_rewards["ethan"])
	var detective_matches := int(character_rewards["detective"])
	var victor_matches := int(character_rewards["victor"])
	if ethan_matches + detective_matches + victor_matches > 0:
		_discover_journal_fact("characters", 0)
	_last_character_rewards = character_rewards.duplicate()
	if ethan_matches + detective_matches > 0:
		_discover_journal_fact("characters", 1)
	if victor_matches > 0:
		_discover_journal_fact("characters", 2)
	if ethan_matches > 0:
		reward_notices.append("ETHAN +%d RESCUE ASSIST%s" % [ethan_matches, "" if ethan_matches == 1 else "S"])
	if detective_matches > 0:
		reward_notices.append("DETECTIVE +%d RESCUE ASSIST%s" % [detective_matches, "" if detective_matches == 1 else "S"])
	if victor_matches > 0:
		reward_notices.append("VICTOR +%d ETHAN COINS" % (victor_matches * 10))
	var special_reward_text := " | ".join(reward_notices)
	SignalBus.play_sfx.emit("tile_match")
	var rank := 0
	if tile_types.size() >= 12:
		feedback_caption = "WONDERFUL!"
		feedback_sound = "match_wonderful"
		rank = 3
		shake_board = true
	elif tile_types.size() >= 9:
		feedback_caption = "EXCELLENT!"
		feedback_sound = "match_great"
		rank = 2
		shake_board = true
	elif tile_types.size() >= 6:
		feedback_caption = "NICE!"
		feedback_sound = "match_nice"
		rank = 1
		shake_board = true
	if ethan_matches > 0:
		feedback_caption = "THANK YOU!"
		feedback_sound = "match_thank_you"
		rank = 4
	if rank <= _turn_praise_rank:
		feedback_caption = ""
	else:
		_turn_praise_rank = rank
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
	if not sound_id.is_empty(): SignalBus.play_sfx.emit(sound_id)
	_hint_label.text = caption
	_hint_label.add_theme_color_override("font_color", Color("#ffe279"))
	_effects().praise(caption,DISPLAY_FONT)
	if shake_board and _board != null:
		var intensity := 0.9 if caption == "NICE!" else (1.5 if caption == "WONDERFUL!" else 1.2)
		_board.play_celebration_shake(intensity)


func _on_special_created(kind: String) -> void:
	_discover_journal_fact(kind, 0)
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
	_discover_journal_fact(kind, 1)


func _on_board_turn_resolved() -> void:
	_turn_praise_rank = 0
	_suppress_character_rewards_this_turn = false
	_discover_journal_fact("first_moves", 1)
	_discover_journal_fact("first_moves", 2)
	if _tutorial_skip_pending:
		_tutorial_skip_pending = false
		_finish_tutorial()
		return
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
	if _result_layer == null:
		_reset_idle_hint_timer()


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
		"res://assets/sprites/characters/david_portrait_v2.png",
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
	_show_tutorial_tip(message, target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)


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
	_show_tutorial_tip("Four in a line made a rocket. Swap it with the glowing neighbor to fire its row and column. Special pieces activate through a swap.", target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_v2.png")


func _show_tutorial_special_result() -> void:
	_tutorial_action = "explain_special_result"
	if _board != null:
		_board.lock()
	_show_tutorial_tip("The rocket cleared its row and column in one move. Creating special pieces also earns Ethan Coins; Amara sends a matching booster after the configured milestone. Use specials to clear a blocked path or reach mission evidence.", _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)


func _show_tutorial_booster_result() -> void:
	_tutorial_action = "explain_booster_result"
	if _board != null:
		_board.lock()
	var consequence := "The rocket clears its row and column."
	match _tutorial_booster_kind:
		"bomb": consequence = "The bomb clears pieces around the target."
		"thunder": consequence = "Thunder clears every piece of the chosen type."
	_show_tutorial_tip("%s The booster count dropped by one; boosters are limited. Save the next one for a useful obstacle or hard-to-reach clue." % consequence, _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)


func _on_tutorial_acknowledged() -> void:
	if _tutorial_action == "campaign_map_intro":
		_tutorial_action = ""
		if _tutorial_overlay != null:
			_tutorial_overlay.hide_tip()
		return
	if not _tutorial_active:
		return
	if _tutorial_action == "academy_lesson":
		_complete_academy_lesson()
		var pending := _academy_pending_level
		_academy_pending_level = {}
		_start_practice_tutorial(pending)
		if not _tutorial_active:
			_board.unlock()
	elif _tutorial_action == "mission_briefing":
		_finish_tutorial()
	elif _tutorial_action == "explain_booster":
		_show_tutorial_booster_selection()
	elif _tutorial_action == "explain_goal":
		_finish_tutorial()
	elif _tutorial_action == "explain_obstacle":
		_finish_tutorial()
	elif _tutorial_action == "explain_special_created":
		_show_tutorial_special_created()
	elif _tutorial_action == "explain_character_tiles":
		_finish_tutorial()
	elif _tutorial_action == "explain_special_result" or _tutorial_action == "explain_booster_result":
		_finish_tutorial()


func _show_tutorial_booster_selection() -> void:
	if _economy_manager != null and _economy_manager.get_booster_count(_tutorial_booster_kind) <= 0:
		_economy_manager.add_booster(_tutorial_booster_kind, 1)
	_tutorial_action = "booster_select"
	_board.lock()
	_refresh_tutorial_controls()
	_show_tutorial_tip(
		"Tap the glowing %s booster below. Then choose the marked piece on the board." % _tutorial_booster_kind,
		_button_screen_rect(_booster_buttons[_tutorial_booster_kind]["button"]),
		"DAVID",
		"res://assets/sprites/characters/david_portrait_v2.png"
	)


func _finish_tutorial() -> void:
	_tutorial_skip_pending = false
	if _tutorial_active and _current_level_id > 0:
		_campaign_progress.set_value("tutorials", str(_current_level_id), true)
		_persist_campaign_progress()
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
		_board.cancel_booster_mode()
		_board.unlock()
	_selected_booster = ""
	_reset_idle_hint_timer()
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
		var level_manager := get_node_or_null("Managers/LevelManager")
		var data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
		var unlocked: bool = data.get("settings", {}).get("available_boosters", []).has(kind)
		button.get_parent().visible = unlocked
		button.disabled = not tutorial_allows or not unlocked


func _on_booster_pressed(kind: String) -> void:
	if _tutorial_active and not (_tutorial_action == "booster_select" and kind == _tutorial_booster_kind):
		return
	if _board == null:
		return
	if _booster_confirm != null or (_board.is_locked() and not _tutorial_active):
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
		_board.unlock()
		_board.set_booster_mode(kind)
		var target_rect := _board.get_cell_screen_rect(_tutorial_target_cell)
		var message := "Tap the glowing piece to use %s. This clears nearby evidence." % kind.capitalize()
		_hint_label.text = "BOOSTER TRAINING | TARGET THE GLOWING PIECE"
		_show_tutorial_tip(message, target_rect, "DAVID", "res://assets/sprites/characters/david_portrait_v2.png")
		_refresh_tutorial_controls()
		return
	_show_booster_confirmation(kind)


func _show_booster_confirmation(kind: String) -> void:
	_board.lock()
	var descriptions := {
		"rocket": "Choose a tile. Rocket clears its full row and column.",
		"bomb": "Choose a tile. Bomb clears the tiles around it.",
		"thunder": "Choose a tile. Thunder clears every tile of that type.",
		"ethan": "Choose a tile. Ethan clears a 3 by 3 rescue area. You can hold up to two assists."
	}
	_booster_confirm_layer = CanvasLayer.new()
	_booster_confirm_layer.name = "BoosterConfirmationLayer"
	_booster_confirm_layer.layer = 38
	_booster_confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_booster_confirm_layer)
	_booster_confirm = IllustratedPopup.new()
	_booster_confirm.name = "BoosterUseConfirmation"
	_booster_confirm_layer.add_child(_booster_confirm)
	var booster_art := "res://assets/sprites/characters/ethan_portrait_cutout.png" if kind == "ethan" else "res://assets/sprites/powerups/%s_powerup_icon.jpeg" % kind
	_booster_confirm.set_card_context(
		"%s BOOSTER | %d AVAILABLE" % [kind.capitalize(), int(_booster_inventory.get(kind, 0))],
		booster_art,
		"USE BOOSTER"
	)
	_booster_confirm.acknowledged.connect(_confirm_booster_use.bind(kind), CONNECT_ONE_SHOT)
	_booster_confirm.skipped.connect(_cancel_booster_dialog, CONNECT_ONE_SHOT)
	_booster_confirm.show_tip(
		"%s\n\nUsing a booster spends one move. Choose USE BOOSTER, then tap a board tile. Tap X to cancel without spending it." % descriptions.get(kind, "Choose a board tile to use this booster."),
		Rect2(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true
	)


func _confirm_booster_use(kind: String) -> void:
	_booster_confirm = null
	if is_instance_valid(_booster_confirm_layer):
		_booster_confirm_layer.queue_free()
	_booster_confirm_layer = null
	_selected_booster = kind
	_board.unlock()
	_board.set_booster_mode(kind)
	_hint_label.text = "TAP A TILE TO USE %s  |  TAP THE BOOSTER AGAIN TO CANCEL" % kind.to_upper()


func _cancel_booster_dialog() -> void:
	_booster_confirm = null
	if is_instance_valid(_booster_confirm_layer):
		_booster_confirm_layer.queue_free()
	_booster_confirm_layer = null
	_selected_booster = ""
	if _board != null:
		_board.unlock()


func _cancel_booster_targeting() -> void:
	if _board != null:
		_board.cancel_booster_mode()
		_board.unlock()
	_selected_booster = ""
	_hint_label.text = "BOOSTER CANCELLED | No item was used."


func _on_booster_used(kind: String) -> void:
	_suppress_character_rewards_this_turn = true
	_discover_journal_fact("characters" if kind == "ethan" else kind, 3 if kind == "ethan" else 2)
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
		_tutorial_overlay.skipped.connect(_skip_tutorial)
		_tutorial_overlay.page_presented.connect(_on_tutorial_page_presented)
		layer.add_child(_tutorial_overlay)
	var board_action := ["guided_swap", "activate_special", "booster_target"].has(_tutorial_action)
	var tap_action := board_action or ["campaign_map_intro", "settings", "pause", "field_guide", "booster_select"].has(_tutorial_action)
	_tutorial_overlay.show_tip(message, target_rect, speaker, portrait_path if not portrait_path.is_empty() else "res://assets/sprites/characters/david_portrait_v2.png", needs_acknowledgement, board_action, tap_action)


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
	if destroyed:
		SignalBus.play_sfx.emit("obstacle_destroyed")
		_board.play_celebration_shake(1.4)
	var obstacle: Obstacle = _board._obstacles.get(cell)
	if is_instance_valid(obstacle):
		var kinds := {Constants.ObstacleType.CHAIN: ["chain", 1], Constants.ObstacleType.LOCK: ["lock", 0], Constants.ObstacleType.BOMB: ["hazard", 1], Constants.ObstacleType.MISSILE: ["hazard", 1], Constants.ObstacleType.ELECTRIC_TRAP: ["electric", 1]}
		var source: Array = kinds.get(obstacle.get_obstacle_type(), [])
		if not source.is_empty(): _discover_journal_fact(str(source[0]), int(source[1]))
	var rect := _board.get_cell_screen_rect(cell)
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null or rect.size == Vector2.ZERO:
		return
	var center := rect.get_center()
	var icon_path := ""
	if is_instance_valid(obstacle):
		var type_name := str(Constants.ObstacleType.keys()[int(obstacle.get_obstacle_type())])
		icon_path = _objective_icon_path(type_name)
	_effects().obstacle_debris(center,ResourceManager.load_texture(icon_path) if not icon_path.is_empty() else null,destroyed)
	var health := Label.new()
	health.text = "BROKEN!" if destroyed else "%d LEFT" % remaining_health
	health.position = center - Vector2(75, 2)
	health.size = Vector2(150, 44)
	health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health.add_theme_font_size_override("font_size", 26)
	health.add_theme_color_override("font_color", Color("#fff2c7"))
	health.add_theme_color_override("font_outline_color", Color("#182c43"))
	health.add_theme_constant_override("outline_size", 3)
	hud.add_child(health)
	var fly := create_tween().set_parallel(true)
	fly.tween_property(health, "position", health.position - Vector2(0, 80), 0.70)
	fly.tween_property(health, "modulate:a", 0.0, 0.70)
	fly.finished.connect(health.queue_free)


func _play_objective_complete_sound() -> void:
	if _objective_complete_sound_played:
		return
	_objective_complete_sound_played = true
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	_story_objective_sound_pending = _is_story_final_level(level_data)


func _evaluate_level_end() -> void:
	if _result_layer != null or _result_in_progress or _current_level_id <= 0:
		return
	if (_mission_objectives_complete() or _moves_remaining <= 0) and is_instance_valid(_gameplay_effects) and _gameplay_effects.pending_collections > 0:
		_waiting_for_collection = true
		_board.lock()
		return
	_waiting_for_collection = false
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
	if _result_in_progress or _result_layer != null:
		return
	_result_in_progress = true
	if _board != null:
		_board.lock()
	_tutorial_active = false
	_tutorial_action = ""
	if won:
		_result_stars_earned = _calculate_level_stars()
		await _play_board_clear_celebration()
	var first_clear := false
	if won:
		first_clear = _record_level_completion()
	_result_layer = CanvasLayer.new()
	_result_layer.name = "LevelResult"
	_result_layer.layer = 22
	_result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_result_layer)
	var veil := ColorRect.new()
	veil.color = Color(0.08, 0.06, 0.035, 0.76)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(minf(520.0, get_viewport_rect().size.x * 0.90), 430)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#f4e4bd")
	card_style.border_color = Color("#8b572b")
	card_style.set_border_width_all(5)
	card_style.set_corner_radius_all(12)
	card_style.set_content_margin_all(24)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	card.scale = Vector2(0.72, 0.72)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	var heading := _make_label("CASE WON!" if won else "THE TRAIL WENT COLD", 32)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("#633718"))
	content.add_child(heading)
	var result_manager := get_node_or_null("Managers/LevelManager")
	var result_data: Dictionary = result_manager.get_level_data() if result_manager != null else {}
	if won and _is_story_final_level(result_data):
		var story_complete := _make_label("STORY OBJECTIVE COMPLETE!", 22)
		story_complete.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story_complete.add_theme_color_override("font_color", Color("#8b572b"))
		content.add_child(story_complete)
	var reward_info: Dictionary = result_data.get("rewards", {})
	var has_next_level := JsonLoader.file_exists("res://levels/level%03d.json" % (_current_level_id + 1))
	var has_after_story := not str(result_data.get("story", {}).get("after_level", "")).is_empty()
	if won:
		var trophy := TextureRect.new()
		var trophy_atlas := AtlasTexture.new()
		trophy_atlas.atlas = ResourceManager.load_texture("res://assets/sprites/ui/screens/victory_screen.png")
		trophy_atlas.region = Rect2(118, 88, 132, 102)
		trophy.texture = trophy_atlas
		trophy.custom_minimum_size = Vector2(108, 68)
		trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trophy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(trophy)
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.add_theme_constant_override("separation", 12)
		content.add_child(stars)
		for star_index in 3:
			var star_mark := String.chr(0x2605) if star_index < _result_stars_earned else String.chr(0x2606)
			var star := _make_label(star_mark, 46)
			star.add_theme_color_override("font_color", Color("#b67b22"))
			stars.add_child(star)
			star.scale = Vector2(0.08, 0.08)
			var stamp := create_tween()
			stamp.tween_interval(0.20 + star_index * 0.52)
			stamp.tween_property(star, "scale", Vector2(1.30, 0.80), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			stamp.tween_property(star, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			if star_index < _result_stars_earned:
				stamp.tween_callback(_play_star_stamp_feedback)
	var coins_earned := (int(reward_info.get("coins", 0)) + _clear_bonus_coins) if first_clear else 0
	var total_coins := _economy_manager.get_coins() if _economy_manager != null else 0
	var total_points := int(_campaign_progress.get_value("campaign", "total_points", 0))
	var detail_text: String
	if not won:
		detail_text = "The remaining moves ran out. You lost one life. Try again or visit the Life Shop."
	else:
		detail_text = "LEVEL POINTS: %d\nTOTAL POINTS: %d\nCOINS: +%d   TOTAL: %d\nSTARS EARNED: %d" % [_current_level_points, total_points, coins_earned, total_coins, _result_stars_earned]
		if has_next_level:
			detail_text += "\nCase %03d is now unlocked." % mini(_highest_unlocked_level, _current_level_id + 1)
		else:
			detail_text += "\nDavid's search continues as new investigations are added."
	var detail := _make_label(detail_text, 17)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_color_override("font_color", Color("#4b2d1a"))
	detail.add_theme_color_override("font_outline_color", Color("#b89564"))
	detail.add_theme_color_override("font_shadow_color", Color("#c9ad7b"))
	detail.add_theme_constant_override("outline_size", 1)
	detail.add_theme_constant_override("shadow_offset_x", 1)
	detail.add_theme_constant_override("shadow_offset_y", 1)
	detail.add_theme_font_size_override("font_size", 16)
	content.add_child(detail)
	if won:
		var next := _make_menu_button("NEXT CHAPTER" if has_after_story else ("NEXT LEVEL" if has_next_level else "RETURN TO MAP"))
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
	if won and first_clear and int(reward_info.get("coins", 0)) > 0:
		_add_reward_offer(content, "Watch an ad: +%d bonus coins" % int(reward_info.get("coins", 0)), "completion", func():
			_economy_manager.add_coins(int(reward_info.get("coins", 0)))
			_persist_campaign_progress()
		)
	elif not won and not _ad_revived:
		_add_reward_offer(content, "Watch an ad: +5 moves and restore lost life", "continue", _reward_continue)
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


func _calculate_level_stars() -> int:
	var level_manager := get_node_or_null("Managers/LevelManager")
	var data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	var total_moves := maxi(1, int(data.get("moves", {}).get("total", 1)))
	var remaining_ratio := float(_moves_remaining) / float(total_moves)
	if remaining_ratio >= 0.50:
		return 3
	if remaining_ratio >= 0.20:
		return 2
	return 1


func _play_star_stamp_feedback() -> void:
	SignalBus.play_sfx.emit("case_close")
	_effects().haptic(52, 0.68)


func _play_board_clear_celebration() -> void:
	if _board == null:
		return
	var remaining_specials: Array[Tile] = []
	for value in _board._grid.values():
		var tile := value as Tile
		if is_instance_valid(tile) and tile.has_powerup():
			remaining_specials.append(tile)
	_current_level_points += remaining_specials.size() * 250
	_clear_bonus_coins = remaining_specials.size() * 5
	for special in remaining_specials:
		SignalBus.play_sfx.emit("powerup_activate")
		var blast := create_tween()
		blast.tween_property(special, "scale", Vector2(1.55, 0.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		blast.tween_property(special, "scale", Vector2.ZERO, 0.12)
		await blast.finished
	for value in _board._grid.values():
		var tile := value as Tile
		if is_instance_valid(tile):
			var leave := create_tween()
			leave.tween_property(tile, "position:y", tile.position.y + get_viewport_rect().size.y, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			leave.parallel().tween_property(tile, "rotation", randf_range(-0.24, 0.24), 0.34)
	await get_tree().create_timer(0.38).timeout
	_board.clear()
	_board.queue_redraw()


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
	_prepare_dialog(purchase_dialog)
	purchase_dialog.title = "LIFE SHOP"
	purchase_dialog.dialog_text = "Refill %d lives for %d Ethan Coins? You have %d." % [amount, price, _economy_manager.get_coins()]
	var seconds := _economy_manager.seconds_until_next_life()
	purchase_dialog.dialog_text += "\n\nA free life returns in %02d:%02d." % [seconds / 60, seconds % 60]
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
		purchase.free()
	)
	var life_ad := purchase_dialog.add_button("Watch ad: +1 life", false, "reward")
	_bind_ad_button(life_ad, "life")
	purchase_dialog.custom_action.connect(func(action: String):
		if action == "reward":
			shop_layer.queue_free()
			_request_reward("life", func():
				_economy_manager.add_life(1)
				_persist_campaign_progress()
				if _result_layer != null:
					_return_to_campaign_map()
			)
	)
	purchase_dialog.confirmed.connect(shop_layer.queue_free, CONNECT_ONE_SHOT)
	purchase_dialog.canceled.connect(shop_layer.queue_free, CONNECT_ONE_SHOT)
	purchase_dialog.popup_centered_clamped(Vector2i(mini(560, int(get_viewport_rect().size.x * 0.9)), 350))


func _show_shop_notice(message: String) -> void:
	var notice := AcceptDialog.new()
	_prepare_dialog(notice)
	notice.title = "ETHAN COINS"
	notice.dialog_text = message
	var notice_layer := CanvasLayer.new()
	notice_layer.layer = 25
	notice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(notice_layer)
	notice_layer.add_child(notice)
	notice.confirmed.connect(notice_layer.queue_free)
	notice.canceled.connect(notice_layer.queue_free)
	notice.popup_centered_clamped(Vector2i(mini(540, int(get_viewport_rect().size.x * 0.9)), 250))


func _is_story_final_level(level_data: Dictionary) -> bool:
	var metadata: Dictionary = level_data.get("metadata", {})
	return int(metadata.get("chapter_end_level", 0)) == int(level_data.get("level_id", -1))


func _dismiss_level_result() -> void:
	if _result_layer != null and is_instance_valid(_result_layer):
		_result_layer.queue_free()
	_result_layer = null
	_result_in_progress = false


func _next_level_after_win() -> void:
	if _ads.busy:
		return
	await _show_result_ad()
	var level_manager := get_node_or_null("Managers/LevelManager")
	var level_data: Dictionary = level_manager.get_level_data() if level_manager != null else {}
	var after_story := str(level_data.get("story", {}).get("after_level", ""))
	var next_id := _current_level_id + 1
	var path := "res://levels/level%03d.json" % next_id
	_dismiss_level_result()
	get_tree().paused = false
	if not after_story.is_empty():
		_pending_level_id = -1
		_pending_story_id = after_story
		_start_campaign_story(after_story)
		return
	if JsonLoader.file_exists(path):
		_on_campaign_level_selected(next_id, _current_route_id)
	else:
		_show_campaign_map(_current_route_id)


func _retry_current_level() -> void:
	if _ads.busy:
		return
	await _show_result_ad()
	var level_id := _current_level_id
	_dismiss_level_result()
	get_tree().paused = false
	_on_campaign_level_selected(level_id, _current_route_id)


func _return_to_campaign_map() -> void:
	if _ads.busy:
		return
	await _show_result_ad()
	_dismiss_level_result()
	get_tree().paused = false
	_show_campaign_map(_current_route_id)


func _load_campaign_progress() -> void:
	var error := CampaignProgressStore.read(_campaign_progress, CAMPAIGN_PROGRESS_PATH)
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
	var stars_earned := _result_stars_earned
	var old_stars := int(_completed_levels.get(str(_current_level_id), 0))
	_completed_levels[str(_current_level_id)] = maxi(stars_earned, old_stars)
	var star_delta := maxi(0, stars_earned - old_stars)
	_highest_unlocked_level = maxi(_highest_unlocked_level, _current_level_id + 1)
	var point_records_value: Variant = _campaign_progress.get_value("campaign", "level_points", {})
	var point_records: Dictionary = point_records_value if typeof(point_records_value) == TYPE_DICTIONARY else {}
	point_records[str(_current_level_id)] = maxi(_current_level_points, int(point_records.get(str(_current_level_id), 0)))
	_campaign_progress.set_value("campaign", "level_points", point_records)
	var total_points := 0
	for points in point_records.values():
		total_points += int(points)
	_campaign_progress.set_value("campaign", "total_points", total_points)
	if old_stars == 0:
		if _reward_manager != null:
			var level_rewards: Array = _reward_manager.calculate_level_rewards({"level": _current_level_id})
			for reward in level_rewards:
				if int(reward.get("type", -1)) == int(Constants.RewardType.STARS):
					reward["amount"] = stars_earned
			_reward_manager.clear_pending_rewards()
			_reward_manager.grant_rewards(level_rewards)
		elif _economy_manager != null:
			_economy_manager.add_coins(int(rewards.get("coins", 0)))
			_economy_manager.add_stars(star_delta)
		if _economy_manager != null and _clear_bonus_coins > 0:
			_economy_manager.add_coins(_clear_bonus_coins)
	elif star_delta > 0 and _economy_manager != null:
		_economy_manager.add_stars(star_delta)
	if star_delta > 0:
		_campaign_progress.set_value("campaign", "total_stars", int(_campaign_progress.get_value("campaign", "total_stars", 0)) + star_delta)
	_persist_campaign_progress()
	return old_stars == 0


func _academy_lessons() -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://configs/academy.json"))
	return data.get("lessons", []) if data is Dictionary else []


func _start_academy_lesson(level_data: Dictionary) -> void:
	_academy_pending_level = {}
	_academy_lesson_id = ""
	for lesson in _academy_lessons():
		if int(lesson["level"]) != _current_level_id:
			continue
		if bool(_campaign_progress.get_value("academy_completed", str(lesson["id"]), false)):
			break
		# Mark on presentation so retrying or relaunching never forces the lesson again.
		# The complete pages are archived in the case file for optional review.
		_campaign_progress.set_value("academy_completed", str(lesson["id"]), true)
		# The Academy already teaches this case. Archive its short practice prompt
		# so it can be reviewed, but do not put the player through both tutorials.
		_campaign_progress.set_value("tutorials", str(_current_level_id), true)
		var level_tutorial: Dictionary = level_data.get("tutorial", {})
		var level_steps: Array = level_tutorial.get("steps", [])
		if not level_steps.is_empty():
			var practice_message := str(level_steps[0].get("message", ""))
			if not practice_message.is_empty():
				CaseJournal.discover(
					_campaign_progress,
					"field_briefing_%03d" % _current_level_id,
					"Case %03d field briefing" % _current_level_id,
					"briefing",
					practice_message,
					"res://assets/sprites/props/evidence_briefcase.jpeg",
					_current_level_id
				)
		var journal_pages: Array = lesson.get("journal_pages", [])
		var lesson_pages: Array = lesson.get("pages", [])
		for page_index in range(mini(journal_pages.size(), lesson_pages.size())):
			var fact: Dictionary = journal_pages[page_index]
			if fact.is_empty(): continue
			CaseJournal.discover(
				_campaign_progress,
				str(fact.get("id", "")),
				str(fact.get("title", lesson.get("title", "Case lesson"))),
				str(fact.get("fact", "")),
				str(lesson_pages[page_index]),
				str(fact.get("illustration", "")),
				_current_level_id
			)
		_persist_campaign_progress()
		_academy_pending_level = level_data
		_academy_lesson_id = str(lesson["id"])
		_tutorial_active = true
		_tutorial_action = "academy_lesson"
		_board.lock()
		_show_tutorial_tip("\n".join(lesson["pages"]), _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)
		return
	_start_practice_tutorial(level_data)


func _skip_tutorial() -> void:
	if _tutorial_action == "campaign_map_intro":
		_on_tutorial_acknowledged()
		return
	_complete_academy_lesson()
	_academy_pending_level = {}
	if _board != null and _board.is_locked() and ["guided_swap", "activate_special", "booster_resolving"].has(_tutorial_action):
		_tutorial_skip_pending = true
		_tutorial_overlay.hide_tip()
		return
	_finish_tutorial()


func _complete_academy_lesson() -> void:
	if not _academy_lesson_id.is_empty():
		_campaign_progress.set_value("academy_completed", _academy_lesson_id, true)
		_persist_campaign_progress()
	_academy_lesson_id = ""


func _add_case_card(parent: VBoxContainer, title: String, subtitle: String, detail: String, illustration: String = "") -> void:
	var button := _make_story_action_button(title, 0)
	button.custom_minimum_size.y = 76
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text = subtitle
	button.pressed.connect(_show_detail.bind(title, detail, Callable(), "", illustration))
	parent.add_child(button)


func _preview_story_choice(choice: Dictionary) -> void:
	_show_detail("Are you sure?", "%s?\n\n%s" % [str(choice.get("label", "Choose this approach")), str(choice.get("impact", ""))], _select_route.bind(choice), "CHOOSE THIS APPROACH")


func _show_detail(title: String, body: String, confirm: Callable = Callable(), confirm_text: String = "", illustration: String = "") -> void:
	if is_instance_valid(_detail_layer):
		return
	_detail_layer = CanvasLayer.new()
	_detail_layer.name = "CaseDetail"
	_detail_layer.layer = 35
	add_child(_detail_layer)
	var card := IllustratedPopup.new()
	card.name = "IllustratedDetailCard"
	_detail_layer.add_child(card)
	card.set_card_context(title, illustration, "CONFIRM" if confirm.is_valid() else "BACK")
	card.skipped.connect(_close_detail)
	card.acknowledged.connect(func():
		_close_detail()
		if confirm.is_valid(): confirm.call())
	card.show_tip(body, Rect2(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)


func _close_detail() -> void:
	if is_instance_valid(_detail_layer):
		_detail_layer.queue_free()
	_detail_layer = null


func _start_practice_tutorial(level_data: Dictionary) -> void:
	var obstacle_items: Array = level_data.get("obstacles", {}).get("items", [])
	var tutorial: Dictionary = level_data.get("tutorial", {})
	var raw_steps: Variant = tutorial.get("steps", [])
	var tutorial_steps: Array = raw_steps if raw_steps is Array else []
	if bool(tutorial.get("enabled", false)) and not tutorial_steps.is_empty() and not bool(_campaign_progress.get_value("tutorials", str(_current_level_id), false)):
		# Save before showing: interrupted tutorials stay in the case file and do
		# not force players through the same opening flow on their next attempt.
		_campaign_progress.set_value("tutorials", str(_current_level_id), true)
		var field_tip := str(tutorial_steps[0].get("message", ""))
		if not field_tip.is_empty():
			CaseJournal.discover(
				_campaign_progress,
				"field_briefing_%03d" % _current_level_id,
				"Case %03d field briefing" % _current_level_id,
				"briefing",
				field_tip,
				"res://assets/sprites/props/evidence_briefcase.jpeg",
				_current_level_id
			)
		_persist_campaign_progress()
		_tutorial_active = true
		_tutorial_mechanic = str(tutorial_steps[0].get("mechanic", ""))
		_tutorial_pause_open = false
		_tutorial_booster_kind = str(tutorial_steps[0].get("booster", "")).to_lower()
		if _tutorial_mechanic == "mission_briefing":
			_tutorial_action = "mission_briefing"
			if _board != null:
				_board.lock()
			_hint_label.text = "CASE %03d | DAVID'S FIELD BRIEFING" % _current_level_id
			_refresh_tutorial_controls()
			_show_tutorial_tip(field_tip, _objective_label.get_global_rect(), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png", true)
		elif _tutorial_mechanic == "character_tiles":
			_tutorial_action = "explain_character_tiles"
			if _board != null:
				_board.lock()
			_hint_label.text = "NEW MATCH PIECES | CHARACTER REWARDS"
			_refresh_tutorial_controls()
			_show_tutorial_tip(
				str(tutorial_steps[0].get("message", "Match character portraits for their rewards.")),
				_button_screen_rect(_booster_buttons["ethan"]["button"]),
				"DAVID",
				"",
				true
			)
		elif not _tutorial_booster_kind.is_empty():
			_tutorial_action = "explain_booster"
			_board.lock()
			_hint_label.text = "BOOSTER TRAINING | " + _tutorial_booster_kind.to_upper()
			_refresh_tutorial_controls()
			_show_tutorial_tip(
				str(tutorial_steps[0].get("message", "Learn to use your new booster.")) + " A practice booster is provided if your supply is empty. Tap Continue to try it.",
				_objective_label.get_global_rect(),
				"DAVID",
				"res://assets/sprites/characters/david_portrait_v2.png",
				true
			)
		else:
			_tutorial_action = "guided_swap"
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
				_show_tutorial_tip(base_message, first_rect.merge(second_rect), "DAVID", "res://assets/sprites/characters/david_portrait_v2.png")
	else:
		_tutorial_active = false
		_tutorial_action = ""
		if _tutorial_overlay != null: _tutorial_overlay.hide_tip()
		var mission_hint := "MATCH %s | COLLECT %d CLUES IN %d MOVES" % [
			_objective_target.replace("_", " "), _evidence_goal, int(level_data.get("moves", {}).get("total", 0))
		]
		if _obstacles_goal > 0:
			mission_hint += " | CLEAR %d BLOCKERS" % _obstacles_goal
		_hint_label.text = mission_hint
	_refresh_tutorial_controls()
	if not _tutorial_active or _tutorial_action == "guided_swap":
		_board.unlock()




func _on_tutorial_page_presented(index: int, message: String) -> void:
	if _tutorial_action == "academy_lesson":
		for lesson in _academy_lessons():
			if str(lesson["id"]) != _academy_lesson_id: continue
			var journal_pages: Array = lesson.get("journal_pages", [])
			if index >= journal_pages.size(): return
			var fact: Dictionary = journal_pages[index]
			if not fact.is_empty() and CaseJournal.discover(_campaign_progress, str(fact["id"]), str(fact["title"]), str(fact["fact"]), message, str(fact["illustration"]), _current_level_id):
				_persist_campaign_progress()
			return
	elif _tutorial_action == "campaign_map_intro":
		if CaseJournal.discover(_campaign_progress, "map", "Using the campaign map", "navigation", message, "res://assets/sprites/props/evidence_briefcase.jpeg", _current_level_id):
			_persist_campaign_progress()


func _discover_journal_fact(lesson_id: String, page: int) -> void:
	for lesson in _academy_lessons():
		if str(lesson["id"]) != lesson_id: continue
		var sources: Array = lesson.get("journal_pages", [])
		if page >= sources.size(): return
		var fact: Dictionary = sources[page]
		if fact.is_empty(): return
		if CaseJournal.discover(_campaign_progress, str(fact["id"]), str(fact["title"]), str(fact["fact"]), str(lesson["pages"][page]), str(fact["illustration"]), _current_level_id):
			_persist_campaign_progress()
		return


func _ad_key(placement: String) -> String:
	return "%d:%s" % [_ad_attempt, placement]


func _add_reward_offer(parent: Control, label: String, placement: String, reward: Callable) -> void:
	var button := _make_menu_button(label)
	var refresh := func():
		if is_instance_valid(button):
			button.disabled = not _ads.available("rewarded") or _ads.claimed(_ad_key(placement))
			button.tooltip_text = "Reward granted only after completing the ad." if not button.disabled else "No ad available right now."
	_ads.availability_changed.connect(refresh)
	button.tree_exiting.connect(func():
		if _ads.availability_changed.is_connected(refresh):
			_ads.availability_changed.disconnect(refresh)
	)
	button.pressed.connect(func(): _request_reward(placement, reward))
	parent.add_child(button)
	refresh.call()


func _request_reward(placement: String, reward: Callable) -> void:
	if _ads.busy:
		return
	var ad_board := _board
	var was_locked := ad_board == null or ad_board.is_locked()
	if ad_board != null:
		ad_board.lock()
	# Connect before show: a provider may report failure synchronously.
	var receive := func(earned: bool):
		if is_instance_valid(ad_board) and not was_locked:
			ad_board.unlock()
		if earned:
			_result_ad_shown = true
			reward.call()
		else:
			_show_shop_notice("Ad not completed. No reward was used. Please try again later.")
	_ads.finished.connect(receive, CONNECT_ONE_SHOT)
	if not _ads.show_ad("rewarded", _ad_key(placement)):
		_ads.finished.disconnect(receive)
		if is_instance_valid(ad_board) and not was_locked:
			ad_board.unlock()
		_show_shop_notice("No ad available right now. Please try again later.")


func _show_result_ad() -> void:
	if _result_layer == null or _result_ad_shown:
		return
	_result_ad_shown = true
	if _ads.available("interstitial"):
		_ads.show_ad("interstitial", "level_end")
		if _ads.busy:
			await _ads.finished


func _reward_continue() -> void:
	if _result_layer == null or _board == null or _ad_revived:
		return
	_ad_revived = true
	_economy_manager.add_life(1)
	_board.add_reward_moves(5)
	_dismiss_level_result()
	get_tree().paused = false
	_board.unlock()
	_persist_campaign_progress()


func _bind_ad_button(button: Button, placement: String) -> void:
	var refresh := func():
		if is_instance_valid(button):
			button.disabled = not _ads.available("rewarded") or _ads.claimed(_ad_key(placement))
	_ads.availability_changed.connect(refresh)
	button.tree_exiting.connect(func():
		if _ads.availability_changed.is_connected(refresh):
			_ads.availability_changed.disconnect(refresh)
	)
	refresh.call()
