## [파일] scripts/ui/retry_panel.gd
## [하는 일] 쓰러지거나 헬기를 놓쳤을 때 뜨는 창: "이 밤 다시 하기 (남은 n)" — 그 밤 처음부터 다시(판마다 2번), 또는 [그만하기] — 결과 화면. 뜬 직후 잘못 눌림은 TapGuard 로 막는다.
## [쓰는 곳] scripts/ui/hud.gd 가 만들고 open() 으로 연다. decided(true/false) 를 scripts/run/night_carry.gd 가 받는다. 자동 플레이 봇은 is_ready()·decide() 를 쓴다.
## [근거 문서] 15 §2 쓰러지면 그 밤 처음부터 다시 하기 2번
class_name RetryPanel
extends Control

signal decided(is_retry: bool)

const BUTTON_SIZE := Vector2(150, 30)

var _guard := TapGuard.new()
var _title: Label
var _retry_button: Button
var _quit_button: Button


func _ready() -> void:
	PixelUi.full_rect(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.02, 0.03, 0.86)
	add_child(PixelUi.full_rect(dim))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(PixelUi.centered(column))
	_title = PixelUi.label("", PixelUi.ALERT, false, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	var hint := PixelUi.label("이 밤 처음부터 다시 할 수 있어요", PixelUi.MUTED, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	_retry_button = _add_button(column, PixelUi.GOOD, true)
	_quit_button = _add_button(column, PixelUi.MUTED, false)
	_quit_button.text = "그만하기"


## end_reason: "died"(쓰러짐) · "helicopter_left"(헬기 놓침)
func open(retries_left: int, end_reason: String) -> void:
	_title.text = "헬기를 놓쳤어요…" if end_reason == "helicopter_left" else "물렸어요…"
	_retry_button.text = "이 밤 다시 하기 (남은 %d)" % retries_left
	_guard.open()
	visible = true


func is_open() -> bool:
	return visible


func is_ready() -> bool:
	return visible and _guard.is_ready()


## 자동 플레이 봇용
func decide(is_retry: bool) -> void:
	if visible:
		_close(is_retry)


func _add_button(column: VBoxContainer, accent: Color, is_retry: bool) -> Button:
	var new_button := PixelUi.button("", accent)
	new_button.custom_minimum_size = BUTTON_SIZE
	_guard.watch(new_button)
	new_button.pressed.connect(func() -> void:
		if _guard.accepts(new_button):
			_close(is_retry))
	column.add_child(new_button)
	return new_button


func _close(is_retry: bool) -> void:
	visible = false
	SoundPlayer.play("card_select")
	decided.emit(is_retry)


func _process(_delta: float) -> void:
	if visible:
		_retry_button.modulate.a = 0.45 + 0.55 * _guard.progress()
		_quit_button.modulate.a = _retry_button.modulate.a
