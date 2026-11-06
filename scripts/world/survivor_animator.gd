## [파일] scripts/world/survivor_animator.gd
## [하는 일] 생존자 그림 담당: 옷(전직하면 바뀜)에 맞는 동작 묶음을 끼우고, 움직임에 따라 서 있기·걷기 4장 × 3방향을 고르고, 맞으면 하얀 실루엣으로 잠깐 바꾼다.
## [쓰는 곳] scripts/world/survivor.gd 의 자식 노드. survivor.gd 가 매 프레임 animate() 를 부른다.
## [근거 문서] 06 그림 규칙·동작, 11 §4
class_name SurvivorAnimator
extends Sprite2D

## 걷기 4장의 길이: 발을 내딛는 장면(0·2)은 길게, 떼는 장면(1·3)은 짧게 — 무게가 실린 걸음 (06 AI 티 안 나게)
const WALK_FRAME_SECONDS: Array[float] = [0.13, 0.085, 0.13, 0.085]
const IDLE_FRAMES_PER_SECOND := 2.0
const DEATH_FRAMES_PER_SECOND := 6.0

var _normal_texture: Texture2D
var _flash_texture: Texture2D
var _flash_time_left: float = 0.0
var _animation_time: float = 0.0
var _last_direction_name: String = "down"
var _is_facing_left: bool = false
var _is_dead: bool = false


func _ready() -> void:
	hframes = SpriteSheetLayout.COLUMNS
	vframes = SpriteSheetLayout.HUMAN_ROW_COUNT
	offset = Vector2(0, -5)   # 발밑이 생존자 위치에 오게 (16×16 그림의 중심이 몸통 쯤이라 살짝 올림)


func set_outfit(outfit_name: String) -> void:
	_normal_texture = load("res://art/sprites/survivor_%s.png" % outfit_name)
	_flash_texture = load("res://art/sprites/survivor_%s_flash.png" % outfit_name)
	texture = _normal_texture


func flash(seconds: float) -> void:
	_flash_time_left = seconds


func play_death() -> void:
	_is_dead = true
	_animation_time = 0.0


## moving_direction 이 0 이면 서 있기. facing 은 마지막으로 바라본 방향.
func animate(delta: float, moving_direction: Vector2, facing: Vector2) -> void:
	_animation_time += delta
	_update_flash(delta)
	if _is_dead:
		var dead_frame := mini(int(_animation_time * DEATH_FRAMES_PER_SECOND), 2)
		frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "death", dead_frame)
		return
	_last_direction_name = SpriteSheetLayout.direction_name(facing)
	if absf(facing.x) > 0.01:
		_is_facing_left = facing.x < 0.0
	flip_h = _last_direction_name == "side" and _is_facing_left
	var is_moving := moving_direction.length() > 0.05
	if is_moving:
		var walk_action: String = SpriteSheetLayout.WALK_ACTIONS[_last_direction_name]
		frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, walk_action, _walk_frame_number())
	else:
		frame = SpriteSheetLayout.frame_index(SpriteSheetLayout.HUMAN_ROWS, "idle_" + _last_direction_name, int(_animation_time * IDLE_FRAMES_PER_SECOND))


## 장면마다 길이가 다른 걸음: 한 바퀴 시간 안에서 지금 몇 번째 장면인지
func _walk_frame_number() -> int:
	var cycle := 0.0
	for seconds: float in WALK_FRAME_SECONDS:
		cycle += seconds
	var into_cycle := fmod(_animation_time, cycle)
	for index: int in range(WALK_FRAME_SECONDS.size()):
		into_cycle -= WALK_FRAME_SECONDS[index]
		if into_cycle < 0.0:
			return index
	return 0


func _update_flash(delta: float) -> void:
	if _flash_time_left > 0.0:
		_flash_time_left -= delta
		texture = _flash_texture if _flash_time_left > 0.0 else _normal_texture
