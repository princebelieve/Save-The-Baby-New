extends HBoxContainer

func configure(taunt: String, font: Font) -> void:
	$VictorTaunt.text = taunt
	$VictorTaunt.add_theme_font_override("font",font)
