## [파일] scripts/run/run_input.gd
## [하는 일] 한 판의 입력 읽기: 이동 방향(키보드 방향키·WASD 가 먼저, 없으면 화면 조이스틱)과 스킬 누름(스페이스 또는 스킬 버튼). 자동 플레이 시험이면 봇에게 묻는다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 매 프레임 move_direction()·wants_skill() 을 부른다.
## [근거 문서] 02 §2 조작, 12 §4 자동 플레이 봇
class_name RunInput
extends RefCounted

var _hud: Hud
var _autoplay: Node = null


func setup(hud: Hud, autoplay: Node) -> void:
	_hud = hud
	_autoplay = autoplay


func move_direction() -> Vector2:
	if _autoplay != null:
		return _autoplay.move_direction()
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	var keys := (keyboard + wasd).limit_length(1.0)
	return keys if keys.length() > 0.0 else _hud.joystick_direction()


func wants_skill() -> bool:
	if _autoplay != null:
		return _autoplay.wants_skill()
	return Input.is_key_pressed(KEY_SPACE) or _hud.consume_skill_press()
