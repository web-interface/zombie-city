## [파일] scripts/weapons/particle_buffer.gd
## [하는 일] 연출 알갱이(불꽃·불씨·물방울·파편·연기) 묶음: 정해진 개수의 칸을 고리처럼 돌려 쓰는 버퍼. 칸마다 위치·속도·나이·수명·중력·색을 숫자 배열에 담아, 매 프레임 새 배열·사전을 만들지 않고 움직이고 그린다. 가득 차면 가장 오래된 칸을 덮어쓴다.
## [쓰는 곳] scripts/weapons/weapon_visuals.gd 가 하나 들고 add()·update()·draw_on() 을 부른다.
## [근거 문서] 12 §6 성능(웹·저가 폰에서 좀비 300마리 + 연출), 14 §2-7
class_name ParticleBuffer
extends RefCounted

var capacity: int = 0
var _positions := PackedVector2Array()
var _velocities := PackedVector2Array()
var _ages := PackedFloat32Array()
var _lives := PackedFloat32Array()     # 수명 0 = 빈 칸
var _gravities := PackedFloat32Array()
var _colors := PackedColorArray()
var _next_index: int = 0


func _init(new_capacity: int) -> void:
	capacity = new_capacity
	_positions.resize(capacity)
	_velocities.resize(capacity)
	_ages.resize(capacity)
	_lives.resize(capacity)
	_gravities.resize(capacity)
	_colors.resize(capacity)


## 알갱이 하나 (가득 차면 가장 오래된 칸을 덮어씀). gravity 가 음수면 떠오른다.
func add(at_position: Vector2, velocity: Vector2, life: float, color: Color, gravity: float) -> void:
	var index := _next_index
	_next_index = (_next_index + 1) % capacity
	_positions[index] = at_position
	_velocities[index] = velocity
	_ages[index] = 0.0
	_lives[index] = life
	_gravities[index] = gravity
	_colors[index] = color


func update(delta: float) -> void:
	for index: int in range(capacity):
		if _ages[index] >= _lives[index]:
			continue
		_ages[index] += delta
		_velocities[index] += Vector2(0.0, _gravities[index] * delta)
		_positions[index] += _velocities[index] * delta


## 살아 있는 알갱이를 1점씩, 나이가 들수록 흐리게
func draw_on(canvas: CanvasItem) -> void:
	for index: int in range(capacity):
		var age := _ages[index]
		var life := _lives[index]
		if age < life:
			canvas.draw_rect(Rect2(_positions[index].round(), Vector2.ONE), Color(_colors[index], 1.0 - age / life))
