## [파일] scripts/ui/leaderboard_screen.gd
## [하는 일] 온라인 순위 화면: 위에 칸 고르기(전체 · 생존자별 · 오늘의 도전), 생존자별이면 [◀ 생존자 ▶], 그 아래 내 순위(하늘색 테두리 — 로그인 안 했으면 [로그인하고 순위에 올리기]), 위 50명 줄(1~3위 금·은·동). 순위는 버틴 밤 → 처치 → 짧은 총 시간. 웹판이 아니면 '웹판에서 볼 수 있어요'.
## [쓰는 곳] scenes/leaderboard.tscn. 타이틀 [순위]에서 SceneRouter.go_to_leaderboard() 로 온다. scripts/meta/online.gd 로 순위를 받는다.
## [근거 문서] 05 화면 목록(순위), 07 온라인 순위표
extends MenuScreen

const TAB_ALL := "all"
const TAB_SURVIVOR := "survivor"
const TAB_DAILY := "daily"
const TABS: Array[Array] = [[TAB_ALL, "전체"], [TAB_SURVIVOR, "생존자별"], [TAB_DAILY, "오늘의 도전"]]
const PODIUM_COLORS: Array[Color] = [Color("ffd166"), Color("d7dde8"), Color("d39a6a")]   # 1·2·3위 금·은·동
const MINE_EDGE := Color("6cc6ff")
const ROW_HEIGHT := 24.0

var _tab: String = TAB_ALL
var _survivor_index: int = 0
var _survivor_ids: Array[String] = []
var _request_number: int = 0   # 칸을 빨리 바꾸면 늦게 온 옛 답은 버린다


func _ready() -> void:
	build_frame("순위", Color("0f1117"))
	_survivor_ids = GameData.entry_ids("survivors")
	_survivor_index = maxi(0, _survivor_ids.find(SceneRouter.selected_survivor_id))
	Online.watch_state(_on_login_state_changed)   # 로그인 창에서 로그인하면 내 순위 칸을 다시
	_show_tab(TAB_ALL)


func _show_tab(tab: String) -> void:
	_tab = tab
	clear_body()
	body.add_child(_build_tabs())
	if tab == TAB_SURVIVOR:
		body.add_child(_build_survivor_picker())
	elif tab == TAB_DAILY:
		body.add_child(PixelUi.label("%s · %s" % [DailyChallenge.today_key(), _survivor_role(DailyChallenge.survivor_for(DailyChallenge.today_key()))], PixelUi.MUTED, true))
	var state := Online.state()
	set_header_value(String(state["username"]))
	if not Online.is_available():
		body.add_child(PixelUi.small_lines("순위표는 웹판(web-interface.github.io/zombie-city)에서 볼 수 있어요.", PixelUi.MUTED, BODY_WIDTH))
		return
	body.add_child(PixelUi.label("불러오는 중…", PixelUi.MUTED, true))
	_request_number += 1
	Online.fetch_rank(_board(), _on_rank_answer.bind(_request_number))


func _board() -> String:
	if _tab == TAB_SURVIVOR:
		return Online.board_for_survivor(_survivor_ids[_survivor_index])
	if _tab == TAB_DAILY:
		return Online.board_for_daily(DailyChallenge.today_key())
	return Online.BOARD_ALL


func _build_tabs() -> HBoxContainer:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	for pair: Array in TABS:
		var tab := PixelUi.button(String(pair[1]), PixelUi.GOLD if pair[0] == _tab else PixelUi.MUTED)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 18)
		PixelUi.on_press(tab, _show_tab.bind(String(pair[0])))
		tabs.add_child(tab)
	return tabs


func _build_survivor_picker() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var previous := PixelUi.button("◀", PixelUi.INK)
	PixelUi.on_press(previous, _step_survivor.bind(-1))
	row.add_child(previous)
	var name_label := PixelUi.label(_survivor_role(_survivor_ids[_survivor_index]), PixelUi.INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var next := PixelUi.button("▶", PixelUi.INK)
	PixelUi.on_press(next, _step_survivor.bind(1))
	row.add_child(next)
	return row


func _step_survivor(step: int) -> void:
	_survivor_index = posmod(_survivor_index + step, _survivor_ids.size())
	_show_tab(TAB_SURVIVOR)


func _on_login_state_changed(_current: Dictionary) -> void:
	_show_tab(_tab)


## 답이 오면: 불러오는 중 글을 지우고 내 순위 + 줄들 (그사이 칸을 바꿨으면 옛 답은 버림)
func _on_rank_answer(answer: Dictionary, request_number: int) -> void:
	if request_number != _request_number:
		return
	body.get_child(body.get_child_count() - 1).queue_free()
	if not bool(answer.get("ok", false)):
		body.add_child(PixelUi.small_lines("순위를 못 불러왔어요. 인터넷을 확인해 주세요.", PixelUi.ALERT, BODY_WIDTH))
		var retry := PixelUi.button("다시 불러오기", PixelUi.INK)
		PixelUi.on_press(retry, _show_tab.bind(_tab))
		body.add_child(retry)
		return
	body.add_child(_build_mine(answer))
	var rows: Array = answer.get("rows", [])
	if rows.is_empty():
		body.add_child(PixelUi.small_lines("아직 아무도 없어요. 첫 기록을 남겨 보세요.", PixelUi.MUTED, BODY_WIDTH))
	for row: Dictionary in rows:
		body.add_child(_build_row(row))


## 내 순위 칸: 로그인했으면 내 기록과 순위, 아니면 로그인 버튼
func _build_mine(answer: Dictionary) -> Control:
	if not Online.is_logged_in():
		var login := PixelUi.button("로그인하고 순위에 올리기", MINE_EDGE)
		login.custom_minimum_size = Vector2(BODY_WIDTH, 22)
		PixelUi.on_press(login, Online.open_login)
		return login
	var mine: Variant = answer.get("me")
	var panel := row_panel(MINE_EDGE)
	if mine is Dictionary:
		var record: Dictionary = mine
		panel.add_child(_row_content("내 순위 %d위" % int(record.get("rank", 0)), _record_text(record), MINE_EDGE))
	else:
		panel.add_child(_row_content("내 순위", "아직 이 판 기록이 없어요", MINE_EDGE))
	return panel


func _build_row(row: Dictionary) -> PanelContainer:
	var place := int(row.get("rank", 0))
	var is_podium := place >= 1 and place <= PODIUM_COLORS.size()
	var color := PODIUM_COLORS[place - 1] if is_podium else PixelUi.INK
	var is_mine := bool(row.get("me", false))
	var panel := row_panel(MINE_EDGE if is_mine else (color.darkened(0.45) if is_podium else PixelUi.PANEL_EDGE))
	panel.custom_minimum_size.y = ROW_HEIGHT
	var detail := _record_text(row)
	if _tab != TAB_SURVIVOR:
		detail = _survivor_role(String(row.get("survivor", ""))) + " · " + detail
	panel.add_child(_row_content("%d  %s" % [place, String(row.get("username", ""))], detail, color))
	return panel


func _row_content(title: String, detail: String, color: Color) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(PixelUi.label(title, color))
	column.add_child(PixelUi.label(detail, PixelUi.MUTED, true))
	return column


## "밤 3 · 처치 1,240 · 10:12"
func _record_text(record: Dictionary) -> String:
	return "밤 %d · 처치 %s · %s" % [int(record.get("nights", 0)), RunMetrics.format_count(int(record.get("kills", 0))), PixelUi.format_time(float(record.get("seconds", 0.0)))]


## 생존자 id → 직업 이름 (지금 게임 표에 없는 옛·새 생존자면 빈 글자 대신 id)
func _survivor_role(survivor_id: String) -> String:
	var entry := GameData.entry("survivors", survivor_id) if _survivor_ids.has(survivor_id) else {}
	return String(entry.get("role", survivor_id))
