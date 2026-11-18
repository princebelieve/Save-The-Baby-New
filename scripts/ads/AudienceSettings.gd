extends Node

# Reuse an existing age answer when available; do not add an age questionnaire.
const SETTINGS := "user://ad_age_group.cfg"
const GROUPS := ["under_13", "13_15", "16_17", "adult", "unknown"]
var age_group := "unknown"

func _settings() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SETTINGS)
	return config

func start_session() -> String:
	var saved := str(_settings().get_value("audience", "group", "unknown"))
	age_group = saved if saved in GROUPS else "unknown"
	return age_group
