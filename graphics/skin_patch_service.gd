extends Node

signal catalog_changed

var catalog: Dictionary = {"skins": [], "helmets": [], "patches": []}
var http: HTTPRequest

func _ready() -> void:
    catalog = SkinPatchLoader.load_local_catalog()
    http = HTTPRequest.new()
    http.timeout = 12.0
    add_child(http)
    http.request_completed.connect(_on_remote_catalog_completed)
    var config := _read_config()
    var url := str(config.get("patch_catalog_url", ""))
    if url.begins_with("https://") and not url.contains("YOUR-USERNAME"):
        var err := http.request(url)
        if err != OK:
            push_warning("Skin patch catalog request could not start: %s" % err)

func get_skin(skin_id: String) -> Dictionary:
    for item in catalog.get("skins", []):
        if str(item.get("id", "")) == skin_id:
            return item
    return {"id": "classic", "name": "کلاسیک", "body": "#8fa3a8", "belly": "#d3e0e0", "spike": "#5d7378", "fx": ""}

func _read_config() -> Dictionary:
    var f := FileAccess.open("res://config/game_config.json", FileAccess.READ)
    if f == null:
        return {}
    var parsed = JSON.parse_string(f.get_as_text())
    f.close()
    return parsed if parsed is Dictionary else {}

func _on_remote_catalog_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_warning("Online skin patch catalog unavailable; local patch remains active.")
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if not parsed is Dictionary:
        return
    SkinPatchLoader._merge_items(catalog["skins"], parsed.get("skins", []))
    SkinPatchLoader._merge_items(catalog["helmets"], parsed.get("helmets", []))
    for patch_id in parsed.get("patches", []):
        if not catalog["patches"].has(str(patch_id)):
            catalog["patches"].append(str(patch_id))
    catalog_changed.emit()
