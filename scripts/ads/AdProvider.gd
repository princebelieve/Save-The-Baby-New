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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	call_deferred("_update_consent")

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

func _update_consent() -> void:
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(), _on_consent_updated, func(_error: FormError): _finish_consent())

func _on_consent_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(func(form: ConsentForm):
			form.show(func(_error: FormError): _finish_consent()),
			func(_error: FormError): _finish_consent())
	else:
		_finish_consent()

func _finish_consent() -> void:
	var status := UserMessagingPlatform.consent_information.get_consent_status()
	_consent_ready = status == ConsentInformation.ConsentStatus.OBTAINED or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	availability_changed.emit()
	_initialize_sdk()

func _initialize_sdk() -> void:
	if not _consent_ready or _initialized or _initializing:
		return
	_initializing = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus):
		_initializing = false
		_initialized = true
		_load_ad("interstitial")
		_load_ad("rewarded")
	MobileAds.initialize(listener)

func privacy_options_required() -> bool:
	return OS.get_name() == "Android" and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if _showing or not privacy_options_required():
		return
	for ad in _ads.values():
		ad.destroy()
	_ads.clear()
	_consent_ready = false
	availability_changed.emit()
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError): _finish_consent())

func _unit_id(kind: String) -> String:
	if OS.is_debug_build():
		return TEST_REWARDED_ID if kind == "rewarded" else TEST_INTERSTITIAL_ID
	return REWARDED_ID if kind == "rewarded" else INTERSTITIAL_ID

func _load_ad(kind: String) -> void:
	if not _initialized or not _consent_ready or _loading.get(kind, false):
		return
	_loading[kind] = true
	var loaded := func(ad):
		_loading[kind] = false
		if not _consent_ready:
			ad.destroy()
			return
		_ads[kind] = ad
		_loaded_at[kind] = Time.get_ticks_msec()
		availability_changed.emit()
	var failed := func(error: LoadAdError):
		_loading[kind] = false
		_retry_at[kind] = Time.get_ticks_msec() + 60000
		print("AdMob: %s unavailable: %s" % [kind, error.message])
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
	callback.on_ad_dismissed_full_screen_content = _finish_ad
	callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError): _finish_ad()
	_active_ad.full_screen_content_callback = callback
	availability_changed.emit()
	if kind == "rewarded":
		var listener := OnUserEarnedRewardListener.new()
		listener.on_user_earned_reward = func(_item: RewardedItem):
			if _showing and _earned.is_valid():
				_earned.call()
				_earned = Callable()
		_active_ad.show(listener)
	else:
		_active_ad.show()

func _finish_ad() -> void:
	if not _showing:
		return
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
