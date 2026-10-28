extends Node
class_name CascadeProcessor

var _is_processing: bool = false
var _should_stop: bool = false
var _match_finder: MatchFinder
var _gravity_solver: GravitySolver
var _refill_system: RefillSystem


func initialize(match_finder: MatchFinder, gravity_solver: GravitySolver, refill_system: RefillSystem) -> void:
	_match_finder = match_finder
	_gravity_solver = gravity_solver
	_refill_system = refill_system


func process(board) -> void:
	if board == null or _match_finder == null:
		return
	_is_processing = true
	_should_stop = false
	for _cycle in range(100):
		if _should_stop:
			break
		var matches: Array = _match_finder.find_all_matches(board)
		if matches.is_empty():
			break
		for found_match in matches:
			for tile in found_match.get_tiles():
				board.remove_tile(tile.get_grid_position())
		_gravity_solver.apply_gravity(board)
		_refill_system.refill(board)
	_is_processing = false


func has_cascade(board) -> bool:
	return board != null and _match_finder != null and _match_finder.has_matches(board)


func is_cascade_processing() -> bool:
	return _is_processing


func stop() -> void:
	_should_stop = true
