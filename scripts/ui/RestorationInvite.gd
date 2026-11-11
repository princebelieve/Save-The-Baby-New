extends Control
## Live lettering and art share one phone-sized composition; preview/practice
## never creates an attempt or consumes the player's timed opportunity.
signal started
signal dismissed
signal practiced

var details: Dictionary = {}
var _primary: Button
var _hero: PanelContainer
var _copy: Label
var _practice_first := -1
var _practice_buttons: Array[Button] = []
var _practice_pieces := [1, 0]
var _practice_solved := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.12, 0.18, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := MobileGameUI.card(center, Color("#fff4d9"))
	card.name = "EarnedChallengeCard"
	card.custom_minimum_size.x = minf(660.0, get_viewport_rect().size.x - 36.0)
	var content := MobileGameUI.column(card, 12)
	var ribbon := MobileGameUI.card(content, MobileGameUI.PURPLE)
	MobileGameUI.display_label(ribbon, "A clue worth restoring!", 48, Color.WHITE)
	_hero = MobileGameUI.card(content, Color("#e2edf0"))
	_hero.custom_minimum_size.y = minf(280.0, get_viewport_rect().size.y * 0.25)
	var picture := MobileGameUI.image(_hero, str(details.get("portrait", "")), Vector2(240, 220))
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_copy = MobileGameUI.display_label(content, "Restore the picture. Win supplies for your next case.", 40)
	var prizes := HBoxContainer.new()
	prizes.alignment = BoxContainer.ALIGNMENT_CENTER
	prizes.add_theme_constant_override("separation", 18)
	content.add_child(prizes)
	var kind := str(details.get("booster", ""))
	if not kind.is_empty():
		MobileGameUI.image(prizes, "res://assets/sprites/powerups/" + kind + "_powerup_icon.jpeg", Vector2(76, 76))
		MobileGameUI.display_label(prizes, "+1 " + kind.capitalize(), 40)
	MobileGameUI.image(prizes, MobileGameUI.COIN, Vector2(54, 54))
	MobileGameUI.display_label(prizes, "+%d" % int(details.get("coins", 15)), 40)
	MobileGameUI.display_label(content, "%d pieces  •  %d:%02d" % [int(details.get("pieces", 9)), int(details.get("seconds", 120)) / 60, int(details.get("seconds", 120)) % 60], 36, Color("#5f5268"))
	_primary = MobileGameUI.button(content, "Try one swap" if bool(details.get("teach", true)) else "Start challenge", _start, MobileGameUI.PINK)
	_primary.name = "StartRestoration"
	MobileGameUI.button(content, "Continue investigation", dismissed.emit, MobileGameUI.TEAL).name = "DeclineRestoration"
	if not bool(details.get("teach", true)):
		MobileGameUI.button(content, "How to play", show_practice, MobileGameUI.PURPLE)
	SignalBus.play_sfx.emit("case_open")
	card.modulate.a = 0.0
	card.create_tween().tween_property(card, "modulate:a", 1.0, 0.18)

func _start() -> void:
	if bool(details.get("teach", true)) and not _practice_solved:
		show_practice()
		return
	_primary.disabled = true
	started.emit()

func show_practice() -> void:
	if not _practice_buttons.is_empty(): return
	for child in _hero.get_children():
		_hero.remove_child(child)
		child.queue_free()
	_copy.text = "Tap both fragments to swap them. No timer yet!"
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_hero.add_child(row)
	for index in 2:
		var fragment := Button.new()
		fragment.name = "PracticeFragment%d" % index
		fragment.custom_minimum_size = Vector2(140, 220)
		fragment.expand_icon = true
		fragment.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fragment.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := MobileGameUI.style(Color("#334064"), 8)
			style.set_content_margin_all(0)
			fragment.add_theme_stylebox_override(state, style)
		fragment.pressed.connect(_swap_practice.bind(index))
		row.add_child(fragment)
		_practice_buttons.append(fragment)
	_refresh_practice()
	_primary.text = "Swap the fragments"
	_primary.disabled = true

func _swap_practice(index: int) -> void:
	if _practice_solved: return
	if _practice_first == -1:
		_practice_first = index
		_practice_buttons[index].modulate = Color("#ffdb78")
		return
	if _practice_first == index:
		_practice_first = -1
		_practice_buttons[index].modulate = Color.WHITE
		return
	_practice_pieces = [0, 1]
	_refresh_practice()
	_practice_solved = true
	details.teach = false
	_copy.text = "That's it! The timer starts when you tap Start."
	_primary.text = "Start challenge"
	_primary.disabled = false
	SignalBus.play_sfx.emit("ui_confirm")
	practiced.emit()

func _refresh_practice() -> void:
	var image := ResourceManager.load_texture(str(details.get("portrait", "")))
	if image == null: return
	for index in 2:
		var fragment := AtlasTexture.new()
		fragment.atlas = image
		fragment.region = Rect2(Vector2(image.get_width() * 0.5 * _practice_pieces[index], 0), Vector2(image.get_width() * 0.5, image.get_height()))
		_practice_buttons[index].icon = fragment
		_practice_buttons[index].modulate = Color.WHITE
