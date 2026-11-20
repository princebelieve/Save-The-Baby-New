extends Node

# Shared CMP state. Neither an AdMob initialization result nor a custom TikTok popup.
signal state_changed
var privacy_ready := false
var consent_status := ConsentInformation.ConsentStatus.UNKNOWN
var _updating := false
var _retry_at_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if _retry_at_ms > 0 and not _updating and Time.get_ticks_msec() >= _retry_at_ms:
		_retry_at_ms = 0
		start_session()

func start_session() -> void:
	if _updating or OS.get_name() != "Android":
		return
	_updating = true
	_retry_at_ms = 0
	privacy_ready = false
	state_changed.emit()
	UserMessagingPlatform.consent_information.update(_consent_parameters(), _on_updated, _on_update_failed)

func _consent_parameters() -> ConsentRequestParameters:
	var parameters := ConsentRequestParameters.new()
	var audience := get_node_or_null("/root/AudienceSettings")
	var group := str(audience.age_group) if audience != null else "unknown"
	# Mark only a known under-age answer; suitable ad content does not classify everyone as a child.
	parameters.tag_for_under_age_of_consent = group in ["under_13", "13_15"]
	return parameters

func _on_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(func(form: ConsentForm):
			form.show(func(_error: FormError): _finish()),
			func(_error: FormError): _on_update_failed(null))
	else:
		_finish()

func _on_update_failed(_error: FormError) -> void:
	print("Privacy: update failed: code=%s message=%s" % [_error.error_code, _error.message] if _error != null else "Privacy: update failed; waiting for a valid regional decision.")
	_updating = false
	privacy_ready = false
	consent_status = ConsentInformation.ConsentStatus.UNKNOWN
	_retry_at_ms = Time.get_ticks_msec() + 60000
	state_changed.emit()

func _finish() -> void:
	_updating = false
	consent_status = UserMessagingPlatform.consent_information.get_consent_status()
	print("Privacy: consent status=%s" % consent_status)
	privacy_ready = consent_status in [ConsentInformation.ConsentStatus.OBTAINED, ConsentInformation.ConsentStatus.NOT_REQUIRED]
	_retry_at_ms = 0 if privacy_ready else Time.get_ticks_msec() + 60000
	state_changed.emit()

func ad_requests_allowed() -> bool:
	return privacy_ready

func privacy_options_required() -> bool:
	return OS.get_name() == "Android" and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if not privacy_options_required() or _updating:
		return
	privacy_ready = false
	_updating = true
	state_changed.emit()
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError): _finish())
