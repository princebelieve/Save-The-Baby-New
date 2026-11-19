extends Node

signal availability_changed

const INTERSTITIAL_ID := "ca-app-pub-7480928068306811/3957444262"
const REWARDED_ID := "ca-app-pub-7480928068306811/7596260199"
const TEST_INTERSTITIAL_ID := "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const MAX_AD_AGE_MS := 50 * 60 * 1000
var _initialized := false
var _initializing := false
var _consent_ready := false
var _ads: Dictionary = {}
var _loading: Dictionary = {}
var _loaded_at: Dictionary = {}
var _retry_at: Dictionary = {}
var _showing := false
var _earned: Callable
var _closed: Callable
var _active_kind := ""
var _active_ad: Variant
var _was_paused := false
var _was_muted := false
var _cover: CanvasLayer
var _show_generation := 0
var _shown_at_ms := -1
var _reward_was_earned := false
var _unity_privacy_prepared := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	if OS.has_feature("editor") and OS.is_debug_build() and DisplayServer.get_name() != "headless" and OS.get_name() != "Android" and "--ad-preview" in OS.get_cmdline_user_args():
		var factory = load("res://addons/admob/internal/mock/mock_admob_factory.gd")
		for name in ["PoingGodotAdMob", "PoingGodotAdMobInterstitialAd", "PoingGodotAdMobRewardedAd"]:
			factory.get_mock_plugin(name).process_mode = Node.PROCESS_MODE_ALWAYS
		print("EDITOR AD PREVIEW: simulated ads and rewards; no Google network requests.")
		_consent_ready = true
		_initialize_sdk()
		return
	if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
		return
	# Boot starts consent after the company splash is finished.

func start_session() -> void:
	if OS.get_name() != "Android":
		return
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	var privacy := get_node_or_null("/root/AppPrivacy")
	if privacy != null:
		if not privacy.state_changed.is_connected(_on_privacy_changed):
			privacy.state_changed.connect(_on_privacy_changed)
		_on_privacy_changed()

func _on_privacy_changed() -> void:
	var privacy := get_node_or_null("/root/AppPrivacy")
	_consent_ready = privacy != null and privacy.ad_requests_allowed()
	if not _consent_ready:
		for ad in _ads.values():
			ad.destroy()
		_ads.clear()
	availability_changed.emit()
	if OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob"):
		_initialize_sdk()

func _process(_delta: float) -> void:
	if not _initialized or not _consent_ready or _showing:
		return
	for kind in ["interstitial", "rewarded"]:
		if not _ads.has(kind) and not _loading.get(kind, false) and Time.get_ticks_msec() >= int(_retry_at.get(kind, 0)):
			_load_ad(kind)
		elif _ads.has(kind) and Time.get_ticks_msec() - int(_loaded_at.get(kind, 0)) >= MAX_AD_AGE_MS:
			_ads[kind].destroy()
			_ads.erase(kind)
			availability_changed.emit()

func _request_configuration() -> RequestConfiguration:
	var configuration := RequestConfiguration.new()
	configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	var audience := get_node_or_null("/root/AudienceSettings")
	var group := str(audience.age_group) if audience != null else "unknown"
	# G limits ad content; it does not imply that every player is a child.
	if group == "under_13":
		configuration.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
	if group in ["under_13", "13_15"]:
		configuration.tag_for_under_age_of_consent = RequestConfiguration.TagForUnderAgeOfConsent.TRUE
	return configuration

func _initialize_sdk() -> void:
	if not _consent_ready or _initialized or _initializing:
		return
	_initializing = true
	if not _prepare_mediation_privacy():
		_initializing = false
		return
	print("AdMob: initializing SDK; units=%s" % ("demo" if OS.is_debug_build() else "production"))
	# Apply before initialization, which may itself preload ads. The pinned
	# Android bridge uses play-services-ads, whose configuration supports this.
	var configuration := _request_configuration()
	print("AdMob request flags: " + JSON.stringify(configuration.convert_to_dictionary()))
	MobileAds.set_request_configuration(configuration)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus):
		_initializing = false
		_initialized = true
		print("AdMob: SDK initialized")
		for adapter_name in _status.adapter_status_map:
			var adapter = _status.adapter_status_map[adapter_name]
			print("AdMob adapter: %s; state=%s" % [adapter_name, adapter.initialization_state])
		_load_ad("interstitial")
		_load_ad("rewarded")
	MobileAds.initialize(listener)

func privacy_options_required() -> bool:
	var privacy := get_node_or_null("/root/AppPrivacy")
	return privacy != null and privacy.privacy_options_required()

func show_privacy_options() -> void:
	var privacy := get_node_or_null("/root/AppPrivacy")
	if privacy != null and not _showing:
		privacy.show_privacy_options()

func _unit_id(kind: String) -> String:
	if OS.is_debug_build():
		return TEST_REWARDED_ID if kind == "rewarded" else TEST_INTERSTITIAL_ID
	return REWARDED_ID if kind == "rewarded" else INTERSTITIAL_ID

func _prepare_mediation_privacy() -> bool:
	if OS.get_name() != "Android":
		return true
	if not Engine.has_singleton("UnityAdsPrivacy"):
		push_error("AdMob: Unity Ads privacy bridge is missing; not requesting ads")
		return false
	var prepared := bool(Engine.get_singleton("UnityAdsPrivacy").prepareContextualAds())
	if prepared and not _unity_privacy_prepared:
		_unity_privacy_prepared = true
		print("AdMob: Unity privacy bridge ready; contextual metadata committed")
	return prepared

func _load_ad(kind: String) -> void:
	if not _initialized or not _consent_ready or _loading.get(kind, false):
		return
	if not _prepare_mediation_privacy():
		_retry_at[kind] = Time.get_ticks_msec() + 60000
		return
	_loading[kind] = true
	var loaded := func(ad):
		_loading[kind] = false
		if not _consent_ready:
			ad.destroy()
			return
		print("AdMob: %s loaded" % kind)
		print("AdMob response: " + JSON.stringify(_describe_ad_response(kind, ad)))
		_ads[kind] = ad
		_loaded_at[kind] = Time.get_ticks_msec()
		availability_changed.emit()
	var failed := func(error: LoadAdError):
		_loading[kind] = false
		_retry_at[kind] = Time.get_ticks_msec() + 60000
		print("AdMob: %s unavailable: code=%s domain=%s message=%s" % [kind, error.code, error.domain, error.message])
		availability_changed.emit()
	if kind == "rewarded":
		var callback := RewardedAdLoadCallback.new()
		callback.on_ad_loaded = loaded
		callback.on_ad_failed_to_load = failed
		RewardedAdLoader.new().load(_unit_id(kind), AdRequest.new(), callback)
	else:
		var callback := InterstitialAdLoadCallback.new()
		callback.on_ad_loaded = loaded
		callback.on_ad_failed_to_load = failed
		InterstitialAdLoader.new().load(_unit_id(kind), AdRequest.new(), callback)

func is_ad_ready(kind: String) -> bool:
	return _initialized and _consent_ready and not _showing and _ads.has(kind) and Time.get_ticks_msec() - int(_loaded_at.get(kind, 0)) < MAX_AD_AGE_MS

func show_ad(kind: String, _placement: String, earned: Callable, closed: Callable) -> void:
	if not is_ad_ready(kind):
		closed.call_deferred()
		return
	_showing = true
	_show_generation += 1
	_shown_at_ms = -1
	_reward_was_earned = false
	print("AdMob: showing %s; placement=%s; presentation=%d" % [kind, _placement, _show_generation])
	var generation := _show_generation
	_earned = earned
	_closed = closed
	_active_kind = kind
	_active_ad = _ads[kind]
	_ads.erase(kind)
	_was_paused = get_tree().paused
	_was_muted = AudioServer.is_bus_mute(0)
	get_tree().paused = true
	AudioServer.set_bus_mute(0, true)
	_cover = CanvasLayer.new()
	_cover.layer = 99
	_cover.process_mode = Node.PROCESS_MODE_ALWAYS
	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.85)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(blocker)
	add_child(_cover)
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func(): _finish_ad(generation)
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError): _finish_ad(generation)
	callback.on_ad_showed_full_screen_content = func():
		if not _showing or generation != _show_generation: return
		_shown_at_ms = Time.get_ticks_msec()
		print("AdMob: native ad displayed; presentation=%d" % generation)
	_active_ad.full_screen_content_callback = callback
	availability_changed.emit()
	if kind == "rewarded":
		var listener := OnUserEarnedRewardListener.new()
		listener.on_user_earned_reward = func(_item: RewardedItem):
			if _showing and generation == _show_generation and _active_kind == "rewarded" and _earned.is_valid():
				_reward_was_earned = true
				print("AdMob: reward earned; presentation=%d; elapsed_ms=%d" % [generation, _presentation_elapsed_ms()])
				_earned.call()
				_earned = Callable()
		_active_ad.show(listener)
	else:
		_active_ad.show()

func _describe_ad_response(kind: String, ad: Object) -> Dictionary:
	var details := {"kind": kind, "unit_id": _unit_id(kind)}
	if not ad.has_method("get_response_info"): return details
	var response = ad.get_response_info()
	if response == null: return details
	details["response_id"] = response.response_id
	details["adapter"] = response.mediation_adapter_class_name
	var source = response.loaded_adapter_response_info
	if source != null:
		details["ad_source"] = source.ad_source_name
	# Never dump response extras or adapter credentials/mappings.
	return details


func _presentation_elapsed_ms() -> int:
	return Time.get_ticks_msec() - _shown_at_ms if _shown_at_ms >= 0 else -1


func _finish_ad(generation := -1) -> void:
	if not _showing or (generation != -1 and generation != _show_generation):
		return
	print("AdMob: presentation closed; kind=%s; presentation=%d; elapsed_ms=%d; earned=%s" % [_active_kind, _show_generation, _presentation_elapsed_ms(), _reward_was_earned])
	_showing = false
	_active_ad.destroy()
	_active_ad = null
	_cover.queue_free()
	get_tree().paused = _was_paused
	AudioServer.set_bus_mute(0, _was_muted)
	var closed := _closed
	_closed = Callable()
	_earned = Callable()
	closed.call()
	_load_ad(_active_kind)
	availability_changed.emit()

func _exit_tree() -> void:
	for ad in _ads.values():
		ad.destroy()
	_ads.clear()
	if _showing and _active_ad != null:
		_active_ad.destroy()
		AudioServer.set_bus_mute(0, _was_muted)
	_active_ad = null
	_closed = Callable()
	_earned = Callable()
