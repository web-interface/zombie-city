## [파일] scripts/run/run_camera.gd
## [하는 일] 한 판 카메라: 생존자를 따라가고(픽셀이 떨리지 않게 정수 위치로), '충격 값' 방식으로 화면을 흔든다 — 충격을 쌓았다가 시간에 따라 줄이고, 실제 흔들림은 충격 값의 제곱이라 작은 충격은 거의 안 흔들리고 큰 충격만 확 흔들린다. 설정에서 흔들림을 끌 수 있다.
## [쓰는 곳] scenes/run.tscn 의 Camera. run.gd 가 follow() 를, 효과가 필요할 때 RunContext.shake() 가 add_trauma() 를 부른다.
## [근거 문서] 02 §12 손맛·설정, 13 커뮤니티·디자인 조사(충격 값 제곱, 최대 3점, 어지러움 → 끄기 옵션)
class_name RunCamera
extends Camera2D

## 움직이는 쪽을 이만큼 더 보여 준다 (세로 화면이라 옆·앞이 좁아서 — 국내 조사)
const LOOK_AHEAD_DISTANCE := 14.0
const LOOK_AHEAD_FOLLOW_SPEED := 2.5

## 0 이면 흔들림 끔 (설정)
var shake_strength_multiplier: float = 1.0
var _trauma: float = 0.0
var _decay_per_second: float = 1.5
var _max_shake_pixels: float = 3.0
var _look_ahead: Vector2 = Vector2.ZERO


func setup(juice_rules: Dictionary) -> void:
	_decay_per_second = float(juice_rules["trauma_decay_per_second"])
	_max_shake_pixels = float(juice_rules["max_shake_pixels"])


## amount: 0~1 충격 (내가 맞음 0.25, 폭발 0.4, 보스 처치 0.5 …)
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount * shake_strength_multiplier, 0.0, 1.0)


## moving_direction 쪽으로 화면을 조금 앞서 보여 준다 (천천히 따라가서 어지럽지 않게).
func follow(target_position: Vector2, delta: float, moving_direction: Vector2) -> void:
	_look_ahead = _look_ahead.lerp(moving_direction * LOOK_AHEAD_DISTANCE, minf(1.0, LOOK_AHEAD_FOLLOW_SPEED * delta))
	_trauma = maxf(_trauma - _decay_per_second * delta, 0.0)
	var strength := _trauma * _trauma * _max_shake_pixels
	var shake_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	global_position = (target_position + _look_ahead + shake_offset).round()


func view_size() -> Vector2:
	return get_viewport_rect().size / zoom
