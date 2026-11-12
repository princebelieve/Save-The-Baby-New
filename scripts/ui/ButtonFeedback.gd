extends RefCounted
## Wrap actions that can yield. Synchronous navigation keeps its normal feedback.
static func run(button: Button, action: Callable, caption := "Please wait…") -> void:
	if button.disabled or bool(button.get_meta("action_pending", false)): return
	var previous := button.text
	button.set_meta("action_pending", true)
	button.disabled = true
	button.text = caption
	await action.call()
	if is_instance_valid(button) and not button.is_queued_for_deletion():
		button.text = previous
		button.disabled = false
		button.set_meta("action_pending", false)
