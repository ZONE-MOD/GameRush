extends Node
class_name DinoGameApiClient

signal api_response(action: String, success: bool, payload: Dictionary)

var http: HTTPRequest
var base_url := ""
var api_enabled := false
var session_token := ""
var pending_action := ""

func _ready() -> void:
    var file := FileAccess.open("res://config/game_config.json", FileAccess.READ)
    if file:
        var config = JSON.parse_string(file.get_as_text())
        file.close()
        if config is Dictionary:
            base_url = str(config.get("api_base_url", "")).trim_suffix("/")
            api_enabled = bool(config.get("api_enabled", false))
    http = HTTPRequest.new()
    http.timeout = 15.0
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func register_account(username: String, password: String, phone: String) -> void:
    _post("/api/v1/auth/register", {"username": username, "password": password, "phone": phone}, "register")

func login_account(username: String, password: String, phone: String) -> void:
    _post("/api/v1/auth/login", {"username": username, "password": password, "phone": phone}, "login")

func fetch_my_profile() -> void:
    _request("/api/v1/players/me", HTTPClient.METHOD_GET, {}, "profile")

func _post(path: String, data: Dictionary, action: String) -> void:
    _request(path, HTTPClient.METHOD_POST, data, action)

func _request(path: String, method: int, data: Dictionary, action: String) -> void:
    if not api_enabled or not base_url.begins_with("https://"):
        api_response.emit(action, false, {"error": "api_disabled", "message": "API هنوز فعال نشده است."})
        return
    var headers := PackedStringArray(["Content-Type: application/json"])
    if not session_token.is_empty():
        headers.append("Authorization: Bearer " + session_token)
    var body := "" if method == HTTPClient.METHOD_GET else JSON.stringify(data)
    pending_action = action
    var err := http.request(base_url + path, headers, method, body)
    if err != OK:
        api_response.emit(action, false, {"error": "request_start_failed", "code": err})

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    var payload: Dictionary = parsed if parsed is Dictionary else {"raw": body.get_string_from_utf8()}
    var success := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
    if success and payload.has("token"):
        session_token = str(payload["token"])
    api_response.emit(pending_action, success, payload)
    pending_action = ""
