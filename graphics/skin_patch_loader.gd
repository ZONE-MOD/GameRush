extends RefCounted
class_name SkinPatchLoader

static func load_local_catalog() -> Dictionary:
    var result := {"skins": [], "helmets": [], "patches": []}
    var dir := DirAccess.open("res://graphics/skin_patches")
    if dir == null:
        return result
    var files: Array[String] = []
    dir.list_dir_begin()
    var file := dir.get_next()
    while file != "":
        if not dir.current_is_dir() and file.ends_with(".json") and (file == "base_patch.json" or file.begins_with("patch_")):
            files.append(file)
        file = dir.get_next()
    dir.list_dir_end()
    files.sort()
    for file_name in files:
        var f := FileAccess.open("res://graphics/skin_patches/" + file_name, FileAccess.READ)
        if f == null:
            continue
        var parsed = JSON.parse_string(f.get_as_text())
        f.close()
        if parsed is Dictionary:
            result["patches"].append(str(parsed.get("patch_id", file_name)))
            _merge_items(result["skins"], parsed.get("skins", []))
            _merge_items(result["helmets"], parsed.get("helmets", []))
    return result

static func _merge_items(target: Array, incoming: Array) -> void:
    for item in incoming:
        if not item is Dictionary or not item.has("id"):
            continue
        var found := -1
        for i in range(target.size()):
            if str(target[i].get("id", "")) == str(item["id"]):
                found = i
                break
        if found >= 0:
            target[found] = item.duplicate(true)
        else:
            target.append(item.duplicate(true))
