extends Node

signal changed
signal login_completed(profile: Dictionary)
signal login_starting
signal login_browser_opened
signal login_start_failed(text: String)
signal login_status_changed(text: String)
signal logged_out
signal message(text: String)
signal background_message(text: String)

const LOGIN_PATH := "user://pending_google_login.cfg"
const LOGIN_LIFETIME := 900

const SESSION_PATH := "user://online_session.cfg"
const OWNER_MODE_PATH := "user://account_owner_mode.cfg"
var base_url := ""
var token := ""
var user_id := ""
var player_name := ""
var revision := 0
var wallet := 0
var billing_account := ""
var conflict := false
var busy := false
var _login_active := false
var _login_state: Dictionary = {}
var _login_generation := 0
var _poll_inflight := false
var _login_poll_timer: Timer
var _sync_timer: Timer
var _pending_save: Dictionary = {}
var _ready_to_sync := false
var _desktop_return: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if preload("res://scripts/debug/DeveloperTools.gd").enabled():
		return
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://configs/online.json"))
	if config is Dictionary:
		base_url = str(config.get("api_base_url", "")).trim_suffix("/")
	var session := ConfigFile.new()
	if session.load(SESSION_PATH) == OK:
		token = str(session.get_value("account", "token", ""))
		user_id = str(session.get_value("account", "user_id", ""))
		player_name = str(session.get_value("account", "name", "Player"))
		revision = int(session.get_value("account", "revision", 0))
		billing_account = str(session.get_value("account", "billing_account", ""))
		wallet = int(session.get_value("account", "wallet", 0))
		conflict = bool(session.get_value("account", "conflict", false))
	_sync_timer = Timer.new()
	_sync_timer.wait_time = 15.0
	_sync_timer.one_shot = true
	_sync_timer.timeout.connect(_upload_pending)
	add_child(_sync_timer)
	_login_poll_timer = Timer.new()
	_login_poll_timer.one_shot = true
	_login_poll_timer.ignore_time_scale = true
	_login_poll_timer.timeout.connect(_poll_login_once)
	add_child(_login_poll_timer)
	_restore_pending_login()


func configured() -> bool:
	return base_url.begins_with("https://") or (OS.is_debug_build() and (base_url.begins_with("http://localhost:") or base_url.begins_with("http://127.0.0.1:")))

func signed_in() -> bool:
	return not token.is_empty() and not user_id.is_empty()

func login_in_progress() -> bool:
	return _login_active

func needs_parent_account() -> bool:
	var owner_mode := ConfigFile.new()
	if owner_mode.load(OWNER_MODE_PATH) == OK:
		var saved_mode := str(owner_mode.get_value("account", "mode", ""))
		if saved_mode in ["adult", "guardian"]:
			return saved_mode == "guardian"
	var settings := ConfigFile.new()
	return settings.load("user://ad_age_group.cfg") != OK or settings.get_value("audience", "group", "unknown") != "adult"

func set_account_owner_mode(mode: String) -> void:
	if mode not in ["adult", "guardian"]:
		return
	var settings := ConfigFile.new()
	settings.set_value("account", "mode", mode)
	CampaignProgressStore.write(settings, OWNER_MODE_PATH)

func api(path: String, method: HTTPClient.Method = HTTPClient.METHOD_GET, data: Dictionary = {}, authenticated := true, timeout_seconds := 25.0) -> Dictionary:
	if not configured():
		return {"error":"Online services are not configured yet.", "status":0}
	var request := HTTPRequest.new()
	request.timeout = timeout_seconds
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authenticated:
		if not signed_in():
			request.queue_free()
			return {"error":"Sign in with Google first.", "status":401}
		headers.append("Authorization: Bearer " + token)
	var result := request.request(base_url + path, headers, method, JSON.stringify(data) if method != HTTPClient.METHOD_GET else "")
	if result != OK:
		request.queue_free()
		return {"error":"Could not connect. Your local progress is safe.", "status":0}
	var response: Array = await request.request_completed
	request.queue_free()
	var response_text := (response[3] as PackedByteArray).get_string_from_utf8()
	var body: Variant = JSON.parse_string(response_text) if not response_text.is_empty() else {}
	if not body is Dictionary:
		body = {"error":"Service unavailable. Please try again."}
	body["status"] = int(response[1])
	if int(response[1]) == 401 and authenticated:
		token = ""
		_save_session()
		changed.emit()
	if int(response[1]) >= 400 and not body.has("error"):
		body["error"] = "Sign-in service unavailable. Please try again."
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		body["error"] = "Connection failed. Your local progress is safe."
	return body

func sign_in(account_mode := "") -> void:
	if _login_active or busy:
		return
	var selected_mode := account_mode
	if selected_mode not in ["self", "guardian"]:
		selected_mode = "guardian" if needs_parent_account() else "self"
	_login_generation += 1
	var generation := _login_generation
	_login_active = true
	login_starting.emit()
	var verifier := Crypto.new().generate_random_bytes(32).hex_encode()
	if not is_instance_valid(_desktop_return):
		_desktop_return = preload("res://scripts/online/DesktopLoginReturn.gd").new()
		add_child(_desktop_return)
		_desktop_return.returned.connect(resume_login)
	var handoff: Dictionary = _desktop_return.start()
	var start := await api("/auth/start", HTTPClient.METHOD_POST, {"challenge":verifier.sha256_text(),"accountMode":selected_mode,"desktopReturn":handoff}, false, 75.0)
	if generation != _login_generation:
		return
	if start.has("error"):
		_fail_login(str(start.error))
		return
	if not start.get("flow") is String or not start.get("url") is String:
		_fail_login("Google sign-in is unavailable. Please try again.")
		return
	_login_state = {"flow":start.flow, "verifier":verifier, "deadline":TimeHelper.current_unix_time() + int(start.get("expiresIn", LOGIN_LIFETIME))}
	if not _save_pending_login():
		_fail_login("Could not save this sign-in attempt. Please check device storage and try again.")
		return
	if OS.shell_open(str(start.url)) != OK:
		_fail_login("Could not open the browser. Check that a browser is installed, then try again.")
		return
	login_browser_opened.emit()
	_login_poll_timer.start(1.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		resume_login()


func resume_login() -> void:
	if _login_active and not _login_state.is_empty() and is_instance_valid(_login_poll_timer):
		_login_poll_timer.start(0.1)


func cancel_login() -> void:
	_login_generation += 1
	_login_active = false
	_login_state = {}
	if is_instance_valid(_login_poll_timer):
		_login_poll_timer.stop()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(LOGIN_PATH + suffix):
			DirAccess.remove_absolute(LOGIN_PATH + suffix)


func _save_pending_login() -> bool:
	var pending := ConfigFile.new()
	for key in _login_state:
		pending.set_value("login", key, _login_state[key])
	return CampaignProgressStore.write(pending, LOGIN_PATH) == OK


func _restore_pending_login() -> void:
	if signed_in():
		cancel_login()
		return
	var pending := ConfigFile.new()
	if CampaignProgressStore.read(pending, LOGIN_PATH) != OK:
		return
	var deadline := int(pending.get_value("login", "deadline", 0))
	var flow := str(pending.get_value("login", "flow", ""))
	var verifier := str(pending.get_value("login", "verifier", ""))
	if deadline <= TimeHelper.current_unix_time() or flow.is_empty() or verifier.length() < 32:
		cancel_login()
		return
	_login_state = {"flow":flow, "verifier":verifier, "deadline":deadline}
	_login_generation += 1
	_login_active = true
	_login_poll_timer.start(0.1)


func _fail_login(text: String) -> void:
	cancel_login()
	login_start_failed.emit(text)


func _poll_login_once() -> void:
	if not _login_active or _login_state.is_empty() or _poll_inflight:
		return
	if TimeHelper.current_unix_time() >= int(_login_state.deadline):
		_fail_login("Google sign-in expired. Please try again. Your local progress has not changed.")
		return
	var generation := _login_generation
	_poll_inflight = true
	var response := await api("/auth/poll", HTTPClient.METHOD_POST, {"flow":_login_state.flow, "verifier":_login_state.verifier}, false, 12.0)
	_poll_inflight = false
	if not _login_active or generation != _login_generation:
		resume_login()
		return
	if response.has("error"):
		var status := int(response.get("status", 0))
		if status == 0 or status in [408, 425, 429] or status >= 500:
			login_status_changed.emit("Reconnecting to finish Google sign-in. Your progress has not changed.")
			_login_poll_timer.start(3.0)
			return
		_fail_login(str(response.error))
		return
	if response.has("token"):
		if str(response.get("token", "")).is_empty() or str(response.get("userId", "")).is_empty():
			_fail_login("The sign-in response was incomplete. Please try again.")
			return
		_ready_to_sync = false
		_pending_save = {}
		_sync_timer.stop()
		token = str(response.token)
		user_id = str(response.userId)
		player_name = str(response.get("name", "Player"))
		revision = int(response.get("revision", 0))
		wallet = int(response.get("wallet", 0))
		billing_account = str(response.get("billingAccount", ""))
		conflict = false
		_save_session()
		cancel_login()
		login_completed.emit(response)
		changed.emit()
		return
	login_status_changed.emit("Finish signing in with Google, then tap Return to game in the browser.")
	_login_poll_timer.start(3.0)

func queue_save(snapshot: Dictionary) -> void:
	if not signed_in() or not _ready_to_sync:
		return
	_pending_save = snapshot.duplicate(true)
	if not conflict and _sync_timer.is_stopped():
		_sync_timer.start()

func _upload_pending() -> void:
	if _pending_save.is_empty() or conflict or not signed_in():
		return
	if busy:
		_sync_timer.start()
		return
	var snapshot := _pending_save.duplicate(true)
	_pending_save = {}
	var response := await upload(snapshot, false)
	if response.has("error") and _pending_save.is_empty():
		_pending_save = snapshot
	if not _pending_save.is_empty() and not conflict:
		_sync_timer.start()

func upload(snapshot: Dictionary, user_initiated := true) -> Dictionary:
	if busy or conflict:
		return {"error":"Resolve the cloud save conflict before uploading.","status":409}
	busy = true
	var response := await api("/v1/save",HTTPClient.METHOD_PUT,{"revision":revision,"save":snapshot})
	busy = false
	if response.has("error"):
		if int(response.get("status",0)) == 409:
			conflict = true
			_save_session()
		if user_initiated:
			message.emit(str(response.error))
		else:
			background_message.emit("Cloud sync delayed. Your local progress is safe. " + str(response.error))
	else:
		accept_profile(response)
		_ready_to_sync = true
	return response

func download() -> Dictionary:
	if busy:
		return {"error":"A sync is already running."}
	busy = true
	var response := await api("/v1/me")
	busy = false
	return response

func accept_profile(profile: Dictionary) -> void:
	revision = int(profile.get("revision",revision))
	wallet = int(profile.get("wallet",wallet))
	conflict = false
	_save_session()
	changed.emit()

func resume_sync() -> void:
	_ready_to_sync = true

func applied_download(profile: Dictionary) -> void:
	_pending_save = {}
	_sync_timer.stop()
	accept_profile(profile)
	_ready_to_sync = true

func sign_out(delete_account := false) -> void:
	if busy:
		return
	busy = true
	var response := await api("/v1/account" if delete_account else "/v1/logout",HTTPClient.METHOD_DELETE if delete_account else HTTPClient.METHOD_POST)
	busy = false
	if response.has("error"):
		message.emit(str(response.error))
		return
	cancel_login()
	token = ""
	user_id = ""
	_pending_save = {}
	_ready_to_sync = false
	_sync_timer.stop()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(SESSION_PATH + suffix)
	logged_out.emit()
	changed.emit()

func _save_session() -> void:
	var session := ConfigFile.new()
	for pair in [["token",token],["user_id",user_id],["name",player_name],["revision",revision],["wallet",wallet],["billing_account",billing_account],["conflict",conflict]]:
		session.set_value("account",str(pair[0]),pair[1])
	CampaignProgressStore.write(session,SESSION_PATH)
