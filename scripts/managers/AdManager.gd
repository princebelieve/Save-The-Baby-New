extends Node
class_name AdManager

# A native provider must report earned rewards separately from dismissal.
signal availability_changed
signal finished(earned: bool)
var provider: Object
var busy := false
var _earned := false
var _request_id := 0
var _rewarded := false
var _claims: Dictionary = {}

func configure(adapter: Object) -> void:
	provider = adapter
	if provider.has_signal("availability_changed"):
		provider.connect("availability_changed", _on_availability_changed)
	availability_changed.emit()

func available(kind: String) -> bool:
	return not busy and is_instance_valid(provider) and provider.has_method("is_ad_ready") and bool(provider.call("is_ad_ready", kind))

func claimed(placement: String) -> bool:
	return _claims.has(placement)

func show_ad(kind: String, placement: String) -> bool:
	if not available(kind) or (kind == "rewarded" and claimed(placement)):
		return false
	busy = true
	_earned = false
	_rewarded = kind == "rewarded"
	_request_id += 1
	var token := _request_id
	# Provider calls earned only on its SDK reward event, closed on close/failure.
	provider.call("show_ad", kind, placement, func(): _on_earned(token), func(): _on_closed(token, placement))
	return true

func _on_earned(token: int) -> void:
	if busy and token == _request_id and _rewarded:
		_earned = true

func _on_closed(token: int, placement: String) -> void:
	if not busy or token != _request_id:
		return
	var earned := _earned
	if earned:
		_claims[placement] = true
	busy = false
	finished.emit(earned)
	availability_changed.emit()

func _on_availability_changed() -> void:
	availability_changed.emit()
