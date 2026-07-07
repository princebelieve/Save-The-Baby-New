extends ObstacleBehavior
class_name ElectricTrapBehavior

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
	pass


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
	return true


func on_thunder_used() -> void:
	if _obstacle:
		_obstacle.damage(_obstacle.get_obstacle_state().get_health())