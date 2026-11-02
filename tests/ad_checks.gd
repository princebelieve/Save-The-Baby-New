extends SceneTree

class FakeProvider extends RefCounted:
	var earned: Callable
	var closed: Callable
	func is_ad_ready(_kind: String) -> bool:
		return true
	func show_ad(_kind: String, _placement: String, on_earned: Callable, on_closed: Callable) -> void:
		earned = on_earned
		closed = on_closed

func _initialize() -> void:
	var ads := AdManager.new()
	assert(not ads.available("rewarded"))
	assert(not ads.show_ad("rewarded", "no_provider"))
	var provider := FakeProvider.new()
	ads.configure(provider)
	assert(ads.show_ad("rewarded", "life"))
	assert(not ads.show_ad("rewarded", "other"))
	provider.closed.call()
	assert(not ads.claimed("life"))
	assert(ads.show_ad("rewarded", "life"))
	var old_reward := provider.earned
	var old_close := provider.closed
	provider.earned.call()
	provider.earned.call()
	provider.closed.call()
	assert(ads.claimed("life"))
	assert(not ads.show_ad("rewarded", "life"))
	assert(ads.show_ad("rewarded", "coins"))
	old_reward.call()
	old_close.call()
	assert(ads.busy)
	provider.closed.call()
	assert(not ads.claimed("coins"))
	assert(ads.show_ad("interstitial", "level_end"))
	provider.earned.call()
	provider.closed.call()
	assert(not ads.claimed("level_end"))
	ads.free()
	print("Ad checks passed")
	quit()
