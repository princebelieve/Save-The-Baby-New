extends Node
class_name AnimationManager

signal animation_started(name)
signal animation_finished(name)

var _active_animations: Dictionary = {}


func initialize() -> void:
	_active_animations.clear()


func play(name: String, target: Object) -> void:
	if target == null:
		push_warning("AnimationManager: Cannot play animation '%s' on a null target." % name)
		return

	var request := AnimationRequest.new()

	request.animation_name = name
	request.target = target

	_active_animations[target] = request

	emit_signal("animation_started", name)

	_dispatch_request(request)


func stop(target: Object) -> void:
	if target == null:
		return

	if not _active_animations.has(target):
		return

	var request: AnimationRequest = _active_animations[target]

	if request.has_method("cancel"):
		request.cancel()

	_active_animations.erase(target)

	emit_signal("animation_finished", request.animation_name)


func stop_all() -> void:
	var targets := _active_animations.keys()

	for target in targets:
		stop(target)


func pause_all() -> void:
	for request in _active_animations.values():
		if request.has_method("pause"):
			request.pause()


func resume_all() -> void:
	for request in _active_animations.values():
		if request.has_method("resume"):
			request.resume()


func is_playing(target: Object) -> bool:
	return _active_animations.has(target)


func wait_for_animation(target: Object) -> void:
	if target == null:
		return

	while _active_animations.has(target):
		await get_tree().process_frame


func _dispatch_request(request: AnimationRequest) -> void:
	if request == null:
		return

	if request.target != null and request.target.has_method("play_animation"):
		request.target.play_animation(request)

	if request.has_signal("finished"):
		request.finished.connect(_on_request_finished.bind(request), CONNECT_ONE_SHOT)


func _on_request_finished(request: AnimationRequest) -> void:
	if request == null:
		return

	if _active_animations.get(request.target) == request:
		_active_animations.erase(request.target)

	emit_signal("animation_finished", request.animation_name)