extends Resource
class_name AnimationSequence

# =========================================================
# PURPOSE
# =========================================================
# Represents an ordered sequence of AnimationRequest objects
# that must be executed sequentially by AnimationManager.
#
# Example flow:
# Swap → Destroy → Fall → Spawn → Cascade
#
# This is PURE STRUCTURE.
# No execution logic belongs here.

# =========================================================
# INTERNAL STATE
# =========================================================

var _steps: Array[AnimationRequest] = []
var _current_index: int = 0


# =========================================================
# CORE API
# =========================================================

func add_step(request: AnimationRequest) -> void:
	if request == null:
		return

	_steps.append(request)


func get_next() -> AnimationRequest:
	if _current_index >= _steps.size():
		return null

	var step: AnimationRequest = _steps[_current_index]
	_current_index += 1
	return step


func peek_next() -> AnimationRequest:
	if _current_index >= _steps.size():
		return null

	return _steps[_current_index]


func reset() -> void:
	_current_index = 0


func is_complete() -> bool:
	return _current_index >= _steps.size()


func size() -> int:
	return _steps.size()


func get_all() -> Array[AnimationRequest]:
	return _steps


# =========================================================
# STATE DEBUG
# =========================================================

func get_progress() -> float:
	if _steps.size() == 0:
		return 1.0

	return float(_current_index) / float(_steps.size())