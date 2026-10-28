extends RefCounted
class_name AutosaveScheduler

var _interval: float = 120.0
var _elapsed_time: float = 0.0
var _running: bool = true
var _paused: bool = false

func initialize() -> void:
	_elapsed_time = 0.0
	_running = true
	_paused = false


func start() -> void:
	_running = true


func stop() -> void:
	_running = false


func pause() -> void:
	_paused = true


func resume() -> void:
	_paused = false


func set_interval(seconds: float) -> void:
	_interval = maxf(1.0, seconds)


func get_interval() -> float:
	return _interval


func update(delta: float) -> void:
	if _running and not _paused:
		_elapsed_time += delta


func is_time_to_autosave() -> bool:
	return _running and not _paused and _elapsed_time >= _interval


func reset_timer() -> void:
	_elapsed_time = 0.0
