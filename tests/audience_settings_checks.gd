extends SceneTree

class TestAudience extends "res://scripts/ads/AudienceSettings.gd":
	var config := ConfigFile.new()
	func _settings() -> ConfigFile: return config

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var audience := TestAudience.new()
	root.add_child(audience)
	for group in audience.GROUPS:
		audience.config.set_value("audience", "group", group)
		assert(audience.start_session() == group)
		assert(audience.age_group == group)
		assert(audience.get_child_count() == 0)
	for group in ["invalid", ""]:
		audience.config.set_value("audience", "group", group)
		assert(audience.start_session() == "unknown")
		assert(audience.get_child_count() == 0, "Do not add an age questionnaire")
	audience.queue_free()
	await process_frame
	print("Audience checks passed: saved answers, unknown fallback and no age questionnaire.")
	quit()
