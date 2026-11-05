extends Node

const Builder = preload("res://tools/CampaignLevelBuilder.gd")

## Offline content-building tool. Never called by the running game.
## Run with tools/materialize_campaign.tscn from the Godot command line.
func _ready() -> void:
	var config := Builder.settings()
	var written := 0
	for level_id in range(int(config.first_level), int(config.last_level) + 1):
		var path := "res://levels/level%03d.json" % level_id
		if FileAccess.file_exists(path):
			continue # Preserve existing levels and manual design edits.
		var definition := Builder.generate(level_id)
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null or definition.is_empty():
			push_error("Could not materialize %s" % path)
			get_tree().quit(1)
			return
		file.store_string(JSON.stringify(definition, "    ") + "\n")
		file.close()
		written += 1
	print("Wrote %d level JSON files; existing files preserved." % written)
	get_tree().quit()
