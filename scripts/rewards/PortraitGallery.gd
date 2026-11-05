extends Node

signal status_changed(message: String)
const STATE_PATH := "user://portrait_gallery.cfg"
var _state := ConfigFile.new()
var _provider: Object
var _busy := false
var _queue: Array[String] = []
var _current := ""
var _permission_denied := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state.load(STATE_PATH)
	if Engine.has_singleton("PortraitGallery"):
		connect_provider(Engine.get_singleton("PortraitGallery"))
	if auto_save():
		_queue_pending.call_deferred()

func connect_provider(provider: Object) -> void:
	_provider = provider
	_provider.connect("portrait_saved",_on_saved)

func supported() -> bool:
	return _provider != null

func auto_save() -> bool:
	return bool(_state.get_value("preferences","auto_save",false))

func set_auto_save(value: bool) -> void:
	_state.set_value("preferences","asked",true)
	_state.set_value("preferences","auto_save",value)
	_state.save(STATE_PATH)
	_permission_denied = false
	if value:
		_queue_pending()
	else:
		_queue.clear()

func record_completed(portrait: String, slot: int) -> String:
	if portrait not in DailyActivities.settings().portraits:
		return ""
	var id := "%s_%d" % [portrait.get_file().get_basename(),slot]
	_state.set_value("completed",id,{"portrait":portrait,"slot":slot})
	_state.save(STATE_PATH)
	if auto_save():
		request_save(id)
	elif supported() and not bool(_state.get_value("preferences","asked",false)):
		_offer_auto_save.call_deferred()
	return id

func _offer_auto_save() -> void:
	if bool(_state.get_value("preferences","asked",false)):
		return
	_state.set_value("preferences","asked",true)
	_state.save(STATE_PATH)
	var dialog := ConfirmationDialog.new()
	dialog.title = "Keep your restored portraits"
	dialog.dialog_text = "Save completed portrait pictures automatically to your phone's gallery in the Save The Baby album?\nYou can change this in Daily Rewards. Your game album is kept either way."
	dialog.ok_button_text = "Enable automatic saving"
	dialog.cancel_button_text = "Not now"
	dialog.confirmed.connect(func(): set_auto_save(true); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(mini(600,int(get_viewport().get_visible_rect().size.x)-32),240))

func save_collection(portrait: String, progress: ConfigFile) -> void:
	var collection: Dictionary = progress.get_value("daily","portraits",{})
	if int(collection.get(portrait,0)) <= 0 or portrait not in DailyActivities.settings().portraits:
		return
	var id := portrait.get_file().get_basename()+"_collection"
	_state.set_value("completed",id,{"portrait":portrait,"slot":-1})
	_state.save(STATE_PATH)
	request_save(id,true)

func request_save(id: String, manual := false) -> void:
	if not supported():
		status_changed.emit("Gallery saving is available in the Android app. Your portrait is in the game album.")
		return
	if not _state.has_section_key("completed",id):
		return
	if _current == id or id in _queue:
		return
	if not manual and bool(_state.get_value("saved",id,false)):
		return
	_permission_denied = false
	_queue.append(id)
	_next()

func _queue_pending() -> void:
	if not supported() or not _state.has_section("completed"):
		return
	for id in _state.get_section_keys("completed"):
		if not bool(_state.get_value("saved",id,false)) and id != _current and id not in _queue:
			_queue.append(id)
	_next()

static func puzzle_image(portrait: String) -> Image:
	var texture := ResourceManager.load_texture(portrait)
	if texture == null:
		return null
	var original := texture.get_image()
	if original == null:
		return null
	if original.is_compressed():
		original.decompress()
	return original

func _next() -> void:
	if _busy or _queue.is_empty() or _permission_denied:
		return
	_current = _queue.pop_front()
	_busy = true
	var record: Dictionary = _state.get_value("completed",_current,{})
	var image := puzzle_image(str(record.get("portrait","")))
	if image == null:
		_on_saved(_current,false,"Could not prepare this portrait. Please try again.")
		return
	status_changed.emit("Saving portrait to gallery…")
	_provider.call("savePortrait",image.save_png_to_buffer(),"SaveTheBaby_"+_current+".png",_current)

func _on_saved(id: String, success: bool, message: String) -> void:
	# Native callbacks can arrive from a worker; update UI/state on Godot's main thread.
	_finish_save.call_deferred(id,success,message)

func _finish_save(id: String, success: bool, message: String) -> void:
	if id != _current:
		return
	if success:
		_state.set_value("saved",id,true)
		_state.save(STATE_PATH)
	else:
		# Avoid repeated permission prompts or failures for every queued portrait.
		_permission_denied = true
		_queue.clear()
	_busy = false
	_current = ""
	status_changed.emit(message)
	_next()
