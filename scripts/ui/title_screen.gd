## [파일] scripts/ui/title_screen.gd
## [하는 일] 타이틀 화면: 새벽시 밤 도시 실루엣 앞 밤거리에 좀비 몇 마리가 비틀거리며 지나가고 가로등이 깜빡인다. 게임 이름 아래 버튼 — 큰 [출동!](생존자 고르기), [은신처]·[오늘의 도전], [순위]·[도감]·[업적]·[설정] — 과 가진 고철·최고 기록, 웹판이면 맨 아래 작은 로그인 상태(누르면 로그인 창). 강화할 고철이 있거나 오늘의 도전을 아직 안 했으면 그 버튼이 깜빡인다. 자동 플레이면 바로 판으로 넘어간다.
## [쓰는 곳] scenes/title.tscn (게임을 켜면 처음 여는 장면). 설정 창(settings_panel.gd)·오늘의 도전 창(daily_challenge_panel.gd)을 겹쳐 띄운다.
## [근거 문서] 05 화면 목록(타이틀), 04 §1 설정, 06 밤 분위기, 14 §3·§4
extends Control

const ZOMBIE_SHEETS: Array[String] = ["zombie_walker", "zombie_runner", "zombie_hazmat"]
const WALKING_ZOMBIES := 5
const STREET_TOP := 122.0       # 좀비가 걷는 줄 (제목 아래, 버튼 위)
const GROUND_LINE := 164.0
const BUTTON_TOP := 176.0
const MENU_WIDTH := 152.0
const SKYLINE: Texture2D = preload("res://art/sprites/title_skyline.png")   # 새벽시 밤 도시 실루엣 (180×90, 하늘 투명)
const SKYLINE_ALPHA := 0.55     # 제목 글자가 묻히지 않게 흐리게

var _time: float = 0.0
var _zombies: Array[Sprite2D] = []
var _login_line: Button   # 맨 아래 로그인 상태 (웹판만)
var _blinking: Array[Control] = []   # 눌러 보라고 깜빡이는 버튼 (강화 가능·오늘의 도전 안 함)


func _ready() -> void:
	PixelUi.full_rect(self)
	SoundPlayer.play_single_music("music_title")
	if SceneRouter.is_autoplay():
		# 장면이 막 붙는 중(_ready)에는 장면을 바꿀 수 없어서 한 박자 뒤에 (엔진 오류 'Parent node is busy')
		SceneRouter.start_run.call_deferred(SceneRouter.selected_survivor_id)
		return
	_build_street()
	_build_title()
	_build_buttons()
	_build_footer()


func _build_street() -> void:
	for index: int in range(WALKING_ZOMBIES):
		var zombie := Sprite2D.new()
		zombie.texture = load("res://art/sprites/%s.png" % ZOMBIE_SHEETS[index % ZOMBIE_SHEETS.size()])
		zombie.hframes = SpriteSheetLayout.COLUMNS
		zombie.vframes = SpriteSheetLayout.ZOMBIE_ROW_COUNT
		zombie.position = Vector2(randf_range(-40.0, 200.0), STREET_TOP + index * 8.0)
		zombie.modulate = Color(0.55, 0.6, 0.75)
		add_child(zombie)
		_zombies.append(zombie)


func _build_title() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.add_child(_centered(PixelUi.label("새벽시의 마지막 밤", PixelUi.MUTED, true)))
	var title := _centered(PixelUi.label("좀비 도시", PixelUi.INK, false, true))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	column.add_child(_centered(PixelUi.label("밤마다 3분, 헬기를 잡아라", PixelUi.GOLD)))
	var top_area := PixelUi.centered(column)
	top_area.offset_bottom = -212.0
	add_child(top_area)


func _build_buttons() -> void:
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 6)
	# 화면이 넓어져도(가로로 긴 창) 가운데에 오게 위쪽 가운데 기준으로 둔다
	menu.set_anchors_preset(Control.PRESET_CENTER_TOP)
	menu.offset_left = -MENU_WIDTH * 0.5
	menu.offset_right = MENU_WIDTH * 0.5
	menu.offset_top = BUTTON_TOP
	add_child(menu)
	var start := PixelUi.button("출동!", PixelUi.GOOD)
	start.add_theme_font_override("font", PixelUi.FONT_BOLD)
	start.custom_minimum_size = Vector2(0, 30)
	PixelUi.on_press(start, func() -> void: if Online.require_login(): SceneRouter.go_to_survivor_select())
	menu.add_child(start)
	var can_upgrade := Shelter.cheapest_next_cost() > 0 and SaveData.scrap() >= Shelter.cheapest_next_cost()
	var is_daily_new := not DailyChallenge.is_played_today()
	var middle_row := _button_row(menu)
	var shelter := _row_button(middle_row, "은신처", PixelUi.GOOD if can_upgrade else PixelUi.INK, SceneRouter.go_to_shelter)
	var daily := _row_button(middle_row, "오늘의 도전", PixelUi.GOLD if is_daily_new else PixelUi.INK, func() -> void: if Online.require_login(): add_child(DailyChallengePanel.new()))
	if can_upgrade:
		_blinking.append(shelter)
	if is_daily_new:
		_blinking.append(daily)
	var bottom_row := _button_row(menu)
	_row_button(bottom_row, "순위", PixelUi.MUTED, SceneRouter.go_to_leaderboard)
	_row_button(bottom_row, "도감", PixelUi.MUTED, SceneRouter.go_to_codex)
	_row_button(bottom_row, "업적", PixelUi.MUTED, SceneRouter.go_to_achievements)
	_row_button(bottom_row, "설정", PixelUi.MUTED, _open_settings)


func _button_row(menu: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	menu.add_child(row)
	return row


func _row_button(row: HBoxContainer, text: String, accent: Color, action: Callable) -> Button:
	var new_button := PixelUi.button(text, accent)
	new_button.custom_minimum_size = Vector2(0, 22)
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PixelUi.on_press(new_button, action)
	row.add_child(new_button)
	return new_button


## 맨 아래: 가진 고철 · 최고 기록 (다음 목표가 늘 보이게 — 문서 14 §4)
func _build_footer() -> void:
	var best_night := int(RunMetrics.totals_from_save()["best_night_any"])
	var text := "고철 %s" % RunMetrics.format_count(SaveData.scrap())
	if best_night > 0:
		text += " · 최고 버틴 밤 %d" % best_night
	var footer := _centered(PixelUi.label(text, PixelUi.MUTED, true))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -30.0
	footer.offset_bottom = -18.0
	add_child(footer)
	_build_login_line()


## 맨 아래 작은 로그인 상태 (웹판만) — 누르면 로그인 창. 웹판은 로그인해야 시작해서, 로그아웃 상태면 켜자마자 로그인 창
func _build_login_line() -> void:
	if not Online.is_available():
		return
	_login_line = Button.new()
	var login_line := _login_line
	login_line.flat = true
	login_line.add_theme_font_override("font", PixelUi.FONT_SMALL)
	login_line.add_theme_font_size_override("font_size", PixelUi.SIZE_SMALL)
	login_line.add_theme_color_override("font_color", Color("6cc6ff"))
	login_line.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	login_line.offset_top = -17.0
	login_line.offset_bottom = -3.0
	login_line.grow_horizontal = Control.GROW_DIRECTION_BOTH
	PixelUi.on_press(login_line, Online.open_login)
	add_child(login_line)
	_show_login_state(Online.state())
	Online.watch_state(_show_login_state)


func _show_login_state(current: Dictionary) -> void:
	var name_text := String(current.get("username", ""))
	_login_line.text = "로그인이 필요해요" if name_text.is_empty() else name_text + " 님 · 순위 참가 중"
	if String(current.get("state", "")) == "out":
		Online.require_login()


func _open_settings() -> void:
	add_child(SettingsPanel.new())


func _centered(target: Label) -> Label:
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return target


func _process(delta: float) -> void:
	_time += delta
	for control: Control in _blinking:
		control.modulate.a = 0.65 + 0.35 * absf(sin(_time * 3.0))
	for index: int in range(_zombies.size()):
		var zombie := _zombies[index]
		zombie.position.x += (6.0 + index * 1.5) * delta
		if zombie.position.x > 200.0:
			zombie.position.x = -20.0
		zombie.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.ZOMBIE_ROWS, "walk_side", int(_time * 5.0 + index))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0f1117"))   # 배경 (자식 노드보다 먼저 그려져 가로등 빛을 가리지 않게 여기서)
	draw_texture(SKYLINE, Vector2(roundf((size.x - SKYLINE.get_width()) * 0.5), GROUND_LINE - SKYLINE.get_height()), Color(1, 1, 1, SKYLINE_ALPHA))
	# 가로등 하나가 가끔 깜빡인다 (계단식 빛 원 세 겹)
	var is_on := fmod(_time, 3.1) > 0.18
	var lamp := Vector2(size.x * 0.72, STREET_TOP - 4.0)
	if is_on:
		for step: int in range(3):
			draw_circle(lamp, 34.0 - step * 10.0, Color(1.0, 0.85, 0.55, 0.05 + step * 0.04))
	draw_rect(Rect2(lamp - Vector2(1, 1), Vector2(3, 3)), Color("f0e3a0") if is_on else Color("5a5440"))
	draw_rect(Rect2(0, GROUND_LINE, size.x, 1), Color("2a2f3b"))
