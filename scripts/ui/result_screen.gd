## [파일] scripts/ui/result_screen.gd
## [하는 일] 결과 화면: 탈출 성공("구조 성공!")·실패("물렸어요…") 큰 글씨, 실패면 무엇에 당했는지, 버틴 시간·처치·레벨·전직·아슬아슬하게 산 횟수를 숫자가 차오르며 보여 준다. 다시 하기(같은 생존자)·생존자 바꾸기 버튼.
## [쓰는 곳] scenes/result.tscn. 판이 끝나면 SceneRouter.finish_run() 이 연다. SceneRouter.last_run_result 를 읽는다.
## [근거 문서] 05 화면 목록(결과), 02 §9 승패, 13 (무엇에 당했는지 보여 주기)
extends Control

const COUNT_UP_SECONDS := 0.8
## 끝난 이유마다 큰 글씨 (이유 모를 실패가 없게 — 문서 12 §6)
const HEADLINES := {
	"escaped": "구조 성공!",
	"died": "물렸어요…",
	"helicopter_left": "헬기를 놓쳤어요…",
	"gave_up": "포기했어요",
}

var _result: Dictionary = {}
var _rows: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	PixelUi.full_rect(self)
	_result = SceneRouter.last_run_result
	var is_escaped := bool(_result.get("is_escaped", false))
	SoundPlayer.play_single_music("music_result")
	var background := ColorRect.new()
	background.color = Color("0e1a12") if is_escaped else Color("1a0e10")
	add_child(PixelUi.full_rect(background))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.custom_minimum_size = Vector2(150, 0)
	var end_reason := String(_result.get("end_reason", "died"))
	var headline := PixelUi.label(String(HEADLINES.get(end_reason, "물렸어요…")), PixelUi.GOOD if is_escaped else PixelUi.ALERT, false, true)
	headline.add_theme_font_size_override("font_size", 22)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(headline)
	var cause := _cause_text(end_reason, String(_result.get("death_cause", "")))
	if not cause.is_empty():
		var cause_label := PixelUi.label(cause, PixelUi.MUTED, true)
		cause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(cause_label)
	_add_count_row(column, "버틴 시간", float(_result.get("survived_seconds", 0.0)), true)
	_add_count_row(column, "처치", float(_result.get("kills", 0)), false)
	_add_count_row(column, "레벨", float(_result.get("level", 1)), false)
	var branch := String(_result.get("branch", ""))
	column.add_child(_row_label("전직", branch if not branch.is_empty() else "-"))
	column.add_child(_row_label("아슬아슬 생존", "%d번" % int(_result.get("near_death_saves", 0))))
	column.add_child(_build_buttons())
	add_child(PixelUi.centered(column))


func _cause_text(end_reason: String, death_cause: String) -> String:
	match end_reason:
		"died":
			if death_cause.is_empty():
				return ""
			# 좀비에게는 '에게', 돌진 같은 공격에는 '에' ("도살자 돌진에게"는 어색함 — 마지막 검수)
			return "%s%s 당함" % [death_cause, "에" if death_cause.ends_with("돌진") else "에게"]
		"helicopter_left":
			return "헬기가 떠날 때까지 착륙 지점에 못 탔어요"   # 시각을 박아 두면 data 가 바뀔 때 틀려짐
	return ""


func _add_count_row(column: VBoxContainer, title: String, target: float, is_time: bool) -> void:
	var row := _row_label(title, "0")
	column.add_child(row)
	_rows.append({"label": row.get_child(1), "target": target, "is_time": is_time})


func _row_label(title: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var left := PixelUi.label(title, PixelUi.MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(PixelUi.label(value, PixelUi.INK))
	return row


func _build_buttons() -> VBoxContainer:
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	var again := PixelUi.button("다시 하기", PixelUi.GOOD)
	again.pressed.connect(func() -> void: SceneRouter.start_run(SceneRouter.selected_survivor_id))
	buttons.add_child(again)
	var change := PixelUi.button("생존자 바꾸기", PixelUi.INK)
	change.pressed.connect(SceneRouter.go_to_survivor_select)
	buttons.add_child(change)
	return buttons


## 숫자가 0 에서 차오른다 (02 §12 숫자는 튀어 오르는 애니메이션)
func _process(delta: float) -> void:
	_time += delta
	var progress := clampf(_time / COUNT_UP_SECONDS, 0.0, 1.0)
	for row: Dictionary in _rows:
		var value := float(row["target"]) * ease(progress, 0.4)
		var value_label: Label = row["label"]
		value_label.text = PixelUi.format_time(value) if bool(row["is_time"]) else str(int(value))
