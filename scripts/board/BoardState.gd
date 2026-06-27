extends RefCounted

class_name BoardState


signal state_changed(
	previous_state: Constants.BoardState,
	current_state: Constants.BoardState
)


var _current_state: Constants.BoardState = Constants.BoardState.GENERATING


func get_state() -> Constants.BoardState:
	return _current_state


func is_state(state: Constants.BoardState) -> bool:
	return _current_state == state


func set_state(state: Constants.BoardState) -> void:
	if _current_state == state:
		return

	var previous_state := _current_state
	_current_state = state

	state_changed.emit(previous_state, _current_state)


func reset() -> void:
	set_state(Constants.BoardState.GENERATING)


func is_generating() -> bool:
	return is_state(Constants.BoardState.GENERATING)


func is_waiting_for_input() -> bool:
	return is_state(Constants.BoardState.WAITING_FOR_INPUT)


func is_swapping() -> bool:
	return is_state(Constants.BoardState.SWAPPING)


func is_checking_matches() -> bool:
	return is_state(Constants.BoardState.CHECKING_MATCHES)


func is_destroying() -> bool:
	return is_state(Constants.BoardState.DESTROYING)


func is_falling() -> bool:
	return is_state(Constants.BoardState.FALLING)


func is_refilling() -> bool:
	return is_state(Constants.BoardState.REFILLING)


func is_cascading() -> bool:
	return is_state(Constants.BoardState.CASCADING)


func is_shuffling() -> bool:
	return is_state(Constants.BoardState.SHUFFLING)


func is_finished() -> bool:
	return is_state(Constants.BoardState.FINISHED)


func can_accept_input() -> bool:
	return _current_state == Constants.BoardState.WAITING_FOR_INPUT


func is_busy() -> bool:
	return _current_state != Constants.BoardState.WAITING_FOR_INPUT


func is_animating() -> bool:
	match _current_state:
		Constants.BoardState.SWAPPING,
		Constants.BoardState.DESTROYING,
		Constants.BoardState.FALLING,
		Constants.BoardState.REFILLING,
		Constants.BoardState.CASCADING,
		Constants.BoardState.SHUFFLING:
			return true

		_:
			return false


func to_string() -> String:
	match _current_state:
		Constants.BoardState.GENERATING:
			return "GENERATING"

		Constants.BoardState.WAITING_FOR_INPUT:
			return "WAITING_FOR_INPUT"

		Constants.BoardState.SWAPPING:
			return "SWAPPING"

		Constants.BoardState.CHECKING_MATCHES:
			return "CHECKING_MATCHES"

		Constants.BoardState.DESTROYING:
			return "DESTROYING"

		Constants.BoardState.FALLING:
			return "FALLING"

		Constants.BoardState.REFILLING:
			return "REFILLING"

		Constants.BoardState.CASCADING:
			return "CASCADING"

		Constants.BoardState.SHUFFLING:
			return "SHUFFLING"

		Constants.BoardState.FINISHED:
			return "FINISHED"

		_:
			return "UNKNOWN"