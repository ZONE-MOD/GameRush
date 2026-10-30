extends Node
class_name DinoAudioManager

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_enabled := true
var sfx_enabled := true

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    sfx_player = AudioStreamPlayer.new()
    add_child(music_player)
    add_child(sfx_player)

func play_music(resource_path: String, volume_db := -8.0, loop := true) -> void:
    if not music_enabled or not ResourceLoader.exists(resource_path):
        return
    var stream = load(resource_path)
    if stream == null:
        return
    music_player.stream = stream
    music_player.volume_db = volume_db
    music_player.play()

func play_sfx(resource_path: String, volume_db := -2.0) -> void:
    if not sfx_enabled or not ResourceLoader.exists(resource_path):
        return
    var stream = load(resource_path)
    if stream == null:
        return
    sfx_player.stream = stream
    sfx_player.volume_db = volume_db
    sfx_player.play()

func stop_music() -> void:
    if music_player:
        music_player.stop()
