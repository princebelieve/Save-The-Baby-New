@tool
extends EditorPlugin

var exporter := GalleryExport.new()

func _enter_tree() -> void:
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class GalleryExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "SaveTheBabyPortraitGallery"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android"):
			return
		var build_dir := str(get_option("gradle_build/gradle_build_directory"))
		if build_dir.is_empty():
			build_dir = "res://android/build"
		var target := build_dir.path_join("src/main/java/com/savethebaby/gallery")
		var error := DirAccess.make_dir_recursive_absolute(target)
		if error == OK:
			error = DirAccess.copy_absolute("res://addons/portrait_gallery/android/PortraitGalleryPlugin.java",target.path_join("PortraitGalleryPlugin.java"))
		if error != OK:
			push_error("Portrait gallery: could not install Android source: "+error_string(error))

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<meta-data android:name="org.godotengine.plugin.v2.PortraitGallery" android:value="com.savethebaby.gallery.PortraitGalleryPlugin" />'

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return '<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />'
