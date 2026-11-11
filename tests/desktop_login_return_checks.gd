extends SceneTree

var failures := 0
var returns := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	var handoff := preload("res://scripts/online/DesktopLoginReturn.gd").new()
	root.add_child(handoff)
	handoff.returned.connect(func(): returns += 1)
	var connection := handoff.start()
	check(not connection.is_empty(), "desktop listener starts")
	if connection.is_empty():
		quit(1)
		return
	check(connection.port >= 1024 and connection.port <= 65535, "ephemeral loopback port")
	check(str(connection.token).length() == 64, "random handoff path")
	var request := HTTPRequest.new()
	request.timeout = 4
	root.add_child(request)
	var base := "http://127.0.0.1:%d/return/" % connection.port
	request.request(base + "wrong-token")
	var rejected: Array = await request.request_completed
	check(rejected[1] == 404 and returns == 0, "wrong token cannot activate game")
	request.request(base + str(connection.token))
	var accepted: Array = await request.request_completed
	check(accepted[0] == HTTPRequest.RESULT_SUCCESS and accepted[1] == 200, "browser handoff returns HTTP success")
	check(returns == 1, "valid browser handoff resumes game login exactly once")
	check(handoff.start() == connection, "listener remains available after sign-in polling completes")
	handoff._deadline = 0
	await process_frame
	await process_frame
	check(not handoff._server.is_listening(), "desktop listener expires")
	print("DESKTOP_LOGIN_RETURN_CHECKS: %d failures" % failures)
	quit(1 if failures else 0)
