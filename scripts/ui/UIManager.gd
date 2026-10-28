extends Node
class_name UIManager

signal popup_opened(name)
signal popup_closed(name)
signal hud_updated

# =========================================================
# REFERENCES (ASSIGNED IN SCENE)
# =========================================================

@export var hud: HUD
@export var pause_menu: PauseMenu
@export var victory_screen: VictoryScreen
@export var game_over_screen: GameOverScreen
@export var loading_screen: LoadingScreen

@export var screens: Node
@export var popups: Node
@export var notification: Node

# =========================================================
# STATE
# =========================================================

var _current_screen: Node = null
var _open_popups: Dictionary = {}
var _input_locked: bool = false
var _is_initialized: bool = false


# =========================================================
# INITIALIZATION
# =========================================================

func initialize() -> void:
	if _is_initialized:
		return

	if hud:
		hud.initialize()

	if pause_menu:
		pause_menu.initialize(self)

	if victory_screen:
		victory_screen.initialize(self)

	if game_over_screen:
		game_over_screen.initialize(self)

	if loading_screen:
		loading_screen.initialize()

	_current_screen = null
	_open_popups.clear()
	_input_locked = false
	_is_initialized = true


# =========================================================
# SCREEN MANAGEMENT
# =========================================================

func show_screen(name: StringName) -> void:
	if screens == null:
		return

	if _current_screen:
		_current_screen.hide()

	var screen := screens.get_node_or_null(NodePath(name))

	if screen:
		screen.show()
		_current_screen = screen


func hide_screen(name: StringName) -> void:
	if screens == null:
		return

	var screen := screens.get_node_or_null(NodePath(name))

	if screen:
		screen.hide()

	if _current_screen == screen:
		_current_screen = null


# =========================================================
# POPUPS
# =========================================================

func show_popup(name: StringName, data := {}) -> void:
	if popups == null:
		return

	var popup := popups.get_node_or_null(NodePath(name))

	if popup == null:
		return

	if popup.has_method("show_popup"):
		popup.show_popup(data)
	else:
		popup.show()

	_open_popups[name] = popup
	emit_signal("popup_opened", name)


func hide_popup(name: StringName) -> void:
	if !_open_popups.has(name):
		return

	var popup: Node = _open_popups[name]

	if is_instance_valid(popup):
		if popup.has_method("hide_popup"):
			popup.hide_popup()
		else:
			popup.hide()

	_open_popups.erase(name)
	emit_signal("popup_closed", name)


func close_all_popups() -> void:
	for popup_name in _open_popups.keys():
		hide_popup(popup_name)


# =========================================================
# HUD
# =========================================================

func update_hud() -> void:
	if hud == null:
		return

	emit_signal("hud_updated")


# =========================================================
# NOTIFICATIONS
# =========================================================

func show_notification(text: String) -> void:
	if notification == null:
		return

	if notification.has_method("show_notification"):
		notification.show_notification(text)
	elif notification.has_method("show_message"):
		notification.show_message(text)
	elif notification.has_method("set_text"):
		notification.set_text(text)

	if notification.has_method("show"):
		notification.show()


func hide_notification() -> void:
	if notification == null:
		return

	if notification.has_method("hide_notification"):
		notification.hide_notification()
	elif notification.has_method("clear_message"):
		notification.clear_message()

	if notification.has_method("hide"):
		notification.hide()


# =========================================================
# LOADING
# =========================================================

func show_loading() -> void:
	if loading_screen == null:
		return

	loading_screen.show()
	loading_screen.start_loading()


func hide_loading() -> void:
	if loading_screen == null:
		return

	loading_screen.finish_loading()
	loading_screen.hide()


# =========================================================
# INPUT CONTROL
# =========================================================

func lock_input() -> void:
	_input_locked = true


func unlock_input() -> void:
	_input_locked = false


func is_input_locked() -> bool:
	return _input_locked


# =========================================================
# RESET / SHUTDOWN
# =========================================================

func reset() -> void:
	close_all_popups()
	hide_notification()

	if loading_screen:
		loading_screen.reset()

	if pause_menu:
		pause_menu.reset()

	if victory_screen:
		victory_screen.reset()

	if game_over_screen:
		game_over_screen.reset()

	if hud:
		hud.reset()

	if _current_screen:
		_current_screen.hide()

	_current_screen = null
	_input_locked = false


func shutdown() -> void:
	reset()
	_open_popups.clear()
	_is_initialized = false


	# =========================================================
# GAME FLOW INTENT FORWARDING
# (Called by UI screens only)
# =========================================================

func restart_level() -> void:
	SignalBus.game_restarted.emit()

func return_to_menu() -> void:
	SignalBus.game_quit.emit()

func request_resume_game() -> void:
	SignalBus.game_resumed.emit()

func request_restart_level() -> void:
	SignalBus.game_restarted.emit()

func request_open_settings() -> void:
	show_popup("Settings")

func request_return_to_menu() -> void:
	SignalBus.game_quit.emit()

func request_quit_game() -> void:
	SignalBus.game_quit.emit()

func request_next_level() -> void:
	SignalBus.next_level_requested.emit()
