extends SceneTree

class FakeBridge extends RefCounted:
	var configured := true
	var vendor_consent := false
	var starts := 0
	var stops := 0
	func isConfigured() -> bool: return configured
	func measurementPermitted(not_required: bool) -> bool: return not_required or vendor_consent
	func startTracking() -> void: starts += 1
	func stopTracking() -> void: stops += 1

class TestPromotion extends "res://scripts/ads/PromotionAttribution.gd":
	var native := FakeBridge.new()
	var has_bridge := true
	func _bridge() -> Object: return native if has_bridge else null

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var promotion := TestPromotion.new()
	root.add_child(promotion)
	for group in ["under_13", "13_15", "", "invalid"]:
		promotion.update_session(group, true, ConsentInformation.ConsentStatus.NOT_REQUIRED)
		assert(promotion.native.starts == 0)
	promotion.update_session("adult", false, ConsentInformation.ConsentStatus.NOT_REQUIRED)
	assert(promotion.native.starts == 0)
	promotion.update_session("adult", true, ConsentInformation.ConsentStatus.OBTAINED)
	assert(promotion.native.starts == 0, "Google consent alone must not authorize TikTok")
	promotion.update_session("adult", true, ConsentInformation.ConsentStatus.NOT_REQUIRED)
	assert(promotion.native.starts == 1, "Background startup needs no custom player approval")
	assert(promotion.get_child_count() == 0, "No TikTok-specific popup or settings UI")
	promotion.native.vendor_consent = true
	promotion.update_session("16_17", true, ConsentInformation.ConsentStatus.OBTAINED)
	assert(promotion.native.starts == 2)
	promotion.native.vendor_consent = false
	var previous := promotion.native.starts
	promotion.update_session("adult", true, ConsentInformation.ConsentStatus.OBTAINED)
	assert(promotion.native.starts == previous, "Vendor withdrawal must stop measurement")
	promotion.native.configured = false
	promotion.update_session("adult", true, ConsentInformation.ConsentStatus.NOT_REQUIRED)
	assert(promotion.native.starts == previous)
	promotion.has_bridge = false
	promotion.update_session("adult", true, ConsentInformation.ConsentStatus.NOT_REQUIRED)
	assert(promotion.native.starts == previous)
	promotion.queue_free()
	await process_frame
	print("Promotion checks passed: automatic background startup, regional/vendor decision, withdrawal, age filter, absent configuration and no custom UI.")
	quit()
