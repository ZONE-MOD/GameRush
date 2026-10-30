extends Node2D
class_name DinoPlayer

const FLOOR_Y := 560.0
var velocity_y := 0.0
var grounded := true
var is_ducking := false
var skin_data: Dictionary = {"body": "#8fa3a8", "belly": "#d3e0e0", "spike": "#5d7378", "fx": ""}
var helmet_id := "none"

func reset_player() -> void:
    position = Vector2(250.0, FLOOR_Y)
    velocity_y = 0.0
    grounded = true
    is_ducking = false
    queue_redraw()

func apply_appearance(data: Dictionary, helmet: String) -> void:
    if not data.is_empty():
        skin_data = data.duplicate(true)
    helmet_id = helmet
    queue_redraw()

func jump() -> void:
    if grounded:
        velocity_y = -650.0
        grounded = false
        is_ducking = false
        queue_redraw()

func set_duck(value: bool) -> void:
    is_ducking = value and grounded
    queue_redraw()

func tick(delta: float) -> void:
    if not grounded:
        velocity_y += 1650.0 * delta
        position.y += velocity_y * delta
        if position.y >= FLOOR_Y:
            position.y = FLOOR_Y
            velocity_y = 0.0
            grounded = true
    queue_redraw()

func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(20):
        var a := TAU * float(i) / 20.0
        points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(points, color)

func _draw() -> void:
    var body := Color.from_string(str(skin_data.get("body", "#8fa3a8")), Color.GRAY)
    var belly := Color.from_string(str(skin_data.get("belly", "#d3e0e0")), Color.WHITE)
    var spike := Color.from_string(str(skin_data.get("spike", "#5d7378")), Color.DARK_GRAY)
    var yoff := 18.0 if is_ducking else 0.0
    # tail
    draw_colored_polygon(PackedVector2Array([Vector2(-42, -38 + yoff), Vector2(-94, -57 + yoff), Vector2(-67, -24 + yoff), Vector2(-40, -18 + yoff)]), body.darkened(0.12))
    # body and belly
    _ellipse(Vector2(-4, -42 + yoff), 48.0, 31.0 if not is_ducking else 22.0, body)
    _ellipse(Vector2(1, -26 + yoff), 28.0, 12.0, belly)
    # neck and head
    draw_rect(Rect2(17, -83 + yoff, 22, 49), body)
    _ellipse(Vector2(44, -91 + yoff), 28.0, 23.0, body)
    _ellipse(Vector2(65, -83 + yoff), 11.0, 8.0, body.lightened(0.12))
    # spikes
    for i in range(5):
        var x := -30.0 + float(i) * 16.0
        draw_colored_polygon(PackedVector2Array([Vector2(x, -66 + yoff), Vector2(x + 8, -83 + yoff), Vector2(x + 16, -64 + yoff)]), spike)
    # legs
    if not is_ducking:
        draw_rect(Rect2(-25, -20, 15, 21), body.darkened(0.18))
        draw_rect(Rect2(14, -20, 15, 21), body.darkened(0.18))
        draw_rect(Rect2(-30, -3, 27, 7), spike)
        draw_rect(Rect2(9, -3, 27, 7), spike)
    else:
        draw_rect(Rect2(-25, -7, 42, 8), body.darkened(0.18))
    # eye
    draw_circle(Vector2(52, -98 + yoff), 4.0, Color("#171321"))
    draw_circle(Vector2(53, -99 + yoff), 1.3, Color.WHITE)
    # helmet styles
    match helmet_id:
        "miner":
            draw_rect(Rect2(24, -119 + yoff, 40, 8), Color("#e2aa37"))
            draw_arc(Vector2(44, -112 + yoff), 19, PI, TAU, 16, Color("#ffe28a"), 5.0)
        "knight":
            draw_colored_polygon(PackedVector2Array([Vector2(22, -103 + yoff), Vector2(29, -126 + yoff), Vector2(54, -126 + yoff), Vector2(67, -103 + yoff)]), Color("#aeb9c9"))
            draw_line(Vector2(28, -112 + yoff), Vector2(63, -112 + yoff), Color("#5b667a"), 3.0)
        "astro":
            draw_circle(Vector2(44, -108 + yoff), 25, Color("#d7e9f4"), false, 5.0)
            draw_arc(Vector2(44, -108 + yoff), 20, PI, TAU, 24, Color("#67d8ff"), 4.0)
        "void":
            draw_colored_polygon(PackedVector2Array([Vector2(19, -104 + yoff), Vector2(27, -139 + yoff), Vector2(40, -120 + yoff), Vector2(51, -147 + yoff), Vector2(61, -119 + yoff), Vector2(72, -137 + yoff), Vector2(69, -103 + yoff)]), Color("#35112f"))
            draw_line(Vector2(25, -111 + yoff), Vector2(68, -111 + yoff), Color("#ff4f93"), 3.0)
        "ultimate":
            draw_colored_polygon(PackedVector2Array([Vector2(15, -105 + yoff), Vector2(24, -140 + yoff), Vector2(40, -119 + yoff), Vector2(46, -153 + yoff), Vector2(56, -119 + yoff), Vector2(73, -142 + yoff), Vector2(74, -104 + yoff)]), Color("#b8f7ff"))
            draw_arc(Vector2(45, -111 + yoff), 31, PI, TAU, 28, Color("#ffe08a"), 3.0)
            draw_circle(Vector2(45, -132 + yoff), 4, Color("#ffffff"))
