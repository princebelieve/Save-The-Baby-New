extends Node

class ImmediateAds extends RefCounted:
	signal on_initialization_complete(status: Dictionary)
	func initialize() -> void: on_initialization_complete.emit({})

class ImmediateConsent extends RefCounted:
	signal on_consent_info_updated_success
	signal on_consent_info_updated_failure(error: Dictionary)
	func update(_parameters: Dictionary) -> void: on_consent_info_updated_success.emit()

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var previous_ads := MobileAds._plugin
	var fake_ads := ImmediateAds.new()
	MobileAds._plugin = fake_ads
	var completions := [0]
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus): completions[0] += 1
	MobileAds.initialize(listener)
	await get_tree().process_frame
	assert(completions[0] == 1, "Do not miss a native initialization callback emitted before initialize returns")
	MobileAds._plugin = previous_ads
	var previous_consent := ConsentInformation._plugin
	var fake_consent := ImmediateConsent.new()
	ConsentInformation._plugin = fake_consent
	var information := ConsentInformation.new()
	information.update(ConsentRequestParameters.new(), func(): completions[0] += 1)
	await get_tree().process_frame
	assert(completions[0] == 2, "Subscribe before requesting a native consent update")
	ConsentInformation._plugin = previous_consent
	print("Ad initialization race checks passed: synchronous native SDK and consent callbacks are delivered.")
	get_tree().quit()
