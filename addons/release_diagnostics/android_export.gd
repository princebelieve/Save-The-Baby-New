@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "SBReleaseDiagnostics"

func _export_begin(features: PackedStringArray, debug: bool, _path: String, _flags: int) -> void:
	if debug or not features.has("android"):
		return
	var build_dir := str(get_option("gradle_build/gradle_build_directory"))
	if build_dir.is_empty():
		build_dir = "res://android/build"
	for filename in ["save-the-baby-release.gradle", "save-the-baby-proguard-rules.pro"]:
		var error := DirAccess.copy_absolute("res://addons/release_diagnostics/" + filename, build_dir.path_join(filename))
		if error != OK:
			push_error("Release diagnostics: cannot install %s: %s" % [filename, error_string(error)])
			return
	var path := build_dir.path_join("build.gradle")
	var source := FileAccess.get_file_as_string(path)
	var hook := "apply from: 'save-the-baby-release.gradle'"
	if not source.contains(hook):
		var output := FileAccess.open(path, FileAccess.WRITE)
		if output == null:
			push_error("Release diagnostics: cannot update Android build.gradle")
			return
		output.store_string(source + "\n// Project-owned release configuration; restored after template updates.\n" + hook + "\n")
