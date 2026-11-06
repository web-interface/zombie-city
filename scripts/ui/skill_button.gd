## [파일] scripts/ui/skill_button.gd
## [하는 일] 오른쪽 아래 스킬 버튼: 지금 스킬 아이콘, 다시 쓸 수 있을 때까지 테두리가 시계 방향으로 차오름, 준비되면 반짝임. 누르면 '눌렸음'을 기억했다가 run.gd 가 한 번 가져간다.
## [쓰는 곳] scripts/ui/hud.gd 가 만든다. SkillRunner 의 ready_ratio()·skill 을 읽는다.
## [근거 문서] 05 게임 화면 배치(스킬 버튼), 02 §2 조작
class_name SkillButton
extends Control

const SIZE := 30.0

var _skill_runner: SkillRunner
var _icon: Texture2D
var _was_pressed: bool = false
var _ready_glow_time: float = 0.0


func setup(skill_runner: SkillRunner) -> void:
	_skill_runner = skill_runner
	_skill_runner.skill_changed.connect(_on_skill_changed)
	_on_skill_changed(_skill_runner.skill_id)
	custom_minimum_size = Vector2.ONE * SIZE
	size = Vector2.ONE * SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func consume_press() -> bool:
	var pressed := _was_pressed
	_was_pressed = false
	return pressed


func _gui_input(event: InputEvent) -> void:
	var is_touch_down := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	var is_click_down := event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	if is_touch_down or is_click_down:
		_was_pressed = true
		accept_event()


func _process(delta: float) -> void:
	_ready_glow_time += delta
	queue_redraw()


func _on_skill_changed(_new_skill_id: String) -> void:
	_icon = load("res://art/sprites/icons/%s.png" % _skill_runner.skill["icon"])


func _draw() -> void:
	var center := Vector2.ONE * SIZE * 0.5
	var ratio := _skill_runner.ready_ratio()
	var is_ready := ratio >= 1.0
	draw_circle(center, SIZE * 0.5, Color(0.09, 0.1, 0.14, 0.85))
	var ring_color := PixelUi.GOLD if is_ready else PixelUi.MUTED
	var dots := 32
	for index: int in range(int(dots * ratio)):
		var point := center + Vector2.from_angle(-PI * 0.5 + TAU * index / dots) * (SIZE * 0.5 - 1.5)
		draw_rect(Rect2(point.round() - Vector2.ONE, Vector2.ONE * 2.0), ring_color)
	if _icon != null:
		var tint := Color.WHITE if is_ready else Color(0.55, 0.55, 0.6)
		draw_texture_rect(_icon, Rect2(center - Vector2.ONE * 10.0, Vector2.ONE * 20.0), false, tint)
	if is_ready and int(_ready_glow_time * 3.0) % 2 == 0:
		draw_arc(center, SIZE * 0.5 + 1.0, 0.0, TAU, 24, Color(PixelUi.GOLD, 0.6), 1.0)
