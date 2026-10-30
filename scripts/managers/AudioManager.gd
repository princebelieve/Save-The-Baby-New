extends Node

##==============================================================================
## AudioManager
##
## Controls all game audio.
##
## Version: 1.0 (Frozen API)
##==============================================================================


#===============================================================================
# Signals
#===============================================================================

signal music_changed(track)
signal music_finished
signal sound_played(sound)


#===============================================================================
# Internal State
#===============================================================================

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_ids_by_player: Dictionary = {}

var _audio_config: Dictionary = {}
var _music_bus_name: String = "Music"
var _sfx_bus_name: String = "SFX"

var _master_volume: float = 1.0
var _music_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_enabled := true
var _sfx_enabled := true

var _muted: bool = false
var _initialized: bool = false


#===============================================================================
# Initialization
#===============================================================================

func _ready() -> void:
	initialize()


func initialize() ->void:
	if _initialized:
		return

	_initialized = true

	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

	_music_player.finished.connect(_on_music_finished)

	_load_audio_configuration()
	_music_player.bus = _music_bus_name
	_apply_bus_volumes()

	_connect_signal_bus()


#===============================================================================
# Public API
#===============================================================================

func play_music(track) -> void:
	if track == null:
		return

	var resolved_track := _resolve_audio_id("music", track)
	var stream := ResourceManager.load_audio(resolved_track)

	if stream == null:
		DebugLogger.warning("AudioManager: Unable to load music: %s" % resolved_track)
		return

	_music_player.stop()
	var music_entries = _audio_config.get("music", {})
	var entry = music_entries.get(str(track), {}) if typeof(music_entries) == TYPE_DICTIONARY else {}
	if stream is AudioStreamOggVorbis and typeof(entry) == TYPE_DICTIONARY:
		stream.loop = bool(entry.get("loop", false))
	_music_player.stream = stream
	_music_player.play()
	_music_player.stream_paused = _muted or not _music_enabled

	emit_signal("music_changed", track)

	if SignalBus:
		SignalBus.emit_signal("music_changed", track)


func stop_music() -> void:
	_music_player.stop()


func pause_music() -> void:
	if _music_player.playing:
		_music_player.stream_paused = true


func resume_music() -> void:
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = _muted or not _music_enabled


func play_sfx(sound) -> void:
	if sound == null or _muted or not _sfx_enabled:
		return

	var resolved_sound := _resolve_audio_id("sfx", sound)
	var stream := ResourceManager.load_audio(resolved_sound)
	if stream == null:
		DebugLogger.warning("AudioManager: Unable to load sound: %s" % resolved_sound)
		return
	var player := AudioStreamPlayer.new()
	player.bus = _sfx_bus_name
	player.stream = stream
	player.finished.connect(
		func():
			_sfx_players.erase(player)
			_sfx_ids_by_player.erase(player)
			player.queue_free()
	)

	add_child(player)

	_sfx_players.append(player)
	_sfx_ids_by_player[player] = sound

	player.play()

	emit_signal("sound_played", sound)


func stop_sfx(sound) -> void:
	for player in _sfx_players.duplicate():
		if _sfx_ids_by_player.get(player) != sound:
			continue
		_sfx_players.erase(player)
		_sfx_ids_by_player.erase(player)
		if is_instance_valid(player):
			player.stop()
			player.queue_free()


func set_master_volume(value) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()


func set_music_volume(value) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()


func set_sfx_volume(value) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = _muted or not _music_enabled
	_apply_bus_volumes()


func is_music_enabled() -> bool:
	return _music_enabled


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	if not _sfx_enabled:
		_stop_all_sfx()
	_apply_bus_volumes()


func is_sfx_enabled() -> bool:
	return _sfx_enabled


func get_music_volume() -> float:
	return _music_volume


func get_sfx_volume() -> float:
	return _sfx_volume


func mute() -> void:
	_muted = true
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = true
	_stop_all_sfx()
	_apply_bus_volumes()


func unmute() -> void:
	_muted = false
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = not _music_enabled
	_apply_bus_volumes()


#===============================================================================
# Internal Helpers
#===============================================================================

func _load_audio_configuration() -> void:
	if ConfigLoader == null:
		return

	_audio_config = ConfigLoader.get_config(Constants.ConfigPaths.AUDIO)

	if _audio_config.is_empty():
		return

	if _audio_config.has("volume_defaults"):
		var defaults = _audio_config["volume_defaults"]

		_master_volume = defaults.get("master", 1.0)
		_music_volume = defaults.get("music", 1.0)
		_sfx_volume = defaults.get("sfx", 1.0)

	var bus_mapping = _audio_config.get("audio_bus_mapping", {})
	if typeof(bus_mapping) == TYPE_DICTIONARY:
		_music_bus_name = str(bus_mapping.get("music", _music_bus_name))
		_sfx_bus_name = str(bus_mapping.get("sfx", _sfx_bus_name))


func _resolve_audio_id(category: String, value) -> String:
	var audio_id := str(value)
	if audio_id.begins_with("res://"):
		return audio_id
	var entries = _audio_config.get(category, {})
	if typeof(entries) == TYPE_DICTIONARY and entries.has(audio_id):
		var entry = entries[audio_id]
		if typeof(entry) == TYPE_DICTIONARY:
			return str(entry.get("path", ""))
		return str(entry)
	return audio_id


func _apply_bus_volumes() -> void:
	var master := _master_volume
	var music := _music_volume if _music_enabled else 0.0
	var sfx := _sfx_volume if _sfx_enabled else 0.0

	if _muted:
		master = 0.0
		music = 0.0
		sfx = 0.0

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus != -1:
		AudioServer.set_bus_mute(master_bus, _muted)
		AudioServer.set_bus_volume_db(
			master_bus,
			_linear_to_db(master)
		)
	var music_bus := AudioServer.get_bus_index(_music_bus_name)
	if music_bus != -1:
		AudioServer.set_bus_mute(music_bus, _muted or not _music_enabled)
		AudioServer.set_bus_volume_db(
			music_bus,
			_linear_to_db(music)
		)

	var sfx_bus := AudioServer.get_bus_index(_sfx_bus_name)
	if sfx_bus != -1:
		AudioServer.set_bus_mute(sfx_bus, _muted or not _sfx_enabled)
		AudioServer.set_bus_volume_db(
			sfx_bus,
			_linear_to_db(sfx)
		)


func _stop_all_sfx() -> void:
	for player in _sfx_players.duplicate():
		_sfx_players.erase(player)
		_sfx_ids_by_player.erase(player)
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_sfx_players.clear()
	_sfx_ids_by_player.clear()


func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0

	return linear_to_db(value)


func _connect_signal_bus() -> void:
	if SignalBus == null:
		return

	if not SignalBus.play_music.is_connected(play_music):
		SignalBus.play_music.connect(play_music)

	if not SignalBus.stop_music.is_connected(stop_music):
		SignalBus.stop_music.connect(stop_music)

	if not SignalBus.play_sfx.is_connected(play_sfx):
		SignalBus.play_sfx.connect(play_sfx)


func _on_music_finished() -> void:
	emit_signal("music_finished")

	if SignalBus:
		SignalBus.emit_signal("music_finished")
