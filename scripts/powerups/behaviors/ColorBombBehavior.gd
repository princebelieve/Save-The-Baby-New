extends PowerupBehavior
class_name ColorBombBehavior


# =========================================================
# LIFECYCLE
# =========================================================

func activate() -> void:
	if _powerup == null:
		return

	_powerup.activate()

	var state := _powerup.get_powerup_state()

	if state != null:
		state.set_armed(true)

	on_activate()


func deactivate() -> void:
	if _powerup == null:
		return

	_powerup.deactivate()

	var state := _powerup.get_powerup_state()

	if state != null:
		state.set_armed(false)


func reset() -> void:
	if _powerup == null:
		return

	deactivate()

	var state := _powerup.get_powerup_state()

	if state != null:
		state.set_consumed(false)


func interrupt() -> void:
	deactivate()


# =========================================================
# SELECTION
# =========================================================

func on_selected() -> void:
	pass


func on_deselected() -> void:
	pass


# =========================================================
# ACTIVATION FLOW
# =========================================================

func on_activate() -> void:
	# BoardManager determines which color is removed.
	# This behavior only updates the runtime state.
	var state := _powerup.get_powerup_state()

	if state != null:
		state.set_consumed(true)


func on_activation_finished() -> void:
	deactivate()


func on_activation_cancelled() -> void:
	deactivate()


func can_activate() -> bool:
	if _powerup == null:
		return false

	var state := _powerup.get_powerup_state()

	if state == null:
		return false

	return (
		not state.is_consumed()
		and not state.is_active()
	)


# =========================================================
# TARGETING
# =========================================================

func requires_target() -> bool:
	# Color Bomb requires a tile selection to determine
	# which tile color BoardManager should remove.
	return true


func is_valid_target(target) -> bool:
	return target != null


func on_target_selected(target) -> void:
	# BoardManager performs the actual color elimination.
	pass


# =========================================================
# COMBINATION
# =========================================================

func can_combine() -> bool:
	return true


func on_combine(other_powerup: Powerup) -> void:
	pass


func on_combination_finished(result_powerup: Powerup) -> void:
	deactivate()


# =========================================================
# STATE QUERIES
# =========================================================

func is_busy() -> bool:
	if _powerup == null:
		return false

	return _powerup.is_animation_playing()