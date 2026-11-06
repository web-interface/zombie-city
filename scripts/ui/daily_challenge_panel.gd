## [파일] scripts/ui/daily_challenge_panel.gd
## [하는 일] 오늘의 도전 창(타이틀 위에 겹쳐 뜸): 오늘 날짜, 오늘의 생존자(걷는 모습·이름), 오늘의 규칙, 오늘 내 최고 기록과 한 판 수, [도전!]·[닫기]. 잠긴 생존자가 걸리면 '맛보기'라고 알려 준다.
## [쓰는 곳] scripts/ui/title_screen.gd 의 [오늘의 도전] 이 띄운다. [도전!] → SceneRouter.start_daily_challenge(). scripts/meta/daily_challenge.gd 를 읽는다.
## [근거 문서] 04 §9 오늘의 도전, 14 §3·§4 매일 할 이유, 05 화면 목록(오늘의 도전)
class_name DailyChallengePanel
extends Control

const WINDOW_WIDTH := 156.0
const PREVIEW_HEIGHT := 40.0
const WALK_FRAME_SECONDS := 0.12

var _preview: Sprite2D
var _time: float = 0.0


func _ready() -> void:
	PixelUi.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(PixelUi.full_rect(dim))
	add_child(PixelUi.centered(_build_window()))


func _process(delta: float) -> void:
	_time += delta
	_preview.frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "walk_down", int(_time / WALK_FRAME_SECONDS))


func _build_window() -> PanelContainer:
	var today := DailyChallenge.today_key()
	var survivor_id := DailyChallenge.survivor_for(today)
	var survivor := GameData.entry("survivors", survivor_id)
	var rule := DailyChallenge.rule_for(today)
	var window := PixelUi.panel(PixelUi.PANEL, PixelUi.GOLD.darkened(0.3))
	window.custom_minimum_size = Vector2(WINDOW_WIDTH, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	window.add_child(column)
	column.add_child(_centered_label("오늘의 도전", PixelUi.GOLD, false, true))
	column.add_child(_centered_label(_date_text(today), PixelUi.MUTED, true))
	column.add_child(_build_preview(String(survivor["outfit"])))
	column.add_child(_centered_label("%s %s" % [survivor["role"], survivor["name"]], PixelUi.INK))
	if not Unlocks.is_unlocked(survivor_id):
		column.add_child(_centered_label("아직 잠긴 생존자 — 오늘만 맛보기", PixelUi.GOLD, true))
	column.add_child(_centered_label("규칙: " + String(rule["name"]), PixelUi.ALERT))
	column.add_child(PixelUi.small_lines(String(rule["text"]), PixelUi.INK, WINDOW_WIDTH - 8.0))
	column.add_child(PixelUi.small_lines(_record_text(), PixelUi.GOOD, WINDOW_WIDTH - 8.0))
	column.add_child(_build_buttons())
	return window


func _build_preview(outfit: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(WINDOW_WIDTH - 8.0, PREVIEW_HEIGHT)
	_preview = Sprite2D.new()
	_preview.texture = load("res://art/sprites/survivor_%s.png" % outfit)
	_preview.hframes = SpriteSheetLayout.COLUMNS
	_preview.vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
	_preview.scale = Vector2.ONE * 2.0
	_preview.position = Vector2((WINDOW_WIDTH - 8.0) * 0.5, PREVIEW_HEIGHT * 0.5)
	holder.add_child(_preview)
	return holder


func _build_buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var close := PixelUi.button("닫기", PixelUi.MUTED)
	close.custom_minimum_size = Vector2(48, 24)
	PixelUi.on_press(close, queue_free, "ui_back")
	row.add_child(close)
	var start := PixelUi.button("도전!", PixelUi.GOLD)
	start.custom_minimum_size = Vector2(0, 24)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PixelUi.on_press(start, SceneRouter.start_daily_challenge)
	row.add_child(start)
	return row


func _record_text() -> String:
	var record := DailyChallenge.today_record()
	if record.is_empty() or not record.has("best_nights"):
		return "아직 안 했어요 · 내일이면 바뀌어요"
	return "오늘 최고: 버틴 밤 %d · 처치 %s (%d판)" % [int(record["best_nights"]), RunMetrics.format_count(int(record["best_kills"])), int(record["plays"])]


## "2026-11-07" → "11월 7일"
func _date_text(date_key: String) -> String:
	var parts := date_key.split("-")
	return "%d월 %d일" % [int(parts[1]), int(parts[2])]


func _centered_label(text: String, color: Color, is_small: bool = false, is_bold: bool = false) -> Label:
	var new_label := PixelUi.label(text, color, is_small, is_bold)
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return new_label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
