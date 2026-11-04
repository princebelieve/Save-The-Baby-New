extends Node

signal changed
signal login_completed(profile: Dictionary)
signal login_starting
signal login_browser_opened
signal login_start_failed(text: String)
signal logged_out
signal message(text: String)

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
var _sync_timer: Timer
var _pending_save: Dictionary = {}
var _ready_to_sync := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		body["error"] = "Connection failed. Your local progress is safe."
	return body

func sign_in(account_mode := "") -> void:
	if _login_active or busy:
		return
	var selected_mode := account_mode
	if selected_mode not in ["self", "guardian"]:
		selected_mode = "guardian" if needs_parent_account() else "self"
	_login_active = true
	login_starting.emit()
	var verifier := Crypto.new().generate_random_bytes(32).hex_encode()
	# The hosted API may be waking from an idle period; allow its cold start to complete.
	var start := await api("/auth/start", HTTPClient.METHOD_POST, {"challenge":verifier.sha256_text(),"accountMode":selected_mode}, false, 75.0)
	if start.has("error"):
		_login_active = false
		login_start_failed.emit(str(start.error))
		return
	if OS.shell_open(str(start.url)) != OK:
		_login_active = false
		login_start_failed.emit("Could not open the browser. Check that a browser is installed, then try again.")
		return
	login_browser_opened.emit()
	for attempt in range(90):
		await get_tree().create_timer(3.0).timeout
		if not _login_active:
			return
		var response := await api("/auth/poll", HTTPClient.METHOD_POST, {"flow":start.flow,"verifier":verifier}, false)
		if response.has("error"):
			_login_active = false
			message.emit(str(response.error))
			return
		if response.has("token"):
			_login_active = false
			_ready_to_sync = false
			_pending_save = {}
			_sync_timer.stop()
			token = str(response.token)
			user_id = str(response.userId)
			player_name = str(response.get("name", "Player"))
			revision = int(response.revision)
			wallet = int(response.wallet)
			billing_account = str(response.billingAccount)
			conflict = false
			_save_session()
			login_completed.emit(response)
			changed.emit()
			return
	_login_active = false
	message.emit("Google sign-in timed out. You can try again.")

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
	var response := await upload(snapshot)
	if response.has("error") and _pending_save.is_empty():
		_pending_save = snapshot
	if not _pending_save.is_empty() and not conflict:
		_sync_timer.start()

func upload(snapshot: Dictionary) -> Dictionary:
	if busy or conflict:
		return {"error":"Resolve the cloud save conflict before uploading.","status":409}
	busy = true
	var response := await api("/v1/save",HTTPClient.METHOD_PUT,{"revision":revision,"save":snapshot})
	busy = false
	if response.has("error"):
		if int(response.get("status",0)) == 409:
			conflict = true
			_save_session()
		message.emit(str(response.error))
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
	_login_active = false
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
