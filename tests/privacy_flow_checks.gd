extends Node

class FakeBridge extends RefCounted:
	var starts := 0
	var stops := 0
	func isConfigured() -> bool: return true
	func measurementPermitted(not_required: bool) -> bool: return not_required
	func startTracking() -> void: starts += 1
	func stopTracking() -> void: stops += 1

class TestPromotion extends "res://scripts/ads/PromotionAttribution.gd":
	var native := FakeBridge.new()
	func _bridge() -> Object: return native

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var privacy := get_node("/root/AppPrivacy")
	var audience := get_node("/root/AudienceSettings")
	for group in ["under_13", "13_15"]:
		audience.age_group = group
		assert(privacy._consent_parameters().tag_for_under_age_of_consent)
	for group in ["16_17", "adult", "unknown", "", "invalid"]:
		audience.age_group = group
		assert(not privacy._consent_parameters().tag_for_under_age_of_consent, "Do not mark every adult under-age")
	audience.age_group = "adult"
	var promotion := TestPromotion.new()
	get_tree().root.add_child(promotion)
	promotion.start_session()
	assert(promotion.native.starts == 0)
	privacy.consent_status = ConsentInformation.ConsentStatus.NOT_REQUIRED
	privacy.privacy_ready = true
	privacy.state_changed.emit()
	assert(promotion.native.starts == 1, "Shared privacy state starts background measurement")
	assert(not get_node("/root/AdProvider")._consent_ready, "AdMob initialization is not a prerequisite")
	privacy._on_update_failed(null)
	assert(not privacy.privacy_ready)
	assert(privacy.consent_status == ConsentInformation.ConsentStatus.UNKNOWN)
	assert(promotion.native.stops >= 2, "Unknown/failed CMP refresh stops measurement")
	assert(privacy.get_child_count() == 0 and promotion.get_child_count() == 0, "No bespoke measurement controls")
	promotion.queue_free()
	await get_tree().process_frame
	print("Shared privacy checks passed: actual age treatment, independent background startup, failed refresh and no custom UI.")
	get_tree().quit()
