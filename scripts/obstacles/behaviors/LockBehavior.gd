extends ObstacleBehavior
class_name LockBehavior

# =========================================================
# LIFECYCLE
# =========================================================

func activate() -> void:
	if _obstacle:
		_obstacle.lock()


func deactivate() -> void:
	if _obstacle:
		_obstacle.unlock()


func reset() -> void:
	if _obstacle:
		_obstacle.lock()


# =========================================================
# GAMEPLAY
# =========================================================

func on_match(match) -> void:
	pass


func on_damage(amount: int) -> void:
	if _obstacle == null:
		return

	_obstacle.damage(amount)


func on_destroy() -> void:
	if _obstacle:
		_obstacle.unlock()


func can_be_damaged() -> bool:
	return true


func can_be_removed() -> bool:
	return _obstacle != null and _obstacle.is_destroyed()


# =========================================================
# SPECIAL
# =========================================================

func requires_thunder() -> bool:
	return false


func on_thunder_used() -> void:
	pass