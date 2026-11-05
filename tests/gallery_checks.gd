extends Node

const Gallery = preload("res://scripts/rewards/PortraitGallery.gd")
var failures: Array[String] = []
var checks := 0

class NativeDouble extends Node:
	signal portrait_saved(id: String, success: bool, message: String)
	var calls: Array[Dictionary] = []
	var fail := false
	func savePortrait(png: PackedByteArray, filename: String, id: String) -> void:
		calls.append({"png":png,"filename":filename,"id":id})
		portrait_saved.emit(id,not fail,"Saved to gallery" if not fail else "Storage unavailable")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/.test-data/"):
		get_tree().quit(1)
		return
	call_deferred("_run")

func settle() -> void:
	for i in range(4):
		await get_tree().process_frame

func _run() -> void:
	if FileAccess.file_exists(Gallery.STATE_PATH):
		DirAccess.remove_absolute(Gallery.STATE_PATH)
	var gallery := Gallery.new()
	add_child(gallery)
	check(not gallery.auto_save(),"automatic gallery export requires a player choice")
	check(not gallery.supported(),"desktop has no native gallery provider")
	var native := NativeDouble.new()
	add_child(native)
	gallery.connect_provider(native)
	gallery.set_auto_save(true)
	var portrait := str(DailyActivities.settings().portraits[0])
	check(gallery.record_completed("res://unrelated.png",123).is_empty(),"unrecognised image cannot be exported")
	var id := gallery.record_completed(portrait,123)
	await settle()
	check(native.calls.size() == 1,"completed portrait automatically queues one save")
	check(bool(gallery._state.get_value("saved",id,false)),"native success persists save receipt")
	var decoded := Image.new()
	check(decoded.load_png_from_buffer(native.calls[0].png) == OK,"gallery bridge receives a valid PNG")
	check(decoded.get_size() == Vector2i(ResourceManager.load_texture(portrait).get_size()),"export preserves the complete portrait aspect ratio")
	var expected := Gallery.puzzle_image(portrait)
	check(decoded.get_size() == expected.get_size(),"export keeps original puzzle resolution")
	check(native.calls[0].filename == "SaveTheBaby_"+id+".png","stable name makes retries idempotent")
	gallery.record_completed(portrait,123)
	await settle()
	check(native.calls.size() == 1,"duplicate completion does not export again")
	gallery.request_save(id,true)
	await settle()
	check(native.calls.size() == 2,"manual save can recreate a deleted gallery image")
	native.fail = true
	var failed := gallery.record_completed(portrait,124)
	await settle()
	check(not bool(gallery._state.get_value("saved",failed,false)),"failed export is not reported as saved")
	check(gallery._state.has_section_key("completed",failed),"completed portrait is retained after export failure")
	gallery.queue_free()
	await settle()
	native.fail = false
	var restored := Gallery.new()
	add_child(restored)
	restored.connect_provider(native)
	await settle()
	check(bool(restored._state.get_value("saved",failed,false)),"pending export retries after restart")
	var before := native.calls.size()
	restored.set_auto_save(false)
	var manual_id := restored.record_completed(portrait,125)
	await settle()
	check(native.calls.size() == before,"disabling automatic saves retains portrait without export")
	restored.request_save(manual_id,true)
	await settle()
	check(native.calls.size() == before+1,"manual save remains available with auto save off")
	var progress := ConfigFile.new()
	before = native.calls.size()
	restored.save_collection(portrait,progress)
	await settle()
	check(native.calls.size() == before,"unearned album picture cannot be exported")
	progress.set_value("daily","portraits",{portrait:1})
	restored.save_collection(portrait,progress)
	await settle()
	check(native.calls.size() == before+1,"earned album picture can be exported after cloud restore")
	var puzzle := PortraitPuzzle.new()
	puzzle.configure({"portrait":portrait,"slot":123,"pieces":[0,1,2,3,4,5,6,7,8],"deadline":TimeHelper.current_unix_time()+120})
	add_child(puzzle)
	check(not puzzle._save_button.visible,"gallery button hidden before completion")
	puzzle.show_reward(15,1)
	check(puzzle._save_button.visible,"completed puzzle exposes save button")
	puzzle.show_gallery_status("Saved to gallery")
	check(puzzle._gallery_message.text == "Saved to gallery","gallery result appears separately from coin reward")
	puzzle.queue_free()
	restored.queue_free()
	native.queue_free()
	await settle()
	print("GALLERY_CHECKS: %d checks; %d failures" % [checks,failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
