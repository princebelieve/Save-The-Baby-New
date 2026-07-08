extends PowerupBehavior
class_name LineBlastBehavior


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
	# BoardManager decides whether this blast is horizontal,
	# vertical, or another configured line pattern.
	# This behavior only updates runtime state.
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
	# Line Blast activates immediately.
	# Direction is determined by BoardManager or configuration.
	return false


func is_valid_target(target) -> bool:
	return true


func on_target_selected(target) -> void:
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