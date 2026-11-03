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
var _preferences_timer: Timer
var _preferences_dirty := false
var _current_music_track := ""
var _application_suspended := false
var _voice_player: AudioStreamPlayer
var _voice_current_id := ""
var _music_volume_db_before_voice := 0.0
var _pending_voice: Dictionary = {}
var _voice_not_before := 0
var _last_praise_tick := -10000
var _last_sfx_tick: Dictionary = {}


#===============================================================================
# Initialization
#===============================================================================

func _ready() -> void:
	initialize()


func initialize() ->void:
	if _initialized:
		return

	_initialized = true
	_preferences_timer = Timer.new()
	_preferences_timer.one_shot = true
	_preferences_timer.wait_time = 0.25
	_preferences_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_preferences_timer.timeout.connect(_flush_preferences)
	add_child(_preferences_timer)

	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	_music_player.finished.connect(_on_music_finished)
	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)
	_voice_player.finished.connect(_on_voice_finished)

	_load_audio_configuration()
	_load_preferences()
	_ensure_audio_bus(_music_bus_name)
	_ensure_audio_bus(_sfx_bus_name)
	_music_player.bus = _music_bus_name
	_voice_player.bus = _sfx_bus_name
	_apply_bus_volumes()

	_connect_signal_bus()


#===============================================================================
# Public API
#===============================================================================

func play_music(track) -> void:
	if track == null:
		return
	if _current_music_track == str(track) and _music_player.playing:
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
	_current_music_track = str(track)
	_music_player.play()
	_music_player.stream_paused = _application_suspended or _muted or not _music_enabled

	emit_signal("music_changed", track)

	if SignalBus:
		SignalBus.emit_signal("music_changed", track)


func stop_music() -> void:
	_music_player.stop()
	_current_music_track = ""


func pause_music() -> void:
	if _music_player.playing:
		_music_player.stream_paused = true


func resume_music() -> void:
	if _music_player != null and _music_player.stream != null:
		_music_player.stream_paused = _application_suspended or _muted or not _music_enabled
		if not _current_music_track.is_empty() and not _music_player.playing:
			_music_player.play()


func play_sfx(sound) -> void:
	if sound == null or _muted or not _sfx_enabled:
		return

	var resolved_sound := _resolve_audio_id("sfx", sound)
	var stream := ResourceManager.load_audio(resolved_sound)
	if stream == null:
		DebugLogger.warning("AudioManager: Unable to load sound: %s" % resolved_sound)
		return
	var id := str(sound)
	var cues: Dictionary = _audio_config.get("voice_cues", {})
	if cues.has(id):
		_queue_voice(id, stream, cues[id])
		return
	var now := Time.get_ticks_msec()
	var limits: Dictionary = _audio_config.get("sfx_limits", {}).get(id, {})
	if now - int(_last_sfx_tick.get(id, -10000)) < int(limits.get("cooldown_ms", 45)):
		return
	var instances := 0
	for active_id in _sfx_ids_by_player.values():
		if str(active_id) == id: instances += 1
	if instances >= int(limits.get("max_instances", 3)) or _sfx_players.size() >= 20:
		return
	_last_sfx_tick[id] = now
	if _is_impact_id(id):
		_voice_not_before = now + 180
		# A new move takes precedence over optional praise. Never stack speech
		# over a fresh explosion or resume a word halfway through.
		if _voice_player.playing and _voice_priority(_voice_current_id) < 80:
			_stop_voice()
	if _voice_player.playing:
		return
	var player := AudioStreamPlayer.new()
	player.bus = _sfx_bus_name
	player.stream = stream
	player.volume_db = float(_audio_config.get("sfx_gain_db", {}).get(id, 0.0))
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
	if str(_pending_voice.get("id", "")) == str(sound): _pending_voice.clear()
	if _voice_current_id == str(sound):
		_stop_voice()
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
	_save_preferences()


func set_music_volume(value) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_save_preferences()


func set_sfx_volume(value) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volumes()
	_save_preferences()


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if _music_player != null and _music_player.playing:
		_music_player.stream_paused = _muted or not _music_enabled
	_apply_bus_volumes()
	_save_preferences()


func is_music_enabled() -> bool:
	return _music_enabled


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	if not _sfx_enabled:
		_stop_all_sfx()
	_apply_bus_volumes()
	_save_preferences()


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

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _load_preferences() -> void:
	var preferences := ConfigFile.new()
	if CampaignProgressStore.read(preferences, "user://audio_preferences.cfg") != OK:
		return
	_master_volume = clampf(float(preferences.get_value("audio", "master", _master_volume)), 0.0, 1.0)
	_music_volume = clampf(float(preferences.get_value("audio", "music", _music_volume)), 0.0, 1.0)
	_sfx_volume = clampf(float(preferences.get_value("audio", "sfx", _sfx_volume)), 0.0, 1.0)
	_music_enabled = bool(preferences.get_value("audio", "music_enabled", true))
	_sfx_enabled = bool(preferences.get_value("audio", "sfx_enabled", true))


func _save_preferences() -> void:
	_preferences_dirty = true
	if _preferences_timer != null and _preferences_timer.is_inside_tree():
		_preferences_timer.start()
	else:
		_flush_preferences()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_flush_preferences()
		_application_suspended = true
		if _music_player != null: _music_player.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_application_suspended = false
		resume_music()


func _exit_tree() -> void:
	_flush_preferences()


func _flush_preferences() -> void:
	if not _preferences_dirty:
		return
	var preferences := ConfigFile.new()
	preferences.set_value("audio", "master", _master_volume)
	preferences.set_value("audio", "music", _music_volume)
	preferences.set_value("audio", "sfx", _sfx_volume)
	preferences.set_value("audio", "music_enabled", _music_enabled)
	preferences.set_value("audio", "sfx_enabled", _sfx_enabled)
	var error := CampaignProgressStore.write(preferences, "user://audio_preferences.cfg")
	if error != OK:
		push_warning("Could not save audio preferences: %s" % error_string(error))
	else:
		_preferences_dirty = false


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
	_pending_voice.clear()
	_stop_voice()
	for player in _sfx_players.duplicate():
		_sfx_players.erase(player)
		_sfx_ids_by_player.erase(player)
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_sfx_players.clear()
	_sfx_ids_by_player.clear()


func _is_impact_id(id: String) -> bool:
	return id.begins_with("powerup_") or id in [
		"thunder_crack", "thunder_roll", "rocket_launch", "rocket_shot",
		"tile_burst", "tile_drop", "board_rumble"
	]


func _voice_priority(id: String) -> int:
	return int(_audio_config.get("voice_cues", {}).get(id, {}).get("priority", 0))


func _duck_music_for_voice() -> void:
	if _music_player == null:
		return
	_music_volume_db_before_voice = _music_player.volume_db
	_music_player.volume_db = -8.0


func _restore_music_after_voice() -> void:
	if _music_player != null:
		_music_player.volume_db = _music_volume_db_before_voice


func _stop_voice() -> void:
	if _voice_player != null:
		_voice_player.stop()
	_voice_current_id = ""
	_restore_music_after_voice()


func _on_voice_finished() -> void:
	_voice_current_id = ""
	_restore_music_after_voice()


func _queue_voice(id: String, stream: AudioStream, cue: Dictionary) -> void:
	var now := Time.get_ticks_msec()
	var priority := int(cue.get("priority", 10))
	if bool(cue.get("praise", false)) and now - _last_praise_tick < 4200: return
	if _voice_player.playing:
		if priority < 80: return
		if priority <= _voice_priority(_voice_current_id): return
		_stop_voice()
	if not _pending_voice.is_empty() and int(_pending_voice["priority"]) > priority: return
	# Busy rocket salvos and multi-wave cascades can take several seconds. Keep
	# praise queued until the effects finish instead of silently dropping it.
	var queue_lifetime := 15000 if bool(cue.get("praise", false)) else 5000
	_pending_voice = {"id": id, "stream": stream, "priority": priority, "expires": now + queue_lifetime, "praise": bool(cue.get("praise", false))}
	_voice_not_before = maxi(_voice_not_before, now + 220)


func _process(_delta: float) -> void:
	if _pending_voice.is_empty() or _muted or not _sfx_enabled or _application_suspended: return
	var now := Time.get_ticks_msec()
	if now > int(_pending_voice["expires"]):
		_pending_voice.clear()
		return
	if _voice_player.playing or now < _voice_not_before: return
	for player in _sfx_players:
		if is_instance_valid(player) and player.playing:
			_voice_not_before = now + 100
			return
	var cue := _pending_voice.duplicate()
	_pending_voice.clear()
	_voice_current_id = str(cue["id"])
	_voice_player.stream = cue["stream"]
	_voice_player.volume_db = -1.5 if int(cue["priority"]) >= 80 else 0.0
	_duck_music_for_voice()
	_voice_player.play()
	if bool(cue["praise"]): _last_praise_tick = now
	sound_played.emit(_voice_current_id)


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
