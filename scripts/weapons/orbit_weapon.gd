## [파일] scripts/weapons/orbit_weapon.gd
## [하는 일] 몸 주위를 도는 무기(톱날 드론·메스·사냥개): 드론·칼날 여러 개가 생존자 둘레를 돌며 닿는 좀비를 같은 좀비당 hit_interval_seconds 마다 한 번씩 벤다. 드론 그림(돌아가는 2장)·메스 칼날(은빛 짧은 선 + 잔상)·사냥개(달리는 방향 걷기 그림)도 직접 그린다. 진화하면 금색, 톱날 폭풍은 도는 반경이 넓어졌다 좁아졌다 한다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "orbit" 인 무기로 만들고, 그리기 때 draw_on() 을 부른다.
## [근거 문서] 03 §2 무기(톱날 드론), 04 §3 (몸 주위를 도는 작은 드론), 14 §2-2 메스·§2-4 수술 칼날 폭풍·톱날 폭풍·§3-1 사냥개·늑대 무리
class_name OrbitWeapon
extends Weapon

const DRONE_TEXTURES: Array[Texture2D] = [preload("res://art/sprites/drone_a.png"), preload("res://art/sprites/drone_b.png")]
const DRONE_HIT_RADIUS := 5.0
const BLADE_COLOR := Color("e3e8f0")
const BLADE_TRAIL_COLOR := Color("8fa3bf")
const BLADE_LENGTH := 3.0
const RADIUS_WAVE_SPEED := 2.0   # 반경이 넓어졌다 좁아졌다 하는 빠르기 (초당 라디안)
const DOG_TEXTURE: Texture2D = preload("res://art/sprites/hunting_dog.png")
const DOG_FRAME_SIZE := Vector2(16, 16)
const DOG_STEPS_PER_SECOND := 9.0

var _spin_angle: float = 0.0
var _spin_time: float = 0.0
var _positions: Array[Vector2] = []   # 드론 위치 — 매 프레임 새 배열을 만들지 않고 다시 씀


## 드론은 시간마다 쏘는 게 아니라 계속 돌며 닿으면 때린다 — 공통 틀의 다시 공격 시간을 쓰지 않는다.
func update(delta: float) -> void:
	var stats := numbers()
	_spin_angle += float(stats["spin_speed"]) * delta
	_spin_time += delta
	var interval := float(stats["hit_interval_seconds"]) / context.survivor.stats.value("attack_speed_multiplier")
	for drone_position: Vector2 in drone_positions():
		for zombie: Zombie in context.horde.in_radius(drone_position, DRONE_HIT_RADIUS):
			if zombie.try_take_hit_from(weapon_id, interval):
				strike(zombie, float(stats["damage"]), context.survivor.position, float(stats["knockback"]))
				play_attack_sound()


func drone_positions() -> Array[Vector2]:
	var stats := numbers()
	var count := int(stats["drone_count"])
	var wave := 1.0 + float(stats.get("radius_wave", 0.0)) * sin(_spin_time * RADIUS_WAVE_SPEED)
	var radius := area_radius(float(stats["radius"])) * wave
	_positions.resize(count)
	for index: int in range(count):
		_positions[index] = context.survivor.position + Vector2.from_angle(_spin_angle + TAU * index / count) * radius
	return _positions


func draw_on(canvas: CanvasItem) -> void:
	if look == "blade":
		_draw_blades(canvas)
		return
	if look == "dog":
		_draw_dogs(canvas)
		return
	var texture := DRONE_TEXTURES[int(_spin_time * 14.0) % 2]
	var tint := EVOLVED_COLOR if is_evolved else Color.WHITE
	for drone_position: Vector2 in drone_positions():
		canvas.draw_texture(texture, (drone_position - texture.get_size() * 0.5).round(), tint)


## 메스: 도는 방향으로 누운 짧은 칼날 + 바로 뒤 흐린 잔상 (진화하면 금색)
func _draw_blades(canvas: CanvasItem) -> void:
	var color := EVOLVED_COLOR if is_evolved else BLADE_COLOR
	var center := context.survivor.position
	for drone_position: Vector2 in drone_positions():
		var tangent := (drone_position - center).orthogonal().normalized()
		var tip := (drone_position + tangent * BLADE_LENGTH * 0.5).round()
		var tail := (drone_position - tangent * BLADE_LENGTH * 0.5).round()
		canvas.draw_line(tail - tangent * 2.0, tail, Color(BLADE_TRAIL_COLOR, 0.5), 1.0)
		canvas.draw_line(tail, tip, color, 1.0)
		canvas.draw_rect(Rect2(tip, Vector2.ONE), Color.WHITE)


## 사냥개: 도는 방향(원의 접선)으로 달리는 걷기 그림 (art/sprites/hunting_dog.png — 좀비와 같은 줄 배치). 진화(늑대 무리)는 금빛
static func draw_dog(canvas: CanvasItem, at_position: Vector2, running_direction: Vector2, step_time: float, tint: Color) -> void:
	var direction_name := SpriteSheetLayout.direction_name(running_direction)
	var frame := SpriteSheetLayout.frame_index(SpriteSheetLayout.ZOMBIE_ROWS, SpriteSheetLayout.WALK_ACTIONS[direction_name], int(step_time * DOG_STEPS_PER_SECOND))
	var region := Rect2(Vector2(frame % SpriteSheetLayout.COLUMNS, floori(frame / float(SpriteSheetLayout.COLUMNS))) * DOG_FRAME_SIZE, DOG_FRAME_SIZE)
	var size := DOG_FRAME_SIZE
	if direction_name == "side" and running_direction.x < 0.0:
		size.x = -size.x   # 왼쪽으로 달리면 오른쪽 그림을 뒤집는다
	var top_left := (at_position - DOG_FRAME_SIZE * 0.5 - Vector2(0.0, 3.0)).round()
	canvas.draw_texture_rect_region(DOG_TEXTURE, Rect2(top_left + (Vector2(DOG_FRAME_SIZE.x, 0.0) if size.x < 0.0 else Vector2.ZERO), size), region, tint)


func _draw_dogs(canvas: CanvasItem) -> void:
	var tint := EVOLVED_COLOR if is_evolved else Color.WHITE
	var center := context.survivor.position
	var spin_sign := signf(float(numbers()["spin_speed"]))
	for dog_position: Vector2 in drone_positions():
		draw_dog(canvas, dog_position, -(dog_position - center).orthogonal() * spin_sign, _spin_time, tint)   # 각도가 커지는 쪽 = 달리는 쪽
