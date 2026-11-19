extends Node

class TestProvider extends "res://scripts/ads/AdProvider.gd":
	var reloads := 0
	func _load_ad(_kind: String) -> void:
		reloads += 1

class FakeAd extends RefCounted:
	var full_screen_content_callback: FullScreenContentCallback
	var reward_listener: OnUserEarnedRewardListener
	var destroyed := false
	var response_info: ResponseInfo
	func get_response_info() -> ResponseInfo:
		return response_info
	func show(listener = null) -> void:
		reward_listener = listener
	func destroy() -> void:
		destroyed = true
		full_screen_content_callback = null
		reward_listener = null

var rewards := 0
var closes := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var provider := TestProvider.new()
	get_tree().root.add_child(provider)
	var configuration := provider._request_configuration().convert_to_dictionary()
	assert(configuration.max_ad_content_rating == "G")
	assert(configuration.tag_for_child_directed_treatment == -1)
	var audience := get_node("/root/AudienceSettings")
	audience.age_group = "under_13"
	var child_configuration := provider._request_configuration().convert_to_dictionary()
	assert(child_configuration.max_ad_content_rating == "G")
	assert(child_configuration.tag_for_child_directed_treatment == 1)
	assert(child_configuration.tag_for_under_age_of_consent == 1)
	audience.age_group = "unknown"
	assert(configuration.tag_for_under_age_of_consent == -1)
	assert(not provider.is_ad_ready("rewarded"))
	provider._initialized = true
	provider._consent_ready = true
	provider.set_process(false)
	var original_mute := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, false)
	var ad := FakeAd.new()
	ad.response_info = ResponseInfo.new(null, [], {"private_extra": "omit"}, "test_adapter", "test_response")
	var details := provider._describe_ad_response("rewarded", ad)
	assert(details.response_id == "test_response" and details.adapter == "test_adapter")
	assert(not details.has("response_extras") and not details.has("ad_unit_mapping"))
	provider._ads["rewarded"] = ad
	provider._loaded_at["rewarded"] = Time.get_ticks_msec()
	assert(provider.is_ad_ready("rewarded"))
	provider.show_ad("rewarded", "test", func(): rewards += 1, func(): closes += 1)
	assert(get_tree().paused and AudioServer.is_bus_mute(0))
	assert(not provider.is_ad_ready("rewarded"))
	ad.full_screen_content_callback.on_ad_showed_full_screen_content.call()
	assert(provider._presentation_elapsed_ms() >= 0)
	var stale_shown := ad.full_screen_content_callback.on_ad_showed_full_screen_content
	var stale_reward := ad.reward_listener.on_user_earned_reward
	var stale_close := ad.full_screen_content_callback.on_ad_dismissed_full_screen_content
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	assert(rewards == 0 and closes == 1)
	assert(not get_tree().paused and not AudioServer.is_bus_mute(0) and ad.destroyed)
	ad = FakeAd.new()
	provider._ads["rewarded"] = ad
	provider._loaded_at["rewarded"] = Time.get_ticks_msec()
	get_tree().paused = true
	AudioServer.set_bus_mute(0, true)
	provider.show_ad("rewarded", "test", func(): rewards += 1, func(): closes += 1)
	stale_shown.call()
	assert(provider._shown_at_ms == -1)
	stale_reward.call(null)
	stale_close.call()
	assert(rewards == 0 and closes == 1 and provider._showing)
	ad.full_screen_content_callback.on_ad_showed_full_screen_content.call()
	ad.reward_listener.on_user_earned_reward.call(null)
	assert(provider._reward_was_earned)
	ad.reward_listener.on_user_earned_reward.call(null)
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	assert(rewards == 1 and closes == 2)
	assert(get_tree().paused and AudioServer.is_bus_mute(0))
	get_tree().paused = false
	ad = FakeAd.new()
	provider._ads["interstitial"] = ad
	provider._loaded_at["interstitial"] = Time.get_ticks_msec()
	provider.show_ad("interstitial", "test", func(): rewards += 1, func(): closes += 1)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content.call(null)
	assert(not get_tree().paused and closes == 3 and rewards == 1)
	assert(provider.reloads == 3)
	provider._ads["interstitial"] = FakeAd.new()
	provider._loaded_at["interstitial"] = Time.get_ticks_msec() - provider.MAX_AD_AGE_MS
	assert(not provider.is_ad_ready("interstitial"))
	AudioServer.set_bus_mute(0, original_mute)
	ad = null
	provider.queue_free()
	await get_tree().process_frame
	print("Ad provider checks passed")
	get_tree().quit()
