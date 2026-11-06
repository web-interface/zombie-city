## [파일] scripts/ui/floating_joystick.gd
## [하는 일] 떠 있는 조이스틱: 화면 아무 데나 누른 곳이 중심이 되고, 끄는 방향·거리를 direction(길이 0~1)으로 알려 준다. 버튼(스킬·일시정지) 위를 누른 건 무시한다(버튼이 먼저 받음).
## [쓰는 곳] scripts/ui/hud.gd 가 만들고, run.gd 가 Hud.joystick_direction() 으로 읽는다.
## [근거 문서] 02 §2 조작, 05 게임 화면 배치
class_name FloatingJoystick
extends Control

const RADIUS := 22.0
const KNOB_RADIUS := 8.0
const DEAD_ZONE := 0.15

var direction: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func release() -> void:
	_touch_index = -1
	direction = Vector2.ZERO
	queue_redraw()


## 버튼이 먼저 입력을 가져가도록 _unhandled_input 에서 받는다.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_center = touch.position
			_knob = _center
		elif not touch.pressed and touch.index == _touch_index:
			release()
		queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		var offset := (drag.position - _center).limit_length(RADIUS)
		_knob = _center + offset
		direction = offset / RADIUS if offset.length() / RADIUS > DEAD_ZONE else Vector2.ZERO
		queue_redraw()


func _draw() -> void:
	if _touch_index == -1:
		return
	var dots := 24
	for index: int in range(dots):
		var point := _center + Vector2.from_angle(TAU * index / dots) * RADIUS
		draw_rect(Rect2(point.round(), Vector2.ONE), Color(1, 1, 1, 0.35))
	draw_circle(_knob.round(), KNOB_RADIUS, Color(1, 1, 1, 0.22))
	draw_circle(_knob.round(), KNOB_RADIUS - 3.0, Color(1, 1, 1, 0.18))
