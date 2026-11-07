## [파일] scripts/ui/result_screen.gd
## [하는 일] 결과 화면: 큰 글씨 "버틴 밤 2" + "셋째 밤 1:12 · 도살자에게 당함", 처치·레벨·최대 연속·얻은 고철이 차오르는 숫자 줄, 그 아래 끌어 올리는 목록(새 기록·업적·해금 띠가 하나씩 날아 들어옴 → 아까운 표시 → 판 목표 3개 → 고철 항목별), 맨 아래 아주 큰 [바로 다시]와 [생존자 고르기]·[은신처].
## [쓰는 곳] scenes/result.tscn. 판이 끝나면 SceneRouter.finish_run() 이 연다. SceneRouter.last_run_result(판 결과)·last_settlement(정산)를 읽고, 목록 부품은 scripts/ui/result_details.gd 가, 맨 앞 온라인 순위 띠는 online_rank_line.gd 가 만든다.
## [근거 문서] 05 화면 목록(결과), 02 §9 승패, 13 (무엇에 당했는지), 14 §4 아까운 표시·한 판만 더
extends Control

const COUNT_UP_SECONDS := 0.8
const FIRST_BANNER_DELAY := 0.55     # 숫자가 거의 다 찬 뒤에 띠가 들어오게
const BANNER_GAP_SECONDS := 0.28
const BANNER_SLIDE_SECONDS := 0.22
const LIST_WIDTH := 164.0
const SIDE := 6.0
const STATS_TOP := 50.0
const LIST_TOP := 82.0
const BUTTONS_HEIGHT := 64.0
## 끝난 이유 → 부제 끝말 (이유 모를 실패가 없게 — 문서 12 §6)
const END_TEXTS := {
	"helicopter_left": "헬기를 놓침",
	"gave_up": "포기",
	"escaped": "구조 성공",
	"test_night_limit": "시험 밤 제한",
}
## 당한 이유의 마지막 낱말이 이것이면 공격·장판이라 '에 당함' (도살자 돌진에 · 산성 비에), 아니면 좀비 이름이라 '에게 당함'
const ATTACK_LAST_WORDS: Array[String] = ["돌진", "해머", "가르기", "식칼", "철근", "폭발", "웅덩이", "비", "토사물", "자국"]
const LONG_LIST_SECONDS := 1.6   # 띠가 많아도 이 시간 안에 다 들어오게 (첫 판엔 업적·도감이 한꺼번에 열림)

var _result: Dictionary = {}
var _settlement: Dictionary = {}
var _count_rows: Array[Dictionary] = []
var _time: float = 0.0
var _list: VBoxContainer
var _again_button: Button


func _ready() -> void:
	PixelUi.full_rect(self)
	_result = SceneRouter.last_run_result
	_settlement = SceneRouter.last_settlement
	var metrics: Dictionary = _settlement.get("metrics", RunMetrics.from_result(_result))
	var nights := int(metrics["nights_survived"])
	SoundPlayer.play_single_music("music_result")
	var background := ColorRect.new()
	background.color = Color("0e1a12") if nights >= 1 else Color("1a0e10")
	add_child(PixelUi.full_rect(background))
	_build_headline(metrics)
	_build_stats(metrics)
	_build_list()
	_build_buttons()


func _build_headline(metrics: Dictionary) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	column.offset_top = 6.0
	add_child(column)
	if bool(_result.get("daily_challenge", false)):
		column.add_child(_centered(PixelUi.label("오늘의 도전 · " + String(SceneRouter.daily_rule.get("name", "")), PixelUi.GOLD, true)))
	var nights := int(metrics["nights_survived"])
	var headline := _centered(PixelUi.label("버틴 밤 %d" % nights, PixelUi.GOOD if nights >= 1 else PixelUi.ALERT, false, true))
	headline.add_theme_font_size_override("font_size", 22)
	column.add_child(headline)
	column.add_child(_centered(PixelUi.label(_subtitle(metrics), PixelUi.MUTED, true)))


## "셋째 밤 1:12 · 도살자에게 당함"
func _subtitle(metrics: Dictionary) -> String:
	var seconds := maxi(0, floori(float(metrics["seconds_in_last_night"])))
	var when := "%s %d:%02d" % [RunMetrics.night_name(int(metrics["last_night"])), floori(seconds / 60.0), seconds % 60]
	var end_reason := String(_result.get("end_reason", "died"))
	if END_TEXTS.has(end_reason):
		return "%s · %s" % [when, END_TEXTS[end_reason]]
	var cause := String(_result.get("death_cause", ""))
	if cause.is_empty():
		return "%s · 물렸어요" % when
	# 낱말 끝 글자로 보면 '좀비'도 '비'로 끝나서, 띄어쓰기로 자른 마지막 낱말 전체를 본다 ("걷는 좀비에게" · "산성 비에")
	var words := cause.split(" ")
	var last_word := words[words.size() - 1]
	return "%s · %s%s 당함" % [when, cause, "에" if ATTACK_LAST_WORDS.has(last_word) else "에게"]


## 숫자 줄: 처치 · 레벨 · 최대 연속 · 고철 (0 에서 차오름)
func _build_stats(metrics: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_top = STATS_TOP
	row.offset_left = SIDE
	row.offset_right = -SIDE
	add_child(row)
	_add_count_cell(row, "처치", int(metrics["kills"]), PixelUi.INK)
	_add_count_cell(row, "레벨", int(metrics["level"]), PixelUi.INK)
	_add_count_cell(row, "최대 연속", int(metrics["max_combo"]), PixelUi.INK)
	_add_count_cell(row, "고철", int(_settlement.get("scrap_total", 0)), PixelUi.GOLD)


func _add_count_cell(row: HBoxContainer, title: String, target: int, color: Color) -> void:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cell)
	cell.add_child(_centered(PixelUi.label(title, PixelUi.MUTED, true)))
	var value := _centered(PixelUi.label("0", color, false, true))
	cell.add_child(value)
	_count_rows.append({"label": value, "target": target, "prefix": "+" if color == PixelUi.GOLD else ""})


## 가운데 목록: 띠는 처음엔 숨겨 두고 _process 가 차례로 날려 보낸다
func _build_list() -> void:
	var scroll := PixelUi.scroll_area()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = LIST_TOP
	scroll.offset_left = SIDE
	scroll.offset_right = -2.0
	scroll.offset_bottom = -BUTTONS_HEIGHT - 4.0
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(_list)
	var delay := FIRST_BANNER_DELAY
	if Online.can_submit(_result):   # 웹판 사람 판만 — 시험 봇·시험 옵션 판은 순위에 안 올림
		_add_delayed(OnlineRankLine.new(_result, LIST_WIDTH), delay, "")
	var recap: Dictionary = _result.get("hit_recap", {})
	if not recap.get("last_hits", []).is_empty():   # 무엇에 당했나 — 맨 앞 (문서 15 §7-3)
		_add_delayed(ResultDetails.build_hit_recap(recap, LIST_WIDTH), delay, "")
	var banners := ResultDetails.banner_items(_settlement)
	var gap := minf(BANNER_GAP_SECONDS, LONG_LIST_SECONDS / maxf(1.0, banners.size()))
	for item: Dictionary in banners:
		_add_delayed(ResultDetails.build_banner(item, LIST_WIDTH), delay, String(item["sound"]))
		delay += gap
	var near_miss: Array = _settlement.get("near_miss", [])
	if not near_miss.is_empty():
		_add_delayed(ResultDetails.build_near_miss(near_miss, LIST_WIDTH), delay, "ui_click")
		delay += BANNER_GAP_SECONDS
	var goals: Array = _settlement.get("goals", [])
	if not goals.is_empty():
		_add_delayed(ResultDetails.build_goals(goals, LIST_WIDTH), delay, "")
	_add_delayed(ResultDetails.build_scrap(_settlement.get("scrap_lines", []), int(_settlement.get("scrap_total", 0)), LIST_WIDTH), delay, "")


## 부품을 투명하게 넣어 두고 delay 뒤에 오른쪽에서 미끄러져 들어오게 (소리 하나씩 — 받는 맛)
func _add_delayed(part: Control, delay: float, sound_name: String) -> void:
	part.modulate.a = 0.0
	_list.add_child(part)
	var appear := part.create_tween()
	appear.tween_interval(delay)
	appear.tween_callback(func() -> void:
		if not sound_name.is_empty():
			SoundPlayer.play(sound_name)
		part.position.x += 24.0)
	appear.tween_property(part, "modulate:a", 1.0, BANNER_SLIDE_SECONDS)
	appear.parallel().tween_property(part, "position:x", -24.0, BANNER_SLIDE_SECONDS).as_relative().set_ease(Tween.EASE_OUT)


## 아주 큰 [바로 다시] (같은 조건 — 멈출 틈이 없게) + [생존자 고르기]·[은신처]
func _build_buttons() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	column.offset_top = -BUTTONS_HEIGHT
	column.offset_bottom = -6.0
	column.offset_left = SIDE + 4.0
	column.offset_right = -SIDE - 4.0
	add_child(column)
	_again_button = PixelUi.button("바로 다시", PixelUi.GOOD)
	_again_button.add_theme_font_override("font", PixelUi.FONT_BOLD)
	_again_button.add_theme_font_size_override("font_size", 16)
	_again_button.custom_minimum_size = Vector2(0, 32)
	PixelUi.on_press(_again_button, SceneRouter.restart_same_run)
	column.add_child(_again_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	for pair: Array in [["생존자 고르기", SceneRouter.go_to_survivor_select], ["은신처", SceneRouter.go_to_shelter]]:
		var small := PixelUi.button(String(pair[0]), PixelUi.INK)
		small.custom_minimum_size = Vector2(0, 20)
		small.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		PixelUi.on_press(small, pair[1])
		row.add_child(small)


func _centered(target: Label) -> Label:
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return target


## 숫자가 0 에서 차오르고(02 §12), [바로 다시]는 살짝 숨 쉬듯 밝아졌다 어두워짐 (눈이 가게)
func _process(delta: float) -> void:
	_time += delta
	var progress := clampf(_time / COUNT_UP_SECONDS, 0.0, 1.0)
	for row: Dictionary in _count_rows:
		var value_label: Label = row["label"]
		value_label.text = String(row["prefix"]) + RunMetrics.format_count(int(float(row["target"]) * ease(progress, 0.4)))
	_again_button.modulate = Color.WHITE.lerp(Color(1.25, 1.25, 1.25), 0.5 + 0.5 * sin(_time * 4.0))
