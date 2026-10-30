extends Node2D

const VIEW_W := 1280.0
const VIEW_H := 720.0
const PROFILE_DIR := "user://profiles"

@onready var world: RunnerWorld = $RunnerWorld

var ui_layer: CanvasLayer
var ui_root: Control
var pages: Dictionary = {}
var state := "login"
var profile: Dictionary = {}
var selected_level := 1
var selected_skin := "classic"
var selected_helmet := "none"
var skin_tab := "skin"
var result_panel: PanelContainer
var hud: Control
var hud_score: Label
var hud_stage: Label
var cutscene_time := 0.0
var cutscene_title_shown := false
var refresh_timer := 0.0

var login_name: LineEdit
var login_password: LineEdit
var login_phone: LineEdit
var login_feedback: Label
var skin_grid: GridContainer
var skin_info: Label
var skin_tab_buttons: Dictionary = {}

func _ready() -> void:
    randomize()
    world.run_finished.connect(_on_run_finished)
    world.coin_collected.connect(_on_coin_collected)
    SkinPatchService.catalog_changed.connect(_on_skin_catalog_changed)
    _build_ui()
    _show_page("login")
    world.visible = false
    set_process(true)

func _process(delta: float) -> void:
    if state == "cutscene":
        cutscene_time += minf(delta, 0.05)
        if cutscene_time >= 18.0 and not cutscene_title_shown:
            cutscene_title_shown = true
            _show_season_end()
        queue_redraw()
    elif state == "playing":
        refresh_timer -= delta
        if refresh_timer <= 0.0:
            refresh_timer = 0.12
            if hud_score:
                hud_score.text = "سکه‌های این دور: %d" % world.earned_coins
            if hud_stage:
                hud_stage.text = "بی‌نهایت" if world.endless else "مرحله %d · %s" % [world.current_level, LevelManager.level_name(world.current_level)]

func _unhandled_input(event: InputEvent) -> void:
    if state != "playing":
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
            world.player.jump()
        elif event.keycode in [KEY_DOWN, KEY_S]:
            world.player.set_duck(true)
    elif event is InputEventKey and not event.pressed:
        if event.keycode in [KEY_DOWN, KEY_S]:
            world.player.set_duck(false)
    elif event is InputEventScreenTouch and event.pressed:
        if event.position.y < VIEW_H * 0.78:
            world.player.jump()

func _build_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    ui_root = Control.new()
    ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_root.layout_direction = Control.LAYOUT_DIRECTION_RTL
    ui_layer.add_child(ui_root)
    _build_login_page()
    _build_menu_page()
    _build_rewards_page()
    _build_skins_page()
    _build_shop_page()
    _build_hud()

func _new_page(page_name: String) -> Control:
    var page := Control.new()
    page.name = page_name
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.layout_direction = Control.LAYOUT_DIRECTION_RTL
    ui_root.add_child(page)
    pages[page_name] = page
    return page

func _background(parent: Control, color := Color("#100b20")) -> void:
    var bg := ColorRect.new()
    bg.color = color
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(bg)
    bg.z_index = -10

func _label(text: String, size: int = 24, color := Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _panel_style(color := Color("#211735"), border := Color("#59416f")) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.border_color = border
    s.set_border_width_all(1)
    s.set_corner_radius_all(18)
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 14
    s.content_margin_bottom = 14
    return s

func _button(text: String, callback: Callable, color := Color("#e9b64d"), height := 58) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0, height)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 21)
    b.add_theme_color_override("font_color", Color("#201426") if color.r > 0.45 else Color.WHITE)
    var normal := _panel_style(color, color.lightened(0.16))
    normal.set_border_width_all(1)
    b.add_theme_stylebox_override("normal", normal)
    var hover := _panel_style(color.lightened(0.12), color.lightened(0.3))
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), color))
    b.pressed.connect(callback)
    return b

func _build_login_page() -> void:
    var page := _new_page("login")
    _background(page, Color("#090713"))
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(500, 560)
    panel.add_theme_stylebox_override("panel", _panel_style(Color("#211832"), Color("#80633c")))
    center.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)
    box.add_child(_label("DINO RUSH", 38, Color("#ffdb86")))
    box.add_child(_label("ورود یا ساخت حساب", 25))
    login_name = LineEdit.new()
    login_name.placeholder_text = "نام اکانت (حداقل ۵ نویسه)"
    login_name.custom_minimum_size.y = 52
    login_name.add_theme_font_size_override("font_size", 20)
    box.add_child(login_name)
    login_password = LineEdit.new()
    login_password.placeholder_text = "رمز عبور"
    login_password.secret = true
    login_password.custom_minimum_size.y = 52
    login_password.add_theme_font_size_override("font_size", 20)
    box.add_child(login_password)
    login_phone = LineEdit.new()
    login_phone.placeholder_text = "شماره تلفن"
    login_phone.custom_minimum_size.y = 52
    login_phone.add_theme_font_size_override("font_size", 20)
    box.add_child(login_phone)
    box.add_child(_button("ورود / ساخت حساب آزمایشی", _submit_login, Color("#f2bd55"), 58))
    box.add_child(_label("نسخه اولیه: حساب‌ها فعلاً روی همین دستگاه ذخیره می‌شوند. ورود امن و همگام‌سازی آنلاین پس از فعال‌سازی API انجام می‌شود.", 14, Color("#c9bfd5")))
    var support := _label("پشتیبانی: @SharkFlux", 16, Color("#ffdc9a"))
    box.add_child(support)
    login_feedback = _label("", 15, Color("#ff8a9d"))
    box.add_child(login_feedback)

func _build_menu_page() -> void:
    var page := _new_page("menu")
    _background(page, Color("#100a21"))
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 16)
    page.add_child(margin)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 12)
    margin.add_child(v)
    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 58
    v.add_child(header)
    var brand := _label("DINO RUSH", 30, Color("#ffdb86"))
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)
    var account := _label("بازیکن", 17, Color("#ded4e9"))
    account.name = "AccountLabel"
    header.add_child(account)
    var coins := _button("سکه: ۰  +", _open_shop, Color("#e3b64d"), 48)
    coins.name = "CoinsButton"
    coins.custom_minimum_size.x = 180
    header.add_child(coins)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    v.add_child(body)
    var preview := PanelContainer.new()
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview.add_theme_stylebox_override("panel", _panel_style(Color("#171027"), Color("#5a416d")))
    body.add_child(preview)
    var pvbox := VBoxContainer.new()
    pvbox.alignment = BoxContainer.ALIGNMENT_CENTER
    preview.add_child(pvbox)
    pvbox.add_child(_label("DINO RUSH", 40, Color("#ffdc88")))
    pvbox.add_child(_label("دنیای ده مرحله‌ای", 22, Color("#d5c6e7")))
    var art := ColorRect.new()
    art.color = Color("#2d1a3d")
    art.custom_minimum_size = Vector2(0, 190)
    pvbox.add_child(art)
    var art_label := _label("DINO\nRUNNER", 38, Color("#c8f4ff"))
    art_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.add_child(art_label)
    pvbox.add_child(_label("مرحله و محیط به‌تدریج سخت‌تر می‌شود", 17, Color("#d8c7e5")))
    var actions := VBoxContainer.new()
    actions.custom_minimum_size.x = 390
    actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
    actions.alignment = BoxContainer.ALIGNMENT_CENTER
    actions.add_theme_constant_override("separation", 14)
    body.add_child(actions)
    actions.add_child(_label("انتخاب مرحله", 23, Color("#f5dfad")))
    var stage_row := HBoxContainer.new()
    actions.add_child(stage_row)
    stage_row.add_child(_button("مرحله قبل", _previous_level, Color("#4a3a60"), 48))
    var stage_label := _label("مرحله ۱", 22, Color.WHITE)
    stage_label.name = "StageSelectLabel"
    stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_row.add_child(stage_label)
    stage_row.add_child(_button("مرحله بعد", _next_level, Color("#4a3a60"), 48))
    actions.add_child(_button("شروع مرحله", _start_story, Color("#f0bd52"), 82))
    actions.add_child(_button("بازی بی‌نهایت", _start_endless, Color("#674c91"), 82))
    actions.add_child(_button("فروشگاه سکه", _open_shop, Color("#3e3157"), 52))
    var nav := HBoxContainer.new()
    nav.custom_minimum_size.y = 64
    nav.add_theme_constant_override("separation", 12)
    v.add_child(nav)
    nav.add_child(_button("بازی کردن", func(): _show_page("menu"), Color("#dcae4d"), 58))
    nav.add_child(_button("جوایز", func(): _show_page("rewards"), Color("#3e3157"), 58))
    nav.add_child(_button("اسکین‌ها", func(): _show_page("skins"), Color("#3e3157"), 58))
    var foot := _label("پشتیبانی: @SharkFlux", 13, Color("#a99bb9"))
    v.add_child(foot)

func _build_rewards_page() -> void:
    var page := _new_page("rewards")
    _background(page, Color("#100a21"))
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(760, 560)
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 16)
    panel.add_child(box)
    box.add_child(_label("جوایز و هدایا", 34, Color("#ffdb86")))
    var daily := _label("هدیه روزانه: ۵۰ سکه\nوضعیت: آماده دریافت", 23)
    daily.name = "DailyStatus"
    box.add_child(daily)
    box.add_child(_button("دریافت هدیه روزانه", _claim_daily, Color("#e7b84f"), 66))
    box.add_child(_button("جعبه شانسی · هزینه ۲۰۰ سکه", _open_box, Color("#7052a1"), 66))
    box.add_child(_button("بازگشت به بازی", func(): _show_page("menu"), Color("#403354"), 54))

func _build_skins_page() -> void:
    var page := _new_page("skins")
    _background(page, Color("#100a21"))
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    page.add_child(margin)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 10)
    margin.add_child(v)
    v.add_child(_label("اسکین‌ها و هلمت‌ها", 30, Color("#ffdb86")))
    var tabs := HBoxContainer.new()
    v.add_child(tabs)
    var skin_btn := _button("اسکین دایناسور", func(): _set_skin_tab("skin"), Color("#d9aa49"), 48)
    var helm_btn := _button("هلمت‌ها", func(): _set_skin_tab("helmet"), Color("#46365d"), 48)
    tabs.add_child(skin_btn)
    tabs.add_child(helm_btn)
    skin_tab_buttons["skin"] = skin_btn
    skin_tab_buttons["helmet"] = helm_btn
    skin_info = _label("یک ظاهر را انتخاب کن.", 18, Color("#e0d2ed"))
    v.add_child(skin_info)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    v.add_child(scroll)
    skin_grid = GridContainer.new()
    skin_grid.columns = 4
    skin_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    skin_grid.add_theme_constant_override("h_separation", 10)
    skin_grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(skin_grid)
    v.add_child(_button("بازگشت به بازی", func(): _show_page("menu"), Color("#403354"), 52))

func _build_shop_page() -> void:
    var page := _new_page("shop")
    _background(page, Color("#100a21"))
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(700, 470)
    panel.add_theme_stylebox_override("panel", _panel_style())
    center.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 18)
    panel.add_child(box)
    box.add_child(_label("فروشگاه سکه", 34, Color("#ffdb86")))
    box.add_child(_label("خرید آنلاین پس از اتصال API و فعال شدن پرداخت انجام می‌شود.\nدر این نسخه هیچ پرداخت واقعی یا افزایش سکه سمت کاربر فعال نیست.", 21, Color("#e2d5ed")))
    box.add_child(_button("ارتباط با پشتیبانی @SharkFlux", func(): OS.shell_open("https://t.me/SharkFlux"), Color("#7052a1"), 58))
    box.add_child(_button("بازگشت", func(): _show_page("menu"), Color("#403354"), 54))

func _build_hud() -> void:
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.visible = false
    ui_root.add_child(hud)
    var top := HBoxContainer.new()
    top.anchor_left = 0.02
    top.anchor_top = 0.02
    top.anchor_right = 0.98
    top.anchor_bottom = 0.13
    hud.add_child(top)
    hud_score = _label("سکه‌های این دور: ۰", 21, Color.WHITE)
    hud_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(hud_score)
    hud_stage = _label("مرحله ۱", 21, Color("#ffe2a0"))
    hud_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(hud_stage)
    var bottom := HBoxContainer.new()
    bottom.anchor_left = 0.04
    bottom.anchor_right = 0.96
    bottom.anchor_top = 0.83
    bottom.anchor_bottom = 0.98
    bottom.add_theme_constant_override("separation", 20)
    hud.add_child(bottom)
    var jump_btn := _button("پرش", func(): world.player.jump(), Color("#e9b84e"), 80)
    var duck_btn := _button("سر خوردن", func(): world.player.set_duck(false), Color("#574275"), 80)
    duck_btn.button_down.connect(func(): world.player.set_duck(true))
    duck_btn.button_up.connect(func(): world.player.set_duck(false))
    bottom.add_child(jump_btn)
    bottom.add_child(duck_btn)
    bottom.add_child(_button("توقف", _pause_to_menu, Color("#372b49"), 80))

func _show_page(page_name: String) -> void:
    state = page_name
    world.stop_run()
    world.visible = false
    hud.visible = false
    for key in pages.keys():
        pages[key].visible = key == page_name
    if page_name == "menu":
        _refresh_menu()
    elif page_name == "rewards":
        _refresh_rewards()
    elif page_name == "skins":
        _refresh_skins()

func _submit_login() -> void:
    var username := login_name.text.strip_edges()
    var password := login_password.text
    var phone := login_phone.text.strip_edges()
    if username.length() < 5:
        _notice("نام اکانت باید حداقل ۵ نویسه داشته باشد.")
        return
    if password.length() < 6:
        _notice("رمز عبور باید حداقل ۶ نویسه داشته باشد.")
        return
    if phone.length() < 8:
        _notice("شماره تلفن را کامل وارد کن.")
        return
    var safe_name := username.to_lower().replace("/", "_").replace("\\", "_").replace(":", "_")
    var path := PROFILE_DIR + "/" + safe_name + ".cfg"
    var user_root := DirAccess.open("user://")
    if user_root:
        user_root.make_dir_recursive("profiles")
    var cfg := ConfigFile.new()
    var salt := ""
    var hash := ""
    if cfg.load(path) == OK:
        salt = str(cfg.get_value("account", "salt", ""))
        hash = str(cfg.get_value("account", "password_hash", ""))
        if str(cfg.get_value("account", "phone", "")) != phone or _hash_password(password, salt) != hash:
            _notice("نام اکانت، رمز عبور یا شماره تلفن مطابقت ندارد.")
            return
    else:
        salt = "%s-%s-%s" % [str(randi()), str(Time.get_ticks_usec()), str(randi())]
        hash = _hash_password(password, salt)
        cfg.set_value("account", "salt", salt)
        cfg.set_value("account", "password_hash", hash)
        cfg.set_value("account", "phone", phone)
        cfg.set_value("account", "username", username)
        cfg.set_value("profile", "player_id", randi_range(100000, 999999))
        cfg.set_value("profile", "coins", 500)
        cfg.set_value("profile", "max_level", 1)
        cfg.set_value("profile", "daily_date", "")
        cfg.set_value("profile", "skin", "classic")
        cfg.set_value("profile", "helmet", "none")
        cfg.set_value("profile", "owned_skins", {"classic": true})
        cfg.set_value("profile", "owned_helmets", {"none": true})
        cfg.save(path)
    profile = {
        "username": username,
        "phone": phone,
        "player_id": int(cfg.get_value("profile", "player_id", 100000)),
        "coins": int(cfg.get_value("profile", "coins", 500)),
        "max_level": int(cfg.get_value("profile", "max_level", 1)),
        "daily_date": str(cfg.get_value("profile", "daily_date", "")),
        "skin": str(cfg.get_value("profile", "skin", "classic")),
        "helmet": str(cfg.get_value("profile", "helmet", "none")),
        "owned_skins": cfg.get_value("profile", "owned_skins", {"classic": true}),
        "owned_helmets": cfg.get_value("profile", "owned_helmets", {"none": true}),
        "path": path
    }
    selected_level = profile.max_level
    selected_skin = profile.skin
    selected_helmet = profile.helmet
    _show_page("menu")

func _hash_password(password: String, salt: String) -> String:
    var context := HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    context.update((salt + password).to_utf8_buffer())
    return context.finish().hex_encode()

func _save_profile() -> void:
    if profile.is_empty():
        return
    var cfg := ConfigFile.new()
    cfg.load(str(profile.path))
    cfg.set_value("profile", "player_id", profile.player_id)
    cfg.set_value("profile", "coins", profile.coins)
    cfg.set_value("profile", "max_level", profile.max_level)
    cfg.set_value("profile", "daily_date", profile.daily_date)
    cfg.set_value("profile", "skin", profile.skin)
    cfg.set_value("profile", "helmet", profile.helmet)
    cfg.set_value("profile", "owned_skins", profile.get("owned_skins", {"classic": true}))
    cfg.set_value("profile", "owned_helmets", profile.get("owned_helmets", {"none": true}))
    cfg.save(str(profile.path))

func _refresh_menu() -> void:
    var page: Control = pages["menu"]
    var account := page.find_child("AccountLabel", true, false) as Label
    var coins := page.find_child("CoinsButton", true, false) as Button
    var stage := page.find_child("StageSelectLabel", true, false) as Label
    if account:
        account.text = "%s  ·  شناسه %06d" % [profile.get("username", "بازیکن"), int(profile.get("player_id", 0))]
    if coins:
        coins.text = "سکه: %s  +" % _fa_number(int(profile.get("coins", 0)))
    selected_level = clampi(selected_level, 1, int(profile.get("max_level", 1)))
    if stage:
        stage.text = "مرحله %d" % selected_level

func _previous_level() -> void:
    selected_level = max(1, selected_level - 1)
    _refresh_menu()

func _next_level() -> void:
    selected_level = min(int(profile.get("max_level", 1)), selected_level + 1)
    _refresh_menu()

func _start_story() -> void:
    _start_game(false)

func _start_endless() -> void:
    _start_game(true)

func _start_game(endless_mode: bool) -> void:
    var skin := SkinPatchService.get_skin(selected_skin)
    world.start_run(selected_level, endless_mode, skin, selected_helmet)
    state = "playing"
    for key in pages.keys():
        pages[key].visible = false
    world.visible = true
    hud.visible = true
    result_panel = null

func _on_run_finished(success: bool, level: int, earned: int, was_endless: bool) -> void:
    world.visible = false
    hud.visible = false
    profile.coins = int(profile.get("coins", 0)) + earned
    if success and not was_endless:
        profile.max_level = max(int(profile.get("max_level", 1)), min(10, level + 1))
    _save_profile()
    if success and not was_endless and level == 10:
        state = "cutscene"
        cutscene_time = 0.0
        cutscene_title_shown = false
        queue_redraw()
        return
    if success:
        _show_result("مرحله %d کامل شد!\n%d سکه دریافت کردی." % [level, earned], "ادامه", _result_to_menu)
    else:
        _show_result("این دور تمام شد.\n%d سکه جمع کردی." % earned, "تلاش دوباره", _retry_last)

func _on_coin_collected(total_gain: int) -> void:
    if hud_score:
        hud_score.text = "سکه‌های این دور: %d" % total_gain

func _retry_last() -> void:
    if result_panel:
        result_panel.queue_free()
        result_panel = null
    _start_game(false)

func _result_to_menu() -> void:
    if result_panel:
        result_panel.queue_free()
        result_panel = null
    _show_page("menu")

func _pause_to_menu() -> void:
    world.stop_run()
    _show_result("بازی متوقف شد.", "بازگشت به منو", _result_to_menu)

func _show_result(message: String, button_text: String, callback: Callable) -> void:
    state = "result"
    if result_panel:
        result_panel.queue_free()
    result_panel = PanelContainer.new()
    result_panel.anchor_left = 0.5
    result_panel.anchor_top = 0.5
    result_panel.anchor_right = 0.5
    result_panel.anchor_bottom = 0.5
    result_panel.offset_left = -250
    result_panel.offset_top = -150
    result_panel.offset_right = 250
    result_panel.offset_bottom = 150
    result_panel.custom_minimum_size = Vector2(500, 300)
    result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#211832"), Color("#d2a34e")))
    ui_root.add_child(result_panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 20)
    result_panel.add_child(box)
    box.add_child(_label(message, 26, Color("#fff0d0")))
    box.add_child(_button(button_text, callback, Color("#e9b84e"), 62))
    box.add_child(_button("منوی اصلی", _result_to_menu, Color("#4c3a62"), 52))

func _show_season_end() -> void:
    state = "season_end"
    _show_result("این داستان ادامه دارد...\nپایان فصل اول", "بازگشت به منو", _result_to_menu)

func _claim_daily() -> void:
    var today := Time.get_date_string_from_system()
    if str(profile.get("daily_date", "")) == today:
        _notice("هدیه امروز را قبلاً دریافت کرده‌ای.")
        return
    profile.coins = int(profile.get("coins", 0)) + 50
    profile.daily_date = today
    _save_profile()
    _notice("۵۰ سکه به حساب آزمایشی اضافه شد.")
    _refresh_rewards()

func _open_box() -> void:
    if int(profile.get("coins", 0)) < 200:
        _notice("برای باز کردن جعبه به ۲۰۰ سکه نیاز داری.")
        return
    profile.coins = int(profile.coins) - 200
    var reward := randi_range(50, 160)
    profile.coins = int(profile.coins) + reward
    _save_profile()
    _notice("جعبه باز شد؛ %d سکه گرفتی." % reward)

func _refresh_rewards() -> void:
    var page: Control = pages["rewards"]
    var daily := page.find_child("DailyStatus", true, false) as Label
    if daily:
        var today := Time.get_date_string_from_system()
        var claimed := str(profile.get("daily_date", "")) == today
        daily.text = "هدیه روزانه: ۵۰ سکه\nوضعیت: " + ("فردا دوباره برگرد" if claimed else "آماده دریافت")

func _set_skin_tab(tab: String) -> void:
    skin_tab = tab
    _refresh_skins()

func _refresh_skins() -> void:
    if not skin_grid:
        return
    for child in skin_grid.get_children():
        child.queue_free()
    var catalog: Dictionary = SkinPatchService.catalog
    var list: Array = catalog.get("skins", []) if skin_tab == "skin" else catalog.get("helmets", [])
    for item in list:
        var id := str(item.get("id", ""))
        var title := str(item.get("name", id))
        var rarity := str(item.get("rarity", "common"))
        var color := Color.from_string(str(item.get("body", item.get("color", "#8fa3a8"))), Color.GRAY)
        var b := Button.new()
        b.custom_minimum_size = Vector2(180, 105)
        var owned_map: Dictionary = profile.get("owned_skins", {"classic": true}) if skin_tab == "skin" else profile.get("owned_helmets", {"none": true})
        var is_owned := bool(owned_map.get(id, false))
        var price := int(item.get("price", -1))
        var status := "در کلکسیون" if is_owned else ("رویدادی / کدی" if price < 0 else ("قیمت: %d سکه" % price))
        b.text = title + "\n" + rarity.to_upper() + "\n" + status
        b.add_theme_font_size_override("font_size", 17)
        b.add_theme_color_override("font_color", Color.WHITE)
        b.add_theme_stylebox_override("normal", _panel_style(color.darkened(0.48), color))
        b.add_theme_stylebox_override("hover", _panel_style(color.darkened(0.30), color.lightened(0.2)))
        b.pressed.connect(_select_cosmetic.bind(id, skin_tab))
        skin_grid.add_child(b)
    if skin_tab_buttons.has("skin"):
        skin_tab_buttons["skin"].add_theme_stylebox_override("normal", _panel_style(Color("#d9aa49") if skin_tab == "skin" else Color("#46365d")))
        skin_tab_buttons["helmet"].add_theme_stylebox_override("normal", _panel_style(Color("#d9aa49") if skin_tab == "helmet" else Color("#46365d")))
    skin_info.text = "اسکین فعال: %s  ·  هلمت فعال: %s" % [selected_skin, selected_helmet]

func _select_cosmetic(id: String, kind: String) -> void:
    var list: Array = SkinPatchService.catalog.get("skins", []) if kind == "skin" else SkinPatchService.catalog.get("helmets", [])
    var selected_item: Dictionary = {}
    for item in list:
        if str(item.get("id", "")) == id:
            selected_item = item
            break
    if selected_item.is_empty():
        return
    var owned_map: Dictionary = profile.get("owned_skins", {"classic": true}) if kind == "skin" else profile.get("owned_helmets", {"none": true})
    if not bool(owned_map.get(id, false)):
        var price := int(selected_item.get("price", -1))
        if price < 0:
            _notice("این ظاهر از طریق رویداد یا کد معتبر دریافت می‌شود.")
            return
        if int(profile.get("coins", 0)) < price:
            _notice("سکه کافی نیست.")
            return
        profile.coins = int(profile.coins) - price
        owned_map[id] = true
        if kind == "skin":
            profile.owned_skins = owned_map
        else:
            profile.owned_helmets = owned_map
    if kind == "skin":
        selected_skin = id
        profile.skin = id
    else:
        selected_helmet = id
        profile.helmet = id
    _save_profile()
    _refresh_skins()

func _on_skin_catalog_changed() -> void:
    if state == "skins":
        _refresh_skins()

func _open_shop() -> void:
    _show_page("shop")

func _notice(message: String) -> void:
    if state == "login" and login_feedback:
        login_feedback.text = message
        return
    _show_result(message, "متوجه شدم", _result_to_menu)

func _fa_number(value: int) -> String:
    var s := str(value)
    var western := "0123456789"
    var persian := "۰۱۲۳۴۵۶۷۸۹"
    for i in range(10):
        s = s.replace(western.substr(i, 1), persian.substr(i, 1))
    return s

func _draw() -> void:
    if state == "cutscene":
        _draw_cutscene()

func _draw_cutscene() -> void:
    var t := cutscene_time
    var red := clampf(t / 5.0, 0.0, 1.0)
    draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("#05030a").lerp(Color("#310711"), red))
    draw_circle(Vector2(1020, 135), 74, Color("#7c1726").lerp(Color("#c22c35"), clampf(t / 8.0, 0.0, 1.0)))
    # graveyard silhouettes
    for i in range(9):
        var x := float(i) * 160.0 + 20.0
        draw_line(Vector2(x, 550), Vector2(x + 6, 390 + float(i % 3) * 24), Color("#100810"), 12.0)
        draw_line(Vector2(x + 6, 430), Vector2(x - 35, 405), Color("#100810"), 7.0)
        draw_line(Vector2(x + 6, 450), Vector2(x + 45, 420), Color("#100810"), 7.0)
    draw_rect(Rect2(0, 550, VIEW_W, 170), Color("#10070d"))
    for i in range(12):
        var bx := float(i) * 115.0 + 10.0
        draw_line(Vector2(bx, 590 + float(i % 2) * 18), Vector2(bx + 70, 600), Color("#8c7778"), 5.0)
        draw_circle(Vector2(bx + 30, 595), 7, Color("#b49a9b"))
    if t < 17.0:
        var fall := clampf((t - 1.5) / 3.5, 0.0, 1.0)
        var dino_y := lerpf(-130.0, 475.0, fall)
        _draw_cutscene_dino(Vector2(420.0, dino_y), 1.0 + fall * 0.2, Color(1, 1, 1, 1.0))
        if t > 5.0:
            for i in range(5):
                var gx := 150.0 + float(i) * 235.0
                var gy := 500.0 - minf(1.0, (t - 5.0) / 2.0) * (50.0 + float(i % 3) * 25.0)
                draw_circle(Vector2(gx, gy), 28, Color(0.65, 0.78, 0.85, 0.23))
                draw_circle(Vector2(gx, gy - 5), 8, Color("#d9f3ff"))
        if t > 8.0:
            var a := clampf((t - 8.0) / 2.0, 0.0, 1.0)
            draw_colored_polygon(PackedVector2Array([Vector2(790, 500), Vector2(820, 300), Vector2(860, 220), Vector2(900, 290), Vector2(950, 190), Vector2(1000, 300), Vector2(1040, 220), Vector2(1090, 330), Vector2(1120, 500)]), Color(0.025, 0.008, 0.03, a))
            draw_circle(Vector2(915, 340), 8, Color(0.95, 0.05, 0.15, a))
            draw_circle(Vector2(990, 340), 8, Color(0.95, 0.05, 0.15, a))
        if t > 11.0:
            var a2 := clampf((t - 11.0) / 2.0, 0.0, 1.0)
            for i in range(6):
                var x := 280.0 + float(i) * 135.0
                draw_colored_polygon(PackedVector2Array([Vector2(x - 20, 550), Vector2(x - 25, 470), Vector2(x, 430), Vector2(x + 25, 470), Vector2(x + 22, 550)]), Color(0.08, 0.015, 0.05, a2))
        if t > 13.0:
            var a3 := clampf((t - 13.0) / 2.0, 0.0, 1.0)
            draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.0, 0.0, 0.0, a3 * 0.86))
            if t < 16.0:
                _draw_cutscene_dino(Vector2(420, 490), 1.0, Color(1, 1, 1, 1.0 - a3 * 0.45))
    if t > 17.0:
        var alpha := clampf((t - 17.0) / 1.0, 0.0, 1.0)
        draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0, 0, 0, alpha))
        draw_string(ThemeDB.fallback_font, Vector2(0, 370), "این داستان ادامه دارد...", HORIZONTAL_ALIGNMENT_CENTER, VIEW_W, 48, Color(1, 0.85, 0.72, alpha))

func _draw_cutscene_dino(at: Vector2, scale_value: float, tint: Color) -> void:
    draw_set_transform(at, 0.0, Vector2.ONE * scale_value)
    draw_colored_polygon(PackedVector2Array([Vector2(-80, 0), Vector2(-150, -35), Vector2(-115, 8), Vector2(-50, 25)]), tint.darkened(0.15))
    draw_circle(Vector2(-10, 0), 48, tint)
    draw_rect(Rect2(12, -70, 28, 72), tint)
    draw_circle(Vector2(52, -78), 29, tint)
    draw_circle(Vector2(69, -70), 5, Color("#10070d"))
    draw_line(Vector2(-30, 34), Vector2(-40, 80), tint, 18.0)
    draw_line(Vector2(18, 34), Vector2(35, 80), tint, 18.0)
    draw_set_transform(Vector2.ZERO)
