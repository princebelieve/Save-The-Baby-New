extends Node
class_name BoardAnimator

# =========================================================
# INTERNAL STATE
# =========================================================

var _animation_manager: AnimationManager = null
var _active_requests: Dictionary = {}  # board -> current animation state


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	_animation_manager = AnimationManager.new()
	_animation_manager.initialize()
	_active_requests.clear()


# =========================================================
# LIFECYCLE ANIMATIONS
# =========================================================

func play_enter(board) -> void:
	_execute("board_enter", board)


func play_exit(board) -> void:
	_execute("board_exit", board)


func play_transition(board) -> void:
	_execute("board_transition", board)


func play_ready(board) -> void:
	_execute("board_ready", board)


# =========================================================
# GAMEPLAY STATE ANIMATIONS
# =========================================================

func play_shuffle(board) -> void:
	_execute("board_shuffle", board)


func play_invalid_move(board) -> void:
	_execute("board_invalid_move", board)


func play_hint(board) -> void:
	_execute("board_hint", board)


func play_complete(board) -> void:
	_execute("board_complete", board)


func play_fail(board) -> void:
	_execute("board_fail", board)


# =========================================================
# CAMERA / BOARD MOTION
# =========================================================

func play_shake(board) -> void:
	_execute("board_shake", board)


func play_bounce(board) -> void:
	_execute("board_bounce", board)


func play_zoom_in(board) -> void:
	_execute("board_zoom_in", board)


func play_zoom_out(board) -> void:
	_execute("board_zoom_out", board)


func play_focus(board) -> void:
	_execute("board_focus", board)


func play_pan(board) -> void:
	_execute("board_pan", board)


# =========================================================
# VISIBILITY ANIMATIONS
# =========================================================

func play_show(board) -> void:
	_execute("board_show", board)


func play_hide(board) -> void:
	_execute("board_hide", board)


func play_fade_in(board) -> void:
	_execute("board_fade_in", board)


func play_fade_out(board) -> void:
	_execute("board_fade_out", board)


# =========================================================
# STATE ANIMATIONS
# =========================================================

func play_lock(board) -> void:
	_execute("board_lock", board)


func play_unlock(board) -> void:
	_execute("board_unlock", board)


# =========================================================
# UTILITY CONTROL
# =========================================================

func stop(board) -> void:
	if board == null:
		return

	if _active_requests.has(board):
		_animation_manager.stop(board)
		_active_requests.erase(board)


func stop_all() -> void:
	_animation_manager.stop_all()
	_active_requests.clear()


func pause(board) -> void:
	if board == null:
		return

	if _animation_manager.is_playing(board):
		_animation_manager.pause_all()


func resume(board) -> void:
	_animation_manager.resume_all()


func is_playing(board) -> bool:
	return board != null and _animation_manager.is_playing(board)


func wait_until_finished(board) -> void:
	if board == null:
		return

	await _animation_manager.wait_for_animation(board)


# =========================================================
# INTERNAL DISPATCH
# =========================================================

func _execute(animation_name: String, board) -> void:
	if board == null:
		return

	# Create animation request
	var request := AnimationRequest.new()
	request.animation_name = animation_name
	request.target = board

	# Track active request
	_active_requests[board] = request

	# Forward to AnimationManager
	_animation_manager.play(animation_name, board)

	# Optional cleanup hook
	if request.has_signal("finished"):
		request.finished.connect(_on_finished.bind(board), CONNECT_ONE_SHOT)


func _on_finished(board) -> void:
	if _active_requests.has(board):
		_active_requests.erase(board)
