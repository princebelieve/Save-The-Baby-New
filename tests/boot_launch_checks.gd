extends Node

func _ready() -> void:
	var boot := preload("res://scenes/boot/Boot.tscn").instantiate()
	add_child(boot)
	await RenderingServer.frame_post_draw
	assert(boot.get_node_or_null("CompanySplashLogo") != null)
	assert(boot.get_node_or_null("GlossyBrandBackground") != null)
	assert(boot._game_scene == null)
	await get_tree().create_timer(4.5).timeout
	assert(not is_instance_valid(boot))
	assert(get_tree().current_scene is Game)
	print("Boot launch checks passed: company logo first, then game scene")
	get_tree().quit()
