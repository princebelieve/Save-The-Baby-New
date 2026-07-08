extends PowerupBehavior
class_name BombBehavior


# =========================================================
# SELECTION
# =========================================================

func on_selected() -> void:
	super.on_selected()

	if _powerup != null:
		_powerup.request_animation("highlight")


func on_deselected() -> void:
	super.on_deselected()


# =========================================================
# ACTIVATION FLOW
# =========================================================

func on_activate() -> void:
	super.on_activate()

	if _powerup == null:
		return

	# Request Bomb activation animation.
	# Board resolution is coordinated externally.
	_powerup.request_animation("activate")


func on_activation_finished() -> void:
	super.on_activation_finished()


func on_activation_cancelled() -> void:
	super.on_activation_cancelled()


# =========================================================
# TARGETING
# =========================================================

func requires_target() -> bool:
	return false


func is_valid_target(target) -> bool:
	# Bomb does not require a target, so there is nothing to validate.
	return false


func on_target_selected(target) -> void:
	# Bomb ignores target selection.
	pass


# =========================================================
# COMBINATION
# =========================================================

func on_combine(other_powerup: Powerup) -> void:
	if other_powerup == null:
		return

	# Combination resolution belongs to the gameplay systems.
	pass


func on_combination_finished(result_powerup: Powerup) -> void:
	super.on_combination_finished(result_powerup)