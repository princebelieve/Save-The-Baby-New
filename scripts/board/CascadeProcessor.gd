extends Node
class_name CascadeProcessor

# =========================================================
# INTERNAL STATE
# =========================================================

var _is_processing: bool = false
var _should_stop: bool = false

var _match_finder = null
var _gravity_solver = null
var _refill_system = null


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_match_finder = MatchFinder.new()
	_gravity_solver = GravitySolver.new()
	_refill_system = RefillSystem.new()

	_match_finder.initialize()
	_gravity_solver.initialize()
	_refill_system.initialize()


# =========================================================
# PUBLIC API
# =========================================================

func process(board) -> void:
	if board == null:
		return

	_is_processing = true
	_should_stop = false

	_process_cycle(board)

	_is_processing = false


func has_cascade(board) -> bool:
	if board == null:
		return false

	if _match_finder.has_matches(board):
		return true

	if _gravity_solver.has_floating_tiles(board):
		return true

	if _refill_system.needs_refill(board):
		return true

	return false


func is_processing() -> bool:
	return _is_processing


func stop() -> void:
	_should_stop = true


# =========================================================
# INTERNAL LOOP
# =========================================================

func _process_cycle(board) -> void:
	while not _should_stop:

		# 1. Detect matches
		var matches = _match_finder.find_all_matches(board)

		if matches.is_empty():
			# No matches → resolve gravity/refill one last time
			_gravity_solver.apply_gravity(board)
			_refill_system.refill(board)

			# If still stable, exit loop
			if not has_cascade(board):
				break
			else:
				continue

		# 2. Remove matched tiles
		for match in matches:
			for tile in match.get_tiles():
				var pos = tile.get_grid_position()
				board.remove_tile(pos)

		# 3. Apply gravity
		_gravity_solver.apply_gravity(board)

		# 4. Refill board
		_refill_system.refill(board)

		# 5. Safety check
		if not has_cascade(board):
			break