extends RefCounted
class_name ObstacleBehavior

# =========================================================
# INTERNAL REFERENCE
# =========================================================

var _obstacle: Obstacle


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(obstacle: Obstacle) -> void:
	_obstacle = obstacle


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
# GAMEPLAY HOOKS
# =========================================================

func on_match(match) -> void:
	pass


func on_damage(amount: int) -> void:
	pass


func on_destroy() -> void:
	pass


func can_be_damaged() -> bool:
	return true


func can_be_removed() -> bool:
	return true


# =========================================================
# SPECIAL BEHAVIOR EXTENSION POINTS
# =========================================================

func disable() -> void:
	# alias hook for deactivate (some behaviors prefer semantic naming)
	deactivate()


func requires_thunder() -> bool:
	return false


func on_thunder_used() -> void:
	pass