extends SceneTree

class TestProvider extends "res://scripts/ads/AdProvider.gd":
	var reloads := 0
	func _load_ad(_kind: String) -> void:
		reloads += 1

class FakeAd extends RefCounted:
	var full_screen_content_callback: FullScreenContentCallback
	var reward_listener: OnUserEarnedRewardListener
	var destroyed := false
	func show(listener = null) -> void:
		reward_listener = listener
	func destroy() -> void:
		destroyed = true
		full_screen_content_callback = null
		reward_listener = null

var rewards := 0
var closes := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var provider := TestProvider.new()
	root.add_child(provider)
	assert(not provider.is_ad_ready("rewarded"))
	provider._initialized = true
	provider._consent_ready = true
	provider.set_process(false)
	var original_mute := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, false)
	var ad := FakeAd.new()
	provider._ads["rewarded"] = ad
	provider._loaded_at["rewarded"] = Time.get_ticks_msec()
	assert(provider.is_ad_ready("rewarded"))
	provider.show_ad("rewarded", "test", func(): rewards += 1, func(): closes += 1)
	assert(paused and AudioServer.is_bus_mute(0))
	assert(not provider.is_ad_ready("rewarded"))
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	assert(rewards == 0 and closes == 1)
	assert(not paused and not AudioServer.is_bus_mute(0) and ad.destroyed)
	ad = FakeAd.new()
	provider._ads["rewarded"] = ad
	provider._loaded_at["rewarded"] = Time.get_ticks_msec()
	paused = true
	AudioServer.set_bus_mute(0, true)
	provider.show_ad("rewarded", "test", func(): rewards += 1, func(): closes += 1)
	ad.reward_listener.on_user_earned_reward.call(null)
	ad.reward_listener.on_user_earned_reward.call(null)
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	assert(rewards == 1 and closes == 2)
	assert(paused and AudioServer.is_bus_mute(0))
	paused = false
	ad = FakeAd.new()
	provider._ads["interstitial"] = ad
	provider._loaded_at["interstitial"] = Time.get_ticks_msec()
	provider.show_ad("interstitial", "test", func(): rewards += 1, func(): closes += 1)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	assert(not paused and closes == 3 and rewards == 1)
	assert(provider.reloads == 3)
	provider._ads["interstitial"] = FakeAd.new()
	provider._loaded_at["interstitial"] = Time.get_ticks_msec() - provider.MAX_AD_AGE_MS
	assert(not provider.is_ad_ready("interstitial"))
	AudioServer.set_bus_mute(0, original_mute)
	ad = null
	provider.queue_free()
	await process_frame
	print("Ad provider checks passed")
	quit()
