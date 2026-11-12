extends Control
signal continued
var details: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MobileGameUI.background(self)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var paper := MobileGameUI.card(center, Color("#fff4d9"))
	paper.name = "ChapterIntroduction"
	paper.custom_minimum_size.x = minf(660, get_viewport_rect().size.x - 36)
	var content := MobileGameUI.column(paper, 14)
	MobileGameUI.display_label(content, str(details.get("season_title", "THE SEARCH CONTINUES")), 36, MobileGameUI.PURPLE)
	MobileGameUI.display_label(content, "CHAPTER %d" % int(details.get("chapter_id", 1)), 36)
	MobileGameUI.display_label(content, str(details.get("chapter_title", "A new lead")), 52)
	var art := MobileGameUI.image(content, str(details.get("art", "")), Vector2(560, minf(340, get_viewport_rect().size.y * 0.28)))
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MobileGameUI.display_label(content, "A new place. Another chance to bring Ethan home.", 40)
	MobileGameUI.button(content, "Follow the lead", continued.emit, MobileGameUI.PINK).name = "EnterChapter"
	MobileGameUI.button(content, "Skip introduction", continued.emit, MobileGameUI.PURPLE)
	MobileGameUI.present(paper, "screen_map")
