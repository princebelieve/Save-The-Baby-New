@tool
extends EditorPlugin

var exporter := TikTokExport.new()

func _enter_tree() -> void:
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class TikTokExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "SaveTheBabyTikTokEvents"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.github.tiktok:tiktok-business-android-sdk:1.7.1",
			"androidx.lifecycle:lifecycle-process:2.3.1",
			"androidx.lifecycle:lifecycle-common-java8:2.3.1",
			"com.android.installreferrer:installreferrer:2.2",
		])

	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://jitpack.io"])

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.TikTokEvents" android:value="com.savethebaby.tiktok.TikTokEventsPlugin" />'

	func _export_begin(features: PackedStringArray, debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android"):
			return
		var build_dir := str(get_option("gradle_build/gradle_build_directory"))
		if build_dir.is_empty():
			build_dir = "res://android/build"
		var target := build_dir.path_join("src/main/java/com/savethebaby/tiktok")
		var error := DirAccess.make_dir_recursive_absolute(target)
		if error == OK:
			for filename in ["TikTokEventsPlugin.java", "TikTokTrackingSession.java", "TikTokPrivacyDecision.java"]:
				error = DirAccess.copy_absolute("res://addons/tiktok_events/android/" + filename, target.path_join(filename))
				if error != OK:
					break
		if error != OK:
			push_error("TikTok Events: cannot install Android source: " + error_string(error))
			return
		# Read outside the exported game resources; never embed credentials in GDScript.
		var config := ConfigFile.new()
		var config_path := "res://.private/tiktok-events.cfg"
		if FileAccess.file_exists(config_path):
			error = config.load(config_path)
			if error != OK:
				push_error("TikTok Events: cannot read local configuration")
		var app_id := OS.get_environment("TIKTOK_APP_ID").strip_edges()
		var token := OS.get_environment("TIKTOK_SDK_ACCESS_TOKEN").strip_edges()
		if app_id.is_empty():
			app_id = str(config.get_value("tiktok", "app_id", "")).strip_edges()
		if token.is_empty():
			token = str(config.get_value("tiktok", "access_token", "")).strip_edges()
		if app_id.is_empty() or token.is_empty():
			push_warning("TikTok Events: credentials missing; SDK will remain inactive in this export")
		var values_dir := build_dir.path_join("res/values")
		error = DirAccess.make_dir_recursive_absolute(values_dir)
		if error != OK:
			push_error("TikTok Events: cannot create Android resources")
			return
		var output := FileAccess.open(values_dir.path_join("sb_tiktok.xml"), FileAccess.WRITE)
		if output == null:
			push_error("TikTok Events: cannot write Android configuration")
			return
		var consent_vendor := OS.get_environment("TIKTOK_CONSENT_VENDOR_ID").strip_edges()
		if consent_vendor.is_empty():
			consent_vendor = str(config.get_value("tiktok", "consent_vendor_id", "")).strip_edges()
		var test_mode := debug and OS.get_environment("TIKTOK_SDK_TEST_MODE").to_lower() == "true"
		# Android string resources need Android escaping as well as XML escaping.
		output.store_string('<resources>\n<string name="sb_tiktok_app_id" translatable="false">"%s"</string>\n<string name="sb_tiktok_access_token" translatable="false">"%s"</string>\n<string name="sb_tiktok_consent_vendor_id" translatable="false">"%s"</string>\n<string name="sb_tiktok_test_mode" translatable="false">%s</string>\n</resources>\n' % [_resource_value(app_id), _resource_value(token), _resource_value(consent_vendor), "true" if test_mode else "false"])

	func _resource_value(value: String) -> String:
		return value.replace("\\", "\\\\").replace('"', '\\"').replace("'", "\\'").replace("\n", "\\n").xml_escape()
