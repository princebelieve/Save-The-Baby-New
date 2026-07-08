extends RefCounted
class_name PowerupBehavior


# =========================================================
# INTERNAL REFERENCE
# =========================================================

var _powerup: Powerup


# =========================================================
# INITIALIZATION
# =========================================================

func initialize(powerup: Powerup) -> void:
	_powerup = powerup


# =========================================================
# LIFECYCLE
# =========================================================

func activate() -> void:
	if _powerup == null:
		return

	if is_busy():
		return

	if not can_activate():
		return

	_powerup.activate()
	on_activate()


func deactivate() -> void:
	if _powerup == null:
		return

	_powerup.deactivate()


func reset() -> void:
	if _powerup == null:
		return

	_powerup.deactivate()


func interrupt() -> void:
	deactivate()


# =========================================================
# SELECTION
# =========================================================

func on_selected() -> void:
	if _powerup == null:
		return

	_powerup.get_powerup_state().set_armed(true)


func on_deselected() -> void:
	if _powerup == null:
		return

	_powerup.get_powerup_state().set_armed(false)


# =========================================================
# ACTIVATION FLOW
# =========================================================

func on_activate() -> void:
	if _powerup == null:
		return

	_powerup.get_powerup_state().set_consumed(true)


func on_activation_finished() -> void:
	if _powerup == null:
		return

	_powerup.deactivate()


func on_activation_cancelled() -> void:
	if _powerup == null:
		return

	_powerup.get_powerup_state().set_armed(false)
	_powerup.deactivate()


func can_activate() -> bool:
	if _powerup == null:
		return false

	var state := _powerup.get_powerup_state()

	if state == null:
		return false

	if state.is_consumed():
		return false

	if _powerup.is_active():
		return false

	return true


# =========================================================
# TARGETING
# =========================================================

func requires_target() -> bool:
	return false


func is_valid_target(target) -> bool:
	return target != null


func on_target_selected(target) -> void:
	pass


# =========================================================
# COMBINATION
# =========================================================

func can_combine() -> bool:
	if _powerup == null:
		return false

	return not _powerup.get_powerup_state().is_consumed()


func on_combine(other_powerup: Powerup) -> void:
	pass


func on_combination_finished(result_powerup: Powerup) -> void:
	if _powerup == null:
		return

	_powerup.get_powerup_state().set_consumed(true)
	_powerup.deactivate()


# =========================================================
# STATE QUERIES
# =========================================================

func is_busy() -> bool:
	if _powerup == null:
		return false

	return _powerup.is_animation_playing()


func disable() -> void:
	deactivate()