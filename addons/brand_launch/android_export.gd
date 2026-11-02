@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "SBBrandLaunch"

func _export_begin(features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
	if not features.has("android"):
		return
	var build_dir := str(get_option("gradle_build/gradle_build_directory"))
	if build_dir.is_empty():
		build_dir = "res://android/build"
	var drawable := build_dir.path_join("res/drawable-nodpi")
	DirAccess.make_dir_recursive_absolute(drawable)
	var result := DirAccess.copy_absolute("res://assets/sb_ibhadode_splash.png", drawable.path_join("sb_launch_logo.png"))
	if result != OK:
		push_error("Cannot install S. B. Android splash logo: %s" % result)
		return
	var icon := FileAccess.open(drawable.path_join("sb_launch_icon.xml"), FileAccess.WRITE)
	# Keep the complete company mark inside Android's circular splash safe area.
	icon.store_string('<layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item android:width="192dp" android:height="192dp" android:gravity="center"><bitmap android:src="@drawable/sb_launch_logo" android:gravity="fill" android:filter="true" /></item></layer-list>')
	icon.close()
	var java_path := build_dir.path_join("src/main/java/com/godot/game/GodotApp.java")
	var source := FileAccess.get_file_as_string(java_path).replace("\r\n", "\n")
	if source.contains("sbEngineStarted"):
		return
	var original := "SplashScreen.installSplashScreen(this);"
	if not source.contains(original) or not source.contains("super.onGodotMainLoopStarted();"):
		push_error("Brand launch: unsupported Godot Android template; startup handoff was not patched.")
		return
	source = source.replace(original, "SplashScreen sbSplash = SplashScreen.installSplashScreen(this);\n\t\tsbSplash.setKeepOnScreenCondition(() -> !sbEngineStarted);")
	# Field belongs to the Activity; release only after the engine has started drawing.
	source = source.replace("\t@Override\n\tpublic void onCreate", "\tprivate volatile boolean sbEngineStarted = false;\n\n\t@Override\n\tpublic void onCreate")
	source = source.replace("super.onGodotMainLoopStarted();", "super.onGodotMainLoopStarted();\n\t\trunOnUiThread(() -> getWindow().getDecorView().postOnAnimation(() -> getWindow().getDecorView().postOnAnimation(() -> sbEngineStarted = true)));")
	var output := FileAccess.open(java_path, FileAccess.WRITE)
	output.store_string(source)
