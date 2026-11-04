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

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return """
		<activity-alias
			android:name=".GodotAuthReturn"
			android:targetActivity=".GodotApp"
			android:exported="true">
			<intent-filter>
				<action android:name="android.intent.action.VIEW" />
				<category android:name="android.intent.category.DEFAULT" />
				<category android:name="android.intent.category.BROWSABLE" />
				<data android:scheme="savethebaby" android:host="auth" android:path="/complete" />
			</intent-filter>
		</activity-alias>
		"""
