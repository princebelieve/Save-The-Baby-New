@tool
extends EditorPlugin

var exporter := UnityPrivacyExport.new()

func _enter_tree() -> void:
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class UnityPrivacyExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "SaveTheBabyUnityAdsPrivacy"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.UnityAdsPrivacy" android:value="com.savethebaby.ads.UnityAdsPrivacyPlugin" />'

	func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android"):
			return
		var build_dir := str(get_option("gradle_build/gradle_build_directory"))
		if build_dir.is_empty():
			build_dir = "res://android/build"
		var target := build_dir.path_join("src/main/java/com/savethebaby/ads")
		var error := DirAccess.make_dir_recursive_absolute(target)
		if error == OK:
			error = DirAccess.copy_absolute("res://addons/unity_ads_privacy/android/UnityAdsPrivacyPlugin.java", target.path_join("UnityAdsPrivacyPlugin.java"))
		if error != OK:
			push_error("Unity Ads: cannot install privacy bridge: " + error_string(error))
