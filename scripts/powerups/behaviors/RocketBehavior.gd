extends PowerupBehavior
class_name RocketBehavior


# =========================================================
# LIFECYCLE
# =========================================================

func activate() -> void:
	super.activate()


func deactivate() -> void:
	super.deactivate()


func reset() -> void:
	super.reset()


func interrupt() -> void:
	super.interrupt()


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

	# Request Rocket activation animation.
	# Gameplay resolution is coordinated externally by BoardManager.
	_powerup.request_animation("activate")


func on_activation_finished() -> void:
	super.on_activation_finished()


func on_activation_cancelled() -> void:
	super.on_activation_cancelled()


func can_activate() -> bool:
	return super.can_activate()


# =========================================================
# TARGETING
# =========================================================

func requires_target() -> bool:
	return true


func is_valid_target(target) -> bool:
	if not super.is_valid_target(target):
		return false

	return true


func on_target_selected(target) -> void:
	if _powerup == null:
		return

	# Rocket accepts any valid board target.
	# Direction and board resolution are determined by
	# the gameplay systems that execute the activation.
	_powerup.get_powerup_state().set_state(target)


# =========================================================
# COMBINATION
# =========================================================

func can_combine() -> bool:
	return super.can_combine()


func on_combine(other_powerup: Powerup) -> void:
	if other_powerup == null:
		return

	# Combination resolution belongs to the gameplay systems.
	pass


func on_combination_finished(result_powerup: Powerup) -> void:
	super.on_combination_finished(result_powerup)


# =========================================================
# STATE
# =========================================================

func is_busy() -> bool:
	return super.is_busy()