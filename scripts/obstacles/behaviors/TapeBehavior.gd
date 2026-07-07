extends ObstacleBehavior
class_name TapeBehavior

# =========================================================
# LIFECYCLE
# =========================================================

func activate() -> void:
	pass


func deactivate() -> void:
	pass


func reset() -> void:
	pass


# =========================================================
# GAMEPLAY
# =========================================================

func on_match(match) -> void:
	if _obstacle:
		_obstacle.damage(1)


func on_damage(amount: int) -> void:
	if _obstacle:
		_obstacle.damage(amount)


func on_destroy() -> void:
	pass


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