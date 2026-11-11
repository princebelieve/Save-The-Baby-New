extends Node
## A temporary loopback handoff for desktop tests and builds. No installed URL
## protocol is required, and the browser never receives a login credential.
var _server := TCPServer.new()
var _secret := ""
var _deadline := 0
var _clients: Array[Dictionary] = []
signal returned

func start() -> Dictionary:
	if OS.get_name() not in ["Windows", "Linux", "macOS"]:
		return {}
	if not _server.is_listening():
		if _server.listen(0, "127.0.0.1") != OK:
			return {}
		_secret = Crypto.new().generate_random_bytes(32).hex_encode()
	_deadline = Time.get_ticks_msec() + 15 * 60 * 1000
	return {"port": _server.get_local_port(), "token": _secret}

func _process(_delta: float) -> void:
	if not _server.is_listening():
		return
	if Time.get_ticks_msec() > _deadline:
		_server.stop()
		_clients.clear()
		return
	while _server.is_connection_available():
		var peer := _server.take_connection()
		if _clients.size() < 4:
			_clients.append({"peer": peer, "data": "", "time": Time.get_ticks_msec()})
		else:
			peer.disconnect_from_host()
	for index in range(_clients.size() - 1, -1, -1):
		var client: Dictionary = _clients[index]
		var peer: StreamPeerTCP = client.peer
		peer.poll()
		var available := peer.get_available_bytes()
		if available > 0:
			client.data += peer.get_utf8_string(mini(available, 4096))
		if client.data.length() > 4096 or Time.get_ticks_msec() - int(client.time) > 3000:
			peer.disconnect_from_host()
			_clients.remove_at(index)
			continue
		if not str(client.data).contains("\r\n\r\n"):
			continue
		var valid := str(client.data).begins_with("GET /return/" + _secret + " HTTP/")
		var body := "Return to the game. Your sign-in will resume there." if valid else "Not found"
		var status := "200 OK" if valid else "404 Not Found"
		peer.put_data(("HTTP/1.1 " + status + "\r\nContent-Type: text/plain; charset=utf-8\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: " + str(body.to_utf8_buffer().size()) + "\r\n\r\n" + body).to_utf8_buffer())
		_clients.remove_at(index)
		if valid:
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_move_to_foreground()
			if OS.get_name() == "Windows" and DisplayServer.get_name() != "headless":
				# The browser-launched navigation does not register a system protocol.
				var game_pid := str(OS.get_process_id())
				var focus_command := "$focusShell = New-Object -ComObject WScript.Shell; if (-not $focusShell.AppActivate(" + game_pid + ")) { $gameProcess = Get-CimInstance Win32_Process -Filter 'ProcessId = " + game_pid + "'; if ($gameProcess) { $focusShell.AppActivate([int]$gameProcess.ParentProcessId) | Out-Null } }"
				OS.create_process("powershell.exe", PackedStringArray(["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", focus_command]))
			returned.emit()
