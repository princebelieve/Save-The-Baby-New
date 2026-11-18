@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = AuthReturnExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AuthReturnExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "SaveTheBabyAuthReturn"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not features.has("android"):
			return
		var build_dir := str(get_option("gradle_build/gradle_build_directory"))
		if build_dir.is_empty():
			build_dir = "res://android/build"
		var path := build_dir.path_join("src/main/AndroidManifest.xml")
		var source := FileAccess.get_file_as_string(path)
		var activity := RegEx.new()
		activity.compile('<activity\\b[^>]*android:name="\\.GodotApp"[^>]*>')
		var found := activity.search(source)
		if found == null:
			push_error("Account return: the Android game activity could not be found.")
			return
		var original := found.get_string()
		var launch_mode := RegEx.new()
		launch_mode.compile('android:launchMode="[^"]+"')
		var updated := launch_mode.sub(original, 'android:launchMode="singleTask"')
		var exported := RegEx.new()
		exported.compile('android:exported="[^"]+"')
		updated = exported.sub(updated, 'android:exported="true"')
		source = source.replace(original, updated)
		# Old templates retained a VIEW filter; the activity hook also injected it
		# into the launcher alias. Remove those copies before adding one handler.
		var filters := RegEx.new()
		filters.compile("(?s)<intent-filter\\b[^>]*>.*?</intent-filter>")
		for filter_match in filters.search_all(source):
			var contents := filter_match.get_string()
			if contents.contains('android:scheme="savethebaby"') and contents.contains('android:host="auth"'):
				source = source.replace(contents, "")
		var output := FileAccess.open(path, FileAccess.WRITE)
		if output == null:
			push_error("Account return: cannot update Android manifest.")
			return
		output.store_string(source)
		output.close()
		var target := build_dir.path_join("src/main/java/com/savethebaby/auth")
		var error := DirAccess.make_dir_recursive_absolute(target)
		if error == OK:
			error = DirAccess.copy_absolute("res://addons/auth_return/android/AuthReturnActivity.java", target.path_join("AuthReturnActivity.java"))
		if error != OK:
			push_error("Account return: cannot install browser return handler.")

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if str(get_option("package/unique_name")) == "com.savethebaby.developer":
			return ""
		return '''
        <activity android:name="com.savethebaby.auth.AuthReturnActivity"
            android:exported="true" android:noHistory="true"
            android:excludeFromRecents="true" android:theme="@android:style/Theme.NoDisplay">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="savethebaby" android:host="auth" android:path="/complete" />
            </intent-filter>
        </activity>
'''
