extends Node
class_name AnimationQueue

# =========================================================
# PURPOSE
# =========================================================
# Owns the queue of pending AnimationRequest objects.
# Pure data structure + queue control.
# No knowledge of gameplay or animation execution.

var _queue: Array = []

# =========================================================
# CORE API
# =========================================================

func enqueue(animation) -> void:
	_queue.append(animation)


func dequeue():
	if _queue.is_empty():
		return null

	return _queue.pop_front()


func clear() -> void:
	_queue.clear()


func has_pending() -> bool:
	return not _queue.is_empty()


func is_empty() -> bool:
	return _queue.is_empty()


# =========================================================
# DEBUG / INTROSPECTION (SAFE)
# =========================================================

func size() -> int:
	return _queue.size()


func peek():
	if _queue.is_empty():
		return null
	return _queue[0]
