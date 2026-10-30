extends Node2D
class_name RunnerWorld

signal run_finished(success: bool, level: int, earned_coins: int, endless: bool)
signal coin_collected(total_gain: int)

const VIEW_W := 1280.0
const VIEW_H := 720.0
const GROUND_Y := 560.0
const LEVEL_LENGTH := 2850.0
@onready var player: DinoPlayer = $Player

var active := false
var endless := false
var current_level := 1
var distance := 0.0
var speed := 360.0
var score := 0
var earned_coins := 0
var spawn_timer := 0.8
var coin_timer := 1.4
var obstacles: Array = []
var coins: Array = []
var elapsed := 0.0

func start_run(level: int, endless_mode: bool, skin: Dictionary, helmet: String) -> void:
    current_level = clampi(level, 1, 10)
    endless = endless_mode
    distance = 0.0
    score = 0
    earned_coins = 0
    speed = LevelManager.base_speed(current_level, endless)
    spawn_timer = 0.8
    coin_timer = 1.3
    elapsed = 0.0
    obstacles.clear()
    coins.clear()
    player.reset_player()
    player.apply_appearance(skin, helmet)
    active = true
    visible = true
    set_process(true)
    queue_redraw()

func stop_run() -> void:
    active = false
    set_process(false)

func _process(delta: float) -> void:
    if not active:
        return
    var dt := minf(delta, 0.05)
    elapsed += dt
    distance += speed * dt
    score = int(distance / 5.0)
    if endless:
        speed = minf(900.0, 360.0 + distance * 0.018)
    else:
        speed = minf(760.0, LevelManager.base_speed(current_level, false) + distance * 0.012)
    player.tick(dt)
    spawn_timer -= dt
    if spawn_timer <= 0.0:
        _spawn_obstacle()
        spawn_timer = maxf(0.72, randf_range(1.05, 1.55) - (speed - 360.0) / 1500.0)
    coin_timer -= dt
    if coin_timer <= 0.0:
        _spawn_coins()
        coin_timer = randf_range(1.8, 2.8)
    for i in range(obstacles.size() - 1, -1, -1):
        obstacles[i]["x"] = float(obstacles[i]["x"]) - speed * dt
        if float(obstacles[i]["x"]) < -100.0:
            obstacles.remove_at(i)
            continue
        if _hits_obstacle(obstacles[i]):
            _finish(false)
            return
    for i in range(coins.size() - 1, -1, -1):
        coins[i]["x"] = float(coins[i]["x"]) - speed * dt
        if float(coins[i]["x"]) < -30.0:
            coins.remove_at(i)
            continue
        var dx: float = absf(float(coins[i]["x"]) - player.position.x)
        var dy: float = absf(float(coins[i]["y"]) - (player.position.y - 55.0))
        if dx < 42.0 and dy < 72.0:
            coins.remove_at(i)
            earned_coins += 1
            coin_collected.emit(earned_coins)
    if not endless and distance >= LEVEL_LENGTH:
        _finish(true)
        return
    queue_redraw()

func _spawn_obstacle() -> void:
    var kind := "spike" if randf() < 0.66 else "bat"
    obstacles.append({"x": VIEW_W + 70.0, "type": kind, "phase": randf() * TAU})

func _spawn_coins() -> void:
    var base_y := GROUND_Y - randf_range(70.0, 150.0)
    for i in range(4):
        coins.append({"x": VIEW_W + 50.0 + float(i) * 38.0, "y": base_y - sin(float(i) / 3.0 * PI) * 24.0})

func _hits_obstacle(ob: Dictionary) -> bool:
    var dx: float = absf(float(ob["x"]) - player.position.x)
    if dx > 42.0:
        return false
    if str(ob["type"]) == "spike":
        return player.position.y > GROUND_Y - 105.0
    return not player.is_ducking and player.position.y > GROUND_Y - 155.0

func _finish(success: bool) -> void:
    if not active:
        return
    active = false
    set_process(false)
    if success:
        earned_coins += 20 + current_level * 8
    run_finished.emit(success, current_level, earned_coins, endless)

func _draw() -> void:
    if not active and not visible:
        return
    var progress := clampf(distance / LEVEL_LENGTH, 0.0, 1.0)
    var colors := LevelManager.palette(current_level, progress)
    var top: Color = colors["top"]
    var bottom: Color = colors["bottom"]
    var far: Color = colors["far"]
    var near: Color = colors["near"]
    var ground: Color = colors["ground"]
    for i in range(20):
        var y := float(i) * 37.0
        draw_rect(Rect2(0, y, VIEW_W, 38), top.lerp(bottom, float(i) / 19.0))
    # distant silhouettes
    var shift := fmod(distance * 0.08, 260.0)
    for i in range(-1, 7):
        var x := float(i) * 260.0 - shift
        draw_colored_polygon(PackedVector2Array([Vector2(x, 445), Vector2(x + 80, 320 + sin(float(i) * 2.1) * 30), Vector2(x + 170, 430), Vector2(x + 260, 350), Vector2(x + 330, 445)]), far)
    var shift2 := fmod(distance * 0.18, 180.0)
    for i in range(-1, 9):
        var x := float(i) * 180.0 - shift2
        draw_colored_polygon(PackedVector2Array([Vector2(x, 500), Vector2(x + 50, 390 + cos(float(i)) * 22), Vector2(x + 115, 500), Vector2(x + 180, 420)]), near)
    draw_rect(Rect2(0, GROUND_Y, VIEW_W, VIEW_H - GROUND_Y), ground)
    draw_line(Vector2(0, GROUND_Y), Vector2(VIEW_W, GROUND_Y), ground.lightened(0.35), 5.0)
    for i in range(18):
        var x := fmod(float(i) * 92.0 - distance * 0.75, VIEW_W)
        draw_line(Vector2(x, GROUND_Y + 34), Vector2(x + 36, GROUND_Y + 34), ground.lightened(0.18), 3.0)
    # obstacles
    for ob in obstacles:
        var x: float = ob["x"]
        if str(ob["type"]) == "spike":
            draw_colored_polygon(PackedVector2Array([Vector2(x - 22, GROUND_Y), Vector2(x - 8, GROUND_Y - 62), Vector2(x + 5, GROUND_Y - 28), Vector2(x + 20, GROUND_Y - 76), Vector2(x + 35, GROUND_Y)]), Color("#243a32"))
            draw_line(Vector2(x - 8, GROUND_Y - 12), Vector2(x + 5, GROUND_Y - 42), Color("#a4c08b"), 3.0)
        else:
            var yy := GROUND_Y - 95.0 + sin(elapsed * 5.0 + float(ob["phase"])) * 9.0
            draw_circle(Vector2(x, yy), 20, Color("#24152e"))
            draw_colored_polygon(PackedVector2Array([Vector2(x - 8, yy), Vector2(x - 50, yy - 26), Vector2(x - 34, yy + 10)]), Color("#4d315c"))
            draw_colored_polygon(PackedVector2Array([Vector2(x + 8, yy), Vector2(x + 50, yy - 26), Vector2(x + 34, yy + 10)]), Color("#4d315c"))
            draw_circle(Vector2(x - 6, yy - 4), 3, Color("#ffcf5a"))
            draw_circle(Vector2(x + 6, yy - 4), 3, Color("#ffcf5a"))
    for coin in coins:
        var c := Vector2(float(coin["x"]), float(coin["y"]))
        draw_circle(c, 13, Color("#ffcf5a"))
        draw_circle(c, 8, Color("#fff0a8"))
        draw_line(c + Vector2(0, -5), c + Vector2(0, 5), Color("#b87517"), 2.0)
    if active:
        draw_string(ThemeDB.fallback_font, Vector2(48, 62), "DIST  %06d" % int(distance), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(48, 94), ("ENDLESS" if endless else "STAGE %02d" % current_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#ffe1a0"))
