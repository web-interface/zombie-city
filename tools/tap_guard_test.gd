## [파일] tools/tap_guard_test.gd
## [하는 일] 잘못 눌림 막기 시험(입력 흉내, 화면 없이 됨): 한 판을 열고 조이스틱 손가락을 누른 채 레벨 업 창을 띄운 뒤 (a) 그 손가락을 카드 위로 끌어가 떼고 (b) 창이 뜬 뒤 0.1·0.3·0.5초에 아래쪽과 카드 위를 빠르게 두드리고 (c) 0.7초 뒤 카드를 정상으로 누른다. (a)(b)는 한 번도 안 골라지고 (c)만 골라져야 통과. 카드·버튼이 화면 아래 35%(엄지 자리)에 없는지도 본다. 결과를 줄마다 찍고 통과면 0, 아니면 1 로 끝난다.
## [쓰는 곳] 사람·검수관이 돌린다: "…/Godot_v4.7.2-stable_win64_console.exe" --headless --audio-driver Dummy --path . -s tools/tap_guard_test.gd -- --save=tools/out/tap_guard_save.json
## [근거 문서] 15 §8 잘못 눌림, scripts/ui/tap_guard.gd
extends SceneTree

const RUN_SCENE := "res://scenes/run.tscn"
const JOYSTICK_SPOT := Vector2(90, 280)
const BOTTOM_TAPS: Array[Vector2] = [Vector2(60, 290), Vector2(120, 300), Vector2(90, 260)]
const EARLY_TAP_SECONDS: Array[float] = [0.1, 0.3, 0.5]
const LATE_TAP_SECONDS := 0.7

var _picks: Array[float] = []   # 골라진 때 (창이 뜬 뒤 초)
var _opened_msec: int = -1
var _failures: PackedStringArray = []


func _initialize() -> void:
	root.get_node("SceneRouter").set("has_seen_first_run_hints", true)
	change_scene_to_file(RUN_SCENE)
	_run_test.call_deferred()


func _run_test() -> void:
	await _wait_seconds(0.8)
	var run := current_scene
	var level_up := run.get_node("Systems/LevelUp")
	var panel: Control = run.get_node("Hud").get("level_up_panel")
	level_up.connect("card_applied", func(_card: Dictionary) -> void: _picks.append(_since_open()))
	_touch(0, JOYSTICK_SPOT, true)                         # 조이스틱을 잡고 움직이는 중
	_drag(0, JOYSTICK_SPOT + Vector2(10, -4))
	level_up.call("add_experience", float(level_up.call("experience_needed")) * 1.05)
	while not panel.visible:
		await process_frame
	_opened_msec = Time.get_ticks_msec()
	var cards: Array = panel.get("_card_box").get_children()
	var card_center: Vector2 = (cards[0] as Control).get_global_rect().get_center()
	_check_layout(panel, cards)
	_drag(0, card_center)                                  # (a) 잡고 있던 손가락이 카드 위로 미끄러져 와서
	_touch(0, card_center, false)                          #     뗌
	print("(a) 조이스틱 손가락을 카드 위로 끌어와 뗌 → 골라진 수 %d" % _picks.size())
	for seconds: float in EARLY_TAP_SECONDS:               # (b) 0.1·0.3·0.5초에 아래쪽·카드 두드리기
		await _wait_until_open_seconds(seconds)
		for spot: Vector2 in BOTTOM_TAPS:
			_tap(1, spot)
		_tap(1, card_center)
		print("(b) %.1f초: 아래쪽 %d번 + 카드 1번 두드림 → 골라진 수 %d" % [seconds, BOTTOM_TAPS.size(), _picks.size()])
	var early_picks := _picks.size()
	await _wait_until_open_seconds(LATE_TAP_SECONDS)       # (c) 0.7초 뒤 정상 탭
	_tap(2, card_center)
	await process_frame
	print("(c) %.1f초: 카드 정상 탭 → 골라진 수 %d (창 열림 %s)" % [LATE_TAP_SECONDS, _picks.size(), panel.visible])
	if early_picks != 0:
		_failures.append("(a)(b) 에서 %d번 골라짐" % early_picks)
	if _picks.size() != 1:
		_failures.append("(c) 뒤 골라진 수가 1이 아님: %d" % _picks.size())
	print("결과: %s" % ("통과" if _failures.is_empty() else "실패 — " + ", ".join(_failures)))
	quit(0 if _failures.is_empty() else 1)


## 카드·버튼이 아래 35%(엄지 자리) 위에만 있나
func _check_layout(panel: Control, cards: Array) -> void:
	var limit := panel.get_viewport_rect().size.y * (1.0 - 0.35)
	var buttons: Array = cards.duplicate()
	buttons.append_array(panel.get("_reroll_button").get_parent().get_children())
	for button: Control in buttons:
		var rect := button.get_global_rect()
		print("배치: %s 위 %d · 아래 %d (엄지 자리 시작 %d)" % [button.get_class(), int(rect.position.y), int(rect.end.y), int(limit)])
		if rect.end.y > limit:
			_failures.append("엄지 자리에 걸친 버튼 (아래 끝 %d)" % int(rect.end.y))


func _tap(finger: int, spot: Vector2) -> void:
	_touch(finger, spot, true)
	_touch(finger, spot, false)


## 폰 손가락처럼: 화면 터치 + 그걸 흉내 낸 마우스 (버튼은 마우스로 받음)
func _touch(finger: int, spot: Vector2, is_pressed: bool) -> void:
	var window_spot := root.get_final_transform() * spot
	var touch := InputEventScreenTouch.new()
	touch.index = finger
	touch.position = window_spot
	touch.pressed = is_pressed
	Input.parse_input_event(touch)
	Input.flush_buffered_events()


func _drag(finger: int, spot: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = finger
	drag.position = root.get_final_transform() * spot
	Input.parse_input_event(drag)
	Input.flush_buffered_events()


func _since_open() -> float:
	return (Time.get_ticks_msec() - _opened_msec) / 1000.0


func _wait_until_open_seconds(seconds: float) -> void:
	while _since_open() < seconds:
		await process_frame


func _wait_seconds(seconds: float) -> void:
	var until := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame
