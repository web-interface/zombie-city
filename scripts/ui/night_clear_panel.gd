## [파일] scripts/ui/night_clear_panel.gd
## [하는 일] 헬기를 탄 뒤 뜨는 '밤 생존' 창: "첫째 밤 생존!", 이번 밤 처치·레벨·최대 연속, 보상(체력 절반 회복 + 카드 한 장 더), 다음 밤 경고("좀비가 더 세고 많아져요"), 큰 [둘째 밤으로] 버튼. 누르면 next_requested 를 보내고 닫힌다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 open() 으로 연다. run.gd 가 next_requested 를 받아 다음 밤을 시작한다. 자동 플레이 봇은 hud.continue_night() 로 누른다.
## [근거 문서] 14 §1-1 밤 이어가기·§4 중독 설계(멈출 틈 없이 '다음 밤?'), 05 화면 목록
class_name NightClearPanel
extends Control

signal next_requested

const INPUT_GUARD_MILLISECONDS := 400.0   # 헬기 버티던 손가락이 그대로 눌러 넘어가지 않게
const TITLE_BOUNCE_SPEED := 5.0      # 제목 반짝임 빠르기

var _title: Label
var _stats_box: VBoxContainer
var _next_button: Button
var _opened_at_msec: int = 0
var _time: float = 0.0


func setup() -> void:
	PixelUi.full_rect(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.86)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(PixelUi.centered(column))
	_title = PixelUi.label("", PixelUi.GOLD, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 2)
	column.add_child(_stats_box)
	_next_button = PixelUi.button("", PixelUi.GOOD)
	_next_button.custom_minimum_size = Vector2(150, 30)
	_next_button.pressed.connect(_on_next_pressed)
	column.add_child(_next_button)


## summary = {"night_name", "next_night_name", "kills", "level", "best_combo", "heal_percent"}
func open(summary: Dictionary) -> void:
	_title.text = "%s 생존!" % summary["night_name"]
	for child: Node in _stats_box.get_children():
		child.queue_free()
	_add_line("처치 %s · 레벨 %d" % [RunMetrics.format_count(int(summary["kills"])), summary["level"]], PixelUi.INK)   # 줄마다 짧게 (한 글자만 넘어가지 않게 — 검수 지적)
	_add_line("최대 연속 %s" % RunMetrics.format_count(int(summary["best_combo"])), PixelUi.INK)
	_add_line("체력 %d%% 회복 + 카드 한 장" % summary["heal_percent"], PixelUi.GOOD)
	_add_line("%s은 좀비가 더 세고 많아요" % summary["next_night_name"], PixelUi.ALERT)
	_next_button.text = "%s으로" % summary["next_night_name"]
	_opened_at_msec = Time.get_ticks_msec()
	_time = 0.0
	visible = true


func is_open() -> bool:
	return visible


## 자동 플레이 봇·키보드용
func press_next() -> void:
	if visible:
		_close_and_continue()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_title.modulate.a = 0.7 + 0.3 * absf(sin(_time * TITLE_BOUNCE_SPEED))   # 제목이 반짝반짝
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
		_on_next_pressed()


func _on_next_pressed() -> void:
	if Time.get_ticks_msec() - _opened_at_msec < INPUT_GUARD_MILLISECONDS:
		return
	_close_and_continue()


func _close_and_continue() -> void:
	visible = false
	SoundPlayer.play("card_select")
	next_requested.emit()


func _add_line(text: String, color: Color) -> void:
	var line := PixelUi.small_lines(text, color, 160.0)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	for child: Node in line.get_children():
		(child as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_box.add_child(line)
