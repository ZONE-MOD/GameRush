extends RefCounted
class_name LevelManager

const LEVELS := [
    "سپیده‌دم صحرا",
    "ظهر سوزان",
    "غروب آتشین",
    "شب مهتابی",
    "جنگل مه‌آلود",
    "دره آتشفشان",
    "طوفان تاریک",
    "یخچال آرورا",
    "شهر نئونی",
    "نبرد کهکشانی"
]

static func level_name(level: int) -> String:
    return LEVELS[clampi(level - 1, 0, LEVELS.size() - 1)]

static func palette(level: int, progress: float) -> Dictionary:
    var palettes := [
        ["#33234f", "#d98d68", "#b96f55", "#d7a16b", "#a76d49"],
        ["#2587bd", "#d4edff", "#c49b70", "#e4b975", "#bb8c50"],
        ["#2b163c", "#f26c48", "#713b57", "#78434a", "#4c2734"],
        ["#060d27", "#243e71", "#1b3157", "#30445d", "#18283c"],
        ["#102d2a", "#78ad91", "#28564b", "#31583e", "#1a3829"],
        ["#230808", "#e94b22", "#421313", "#4a1b12", "#260b08"],
        ["#101723", "#46516c", "#1c283a", "#303a4a", "#1b222e"],
        ["#06152e", "#36b9ae", "#75a9ca", "#c8e3f0", "#8bb9d5"],
        ["#18042f", "#8129a6", "#32104e", "#1b0c35", "#0c041b"],
        ["#03020b", "#25104d", "#21134b", "#30215b", "#17102f"]
    ]
    var p: Array = palettes[clampi(level - 1, 0, 9)]
    var top := Color.from_string(p[0], Color.BLACK)
    var bottom := Color.from_string(p[1], Color.BLACK)
    var far := Color.from_string(p[2], Color.BLACK)
    var near := Color.from_string(p[3], Color.BLACK)
    var ground := Color.from_string(p[4], Color.BLACK)
    if level == 10:
        var hell := clampf((progress - 0.18) / 0.82, 0.0, 1.0)
        top = top.lerp(Color("#35050d"), hell * 0.72)
        bottom = bottom.lerp(Color("#9d1b26"), hell * 0.60)
        far = far.lerp(Color("#4c101c"), hell * 0.70)
        near = near.lerp(Color("#290811"), hell * 0.65)
        ground = ground.lerp(Color("#21070d"), hell * 0.70)
    return {"top": top, "bottom": bottom, "far": far, "near": near, "ground": ground}

static func base_speed(level: int, endless: bool) -> float:
    if endless:
        return 360.0
    return 340.0 + float(level - 1) * 34.0
