extends SceneTree

class PolicyProvider extends "res://scripts/ads/AdProvider.gd":
	var consent_started := false
	func _ready() -> void:
		pass
	func _update_consent() -> void:
		consent_started = true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_user_data_dir().replace("\\", "/").contains("/.test-data/"))
	var provider := PolicyProvider.new()
	root.add_child(provider)
	provider._show_age_screen()
	var dialog := provider._age_dialog
	var choices: OptionButton
	for child in dialog.get_children():
		if child is OptionButton:
			choices = child
	assert(choices != null and choices.selected == 0)
	assert(dialog.get_ok_button().disabled and not provider.consent_started)
	assert(choices.get_item_text(5) == "Prefer not to say")
	choices.select(5)
	choices.item_selected.emit(5)
	assert(not dialog.get_ok_button().disabled)
	dialog.confirmed.emit()
	await process_frame
	var settings := ConfigFile.new()
	assert(settings.load(provider.AGE_SETTINGS) == OK)
	assert(settings.get_value("audience", "group") == "unknown")
	assert(provider.consent_started)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(provider.AGE_SETTINGS))
	provider.queue_free()
	await process_frame
	print("Ad age screen checks passed")
	quit()
