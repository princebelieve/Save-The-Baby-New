extends Node

# Background measurement only. The shared CMP owns regional privacy messages.
func _bridge() -> Object:
	if OS.get_name() == "Android" and Engine.has_singleton("TikTokEvents"):
		return Engine.get_singleton("TikTokEvents")
	return null

func start_session() -> void:
	var privacy := get_node_or_null("/root/AppPrivacy")
	if privacy != null:
		if not privacy.state_changed.is_connected(_on_privacy_changed):
			privacy.state_changed.connect(_on_privacy_changed)
		_on_privacy_changed()

func _on_privacy_changed() -> void:
	var audience := get_node_or_null("/root/AudienceSettings")
	var privacy := get_node_or_null("/root/AppPrivacy")
	update_session(str(audience.age_group) if audience != null else "unknown", privacy != null and privacy.privacy_ready,
		privacy.consent_status if privacy != null else ConsentInformation.ConsentStatus.UNKNOWN)

func update_session(age_group: String, privacy_ready: bool, consent_status: int) -> void:
	var bridge := _bridge()
	if bridge == null:
		return
	# Known under-16 users do not initialize this measurement SDK. A general-audience
	# app does not need a bespoke age screen just to enforce a family-safe ad content cap.
	if not privacy_ready or consent_status not in [ConsentInformation.ConsentStatus.OBTAINED, ConsentInformation.ConsentStatus.NOT_REQUIRED] or age_group not in ["16_17", "adult", "unknown"] or not bool(bridge.isConfigured()):
		bridge.stopTracking()
		return
	# OBTAINED alone does not prove TikTok consent. The native gate checks the
	# CMP's TikTok vendor/purpose decisions and applicable opt-out signals.
	if bool(bridge.measurementPermitted(consent_status == ConsentInformation.ConsentStatus.NOT_REQUIRED)):
		bridge.startTracking()
	else:
		bridge.stopTracking()
