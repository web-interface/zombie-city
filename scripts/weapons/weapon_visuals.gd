## [파일] scripts/weapons/weapon_visuals.gd
## [하는 일] 무기·히든 스킬의 눈에 띄는 연출만 그린다: 번개(지그재그 하얀 번쩍)·하늘 번개, 물줄기(굵은 파란 선 + 물방울)·테이프 줄, 폭발(원 + 파편 + 연기), 충격파·전기·화염 고리, 폭격 예고 원, 화면 번쩍, 불꽃·불씨·연기 알갱이. 게임 규칙에는 영향이 없다. 180×320 픽셀 화면이라 1점 단위로 그린다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 빛 층(어둠을 안 받음)에 만들고, 무기(Weapon.visuals())·무기 장판(weapon_zones.gd)·히든 스킬(hidden_skill_effects.gd)이 부른다.
## [근거 문서] 14 §2-7 눈에 띄는 연출, 06 손맛·AI 티(빛도 픽셀 단계로), 12 §6 성능(개수 상한, 알갱이는 ParticleBuffer 고리 버퍼)
class_name WeaponVisuals
extends Node2D

const DRAW_LAYER := 15                 # 좀비·무기 칸(12) 위, 피해 숫자(20) 아래
const MAX_BOLTS := 48                  # 한꺼번에 보이는 번개 줄기 상한 (좀비 300마리 + 연출이 저가 폰에서 돌게)
const MAX_BEAMS := 16
const MAX_SHAPES := 48
const PARTICLE_CAPACITY := 400         # 알갱이는 이 개수 고리 버퍼를 돌려 쓴다 (매 프레임 새 배열을 안 만들려고)
const BOLT_SECONDS := 0.14
const BOLT_STEP := 7.0                 # 번개가 꺾이는 간격(점)
const BOLT_JAG := 3.0                  # 꺾일 때 옆으로 튀는 거리(점)
const SKY_BOLT_HEIGHT := 150.0         # 하늘 번개가 시작하는 높이 (화면 위쪽 밖)
const BEAM_SECONDS := {"water": 0.22, "tape": 0.4}
const EXPLOSION_SECONDS := 0.35
const RING_SECONDS := 0.3
const DEBRIS_PER_EXPLOSION := 10
const FALL_GRAVITY := 120.0            # 파편·물방울이 떨어지는 힘
const RISE_GRAVITY := -14.0            # 불씨·연기가 떠오르는 힘

const WHITE := Color("ffffff")
const LIGHTNING_GLOW := Color("8fd3ff")
const GOLD := Color("ffd166")
const WATER_DEEP := Color("2f86ff")
const WATER_LIGHT := Color("bfe6ff")
const TAPE_COLOR := Color("d9b36c")
const TAPE_STRIPE := Color("8c6a2e")
const SMOKE_COLOR := Color("4a4d57")
const WARNING_COLOR := Color("ff4d4d")
const SHOCK_COLOR := Color("fff2b0")
const FIRE_COLORS: Array[Color] = [Color("ffe08a"), Color("ff9a3c"), Color("ff5a2a")]
const DEBRIS_COLORS: Array[Color] = [Color("3b3f4a"), Color("6b5a48"), Color("ff9a3c")]

var _bolts: Array[Dictionary] = []
var _beams: Array[Dictionary] = []
## 고리·폭발·예고 원·화면 번쩍 — "style" 로 구분해 한 목록에
var _shapes: Array[Dictionary] = []
var _particles := ParticleBuffer.new(PARTICLE_CAPACITY)
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context
	z_as_relative = false
	z_index = DRAW_LAYER


## 지그재그 번개 한 줄기 (테이저건·제세동기). 진화 무기는 금빛 테두리.
func lightning(from_position: Vector2, to_position: Vector2, is_evolved: bool) -> void:
	_push(_bolts, MAX_BOLTS, {"points": _zigzag(from_position, to_position), "time": 0.0, "life": BOLT_SECONDS, "glow": GOLD if is_evolved else LIGHTNING_GLOW})
	spray(to_position, WHITE, 3, 30.0)


## 하늘에서 내리꽂는 번개 (낙뢰) — 화면 위에서 땅까지 + 땅에 번쩍 고리
func sky_bolt(target: Vector2) -> void:
	lightning(target + Vector2(randf_range(-BOLT_STEP, BOLT_STEP), -SKY_BOLT_HEIGHT), target, true)
	_add_shape("ring", target, 12.0, RING_SECONDS, WHITE)


## 물줄기(water)·테이프(tape) 일직선. 물줄기는 물방울이 사방으로 튄다.
func beam(from_position: Vector2, to_position: Vector2, width: float, look_name: String, is_evolved: bool) -> void:
	var life := float(BEAM_SECONDS.get(look_name, RING_SECONDS))
	_push(_beams, MAX_BEAMS, {"from": from_position, "to": to_position, "width": width, "look": look_name, "time": 0.0, "life": life, "is_evolved": is_evolved})
	if look_name != "water":
		return
	var direction := (to_position - from_position).normalized()
	for index: int in range(8):
		var along := from_position.lerp(to_position, randf())
		var velocity := direction.orthogonal() * randf_range(-25.0, 25.0) + direction * randf_range(10.0, 40.0)
		add_particle(along, velocity, randf_range(0.2, 0.4), WATER_LIGHT, FALL_GRAVITY)


## 폭발: 하얗게 → 주황 → 빨갛게 커지는 원 + 고리 + 파편·연기 (소포 폭탄·조명탄·슬러그·폭격)
func explosion(center: Vector2, radius: float, is_evolved: bool) -> void:
	_add_shape("explosion", center, radius, EXPLOSION_SECONDS, GOLD if is_evolved else FIRE_COLORS[1])
	for index: int in range(DEBRIS_PER_EXPLOSION):
		var direction := Vector2.from_angle(randf() * TAU)
		add_particle(center, direction * randf_range(radius, radius * 3.0), randf_range(0.3, 0.6), DEBRIS_COLORS.pick_random(), FALL_GRAVITY)
	puff(center, SMOKE_COLOR, 4, radius * 0.5)


## 넓어지는 충격파 고리 두 겹 (확성기·민방위 사이렌)
func shockwave(center: Vector2, radius: float, is_evolved: bool) -> void:
	_add_shape("shockwave", center, radius, RING_SECONDS + 0.1, GOLD if is_evolved else SHOCK_COLOR)


## 지직거리는 전기 고리 (제세동기)
func electric_ring(center: Vector2, radius: float, is_evolved: bool) -> void:
	_add_shape("electric", center, radius, RING_SECONDS * 0.7, GOLD if is_evolved else LIGHTNING_GLOW)
	_add_shape("ring", center, radius * 0.6, RING_SECONDS * 0.5, WHITE)
	for index: int in range(12):   # 고리에서 튀는 불똥
		var point := center + Vector2.from_angle(TAU * index / 12.0) * radius
		add_particle(point, Vector2.from_angle(randf() * TAU) * 20.0, randf_range(0.1, 0.25), WHITE if index % 2 == 0 else LIGHTNING_GLOW, 0.0)


## 화염 고리 + 불씨 (백드래프트)
func fire_ring(center: Vector2, radius: float) -> void:
	_add_shape("fire_ring", center, radius, RING_SECONDS * 1.5, FIRE_COLORS[1])
	for index: int in range(16):
		var point := center + Vector2.from_angle(TAU * index / 16.0) * radius * 0.8
		add_particle(point, Vector2.from_angle(randf() * TAU) * 12.0, randf_range(0.3, 0.6), FIRE_COLORS.pick_random(), RISE_GRAVITY)


## 폭격 예고: 깜빡이는 빨간 원 + 줄어드는 안쪽 원 (억울하지 않게 — 문서 14 §4 공정한 어려움)
func warning_circle(center: Vector2, radius: float, seconds: float) -> void:
	_add_shape("warning", center, radius, seconds, WARNING_COLOR)


## 화면 전체가 잠깐 번쩍 (심정지·히든 스킬)
func screen_flash(color: Color, seconds: float) -> void:
	_add_shape("flash", Vector2.ZERO, 0.0, seconds, color)


## 불꽃 튀기 (절단기): direction 쪽으로 빠르게 튀고 떨어진다
func sparks(at_position: Vector2, direction: Vector2, count: int) -> void:
	for index: int in range(count):
		var velocity := direction.rotated(randf_range(-0.9, 0.9)) * randf_range(30.0, 70.0)
		add_particle(at_position, velocity, randf_range(0.12, 0.25), FIRE_COLORS[randi() % 2], FALL_GRAVITY)


## 사방으로 튀는 알갱이 (번개 끝·유리 깨짐)
func spray(at_position: Vector2, color: Color, count: int, speed: float) -> void:
	for index: int in range(count):
		add_particle(at_position, Vector2.from_angle(randf() * TAU) * randf_range(speed * 0.4, speed), randf_range(0.15, 0.3), color, 0.0)


## 천천히 떠오르는 연기·구름 알갱이
func puff(at_position: Vector2, color: Color, count: int, spread: float) -> void:
	for index: int in range(count):
		var offset := Vector2.from_angle(randf() * TAU) * randf() * spread
		add_particle(at_position + offset, Vector2(randf_range(-6.0, 6.0), -8.0), randf_range(0.5, 0.9), color, RISE_GRAVITY * 0.3)


## 알갱이 하나 (고리 버퍼 — 가득 차면 가장 오래된 칸을 덮어씀)
func add_particle(at_position: Vector2, velocity: Vector2, life: float, color: Color, gravity: float) -> void:
	_particles.add(at_position, velocity, life, color, gravity)


func _process(delta: float) -> void:
	_age(_bolts, delta)
	_age(_beams, delta)
	_age(_shapes, delta)
	_particles.update(delta)
	queue_redraw()


## 시간을 흘리고 끝난 것을 그 자리에서 뺀다 (새 배열을 만들지 않게)
func _age(items: Array[Dictionary], delta: float) -> void:
	var write_index := 0
	for item: Dictionary in items:
		item["time"] = float(item["time"]) + delta
		if float(item["time"]) < float(item["life"]):
			items[write_index] = item
			write_index += 1
	items.resize(write_index)


func _push(items: Array[Dictionary], limit: int, item: Dictionary) -> void:
	if items.size() >= limit:
		items.pop_front()
	items.append(item)


func _add_shape(style: String, center: Vector2, radius: float, life: float, color: Color) -> void:
	_push(_shapes, MAX_SHAPES, {"style": style, "center": center, "radius": radius, "time": 0.0, "life": life, "color": color})


## 두 점 사이를 BOLT_STEP 마다 옆으로 튀게 꺾은 점들 (정수 위치 — 픽셀 번개)
func _zigzag(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(2, int(from_position.distance_to(to_position) / BOLT_STEP))
	var side := (to_position - from_position).orthogonal().normalized()
	points.append(from_position.round())
	for index: int in range(1, steps):
		var along := from_position.lerp(to_position, float(index) / steps)
		points.append((along + side * randf_range(-BOLT_JAG, BOLT_JAG)).round())
	points.append(to_position.round())
	return points


func _draw() -> void:
	for weapon: Weapon in _context.weapon_rack.weapons:
		weapon.draw_glow_on(self)   # 무기가 늘 띄워 두는 빛나는 것 (소독약 안개·불꽃 심지)
	for shape: Dictionary in _shapes:
		_draw_shape(shape)
	for beam_item: Dictionary in _beams:
		_draw_beam(beam_item)
	for bolt: Dictionary in _bolts:
		_draw_bolt(bolt)
	_particles.draw_on(self)


func _draw_bolt(bolt: Dictionary) -> void:
	var time := float(bolt["time"])
	if int(time * 40.0) % 3 == 2:
		return   # 번쩍번쩍 깜빡이게
	var fade := 1.0 - time / float(bolt["life"])
	var points: PackedVector2Array = bolt["points"]
	draw_polyline(points, Color(bolt["glow"], 0.75 * fade), 3.0)
	draw_polyline(points, Color(WHITE, 0.5 + 0.5 * fade), 1.0)


func _draw_beam(item: Dictionary) -> void:
	var progress := float(item["time"]) / float(item["life"])
	var from_position := Vector2(item["from"]).round()
	var to_position := Vector2(item["to"]).round()
	var width := maxf(1.0, float(item["width"]) * (1.0 - progress * 0.6))
	var is_evolved := bool(item["is_evolved"])
	if is_evolved:
		draw_line(from_position, to_position, Color(GOLD, 0.6 * (1.0 - progress)), width + 2.0)
	if item["look"] == "water":
		draw_line(from_position, to_position, Color(WATER_DEEP, 0.85 * (1.0 - progress)), width)
		draw_line(from_position, to_position, Color(WATER_LIGHT, 1.0 - progress), maxf(1.0, width * 0.4))
		return
	draw_line(from_position, to_position, Color(TAPE_COLOR, 1.0 - progress * 0.5), width)
	var direction := (to_position - from_position).normalized()
	var length := from_position.distance_to(to_position)
	for step: int in range(0, int(length), 4):   # 테이프 줄무늬
		draw_rect(Rect2((from_position + direction * step).round(), Vector2.ONE), Color(TAPE_STRIPE, 1.0 - progress * 0.5))


func _draw_shape(shape: Dictionary) -> void:
	var progress := float(shape["time"]) / float(shape["life"])
	var center: Vector2 = shape["center"]
	var radius := float(shape["radius"])
	var color: Color = shape["color"]
	match String(shape["style"]):
		"ring":
			_draw_dotted_ring(center, radius * (0.3 + 0.7 * progress), Color(color, 1.0 - progress), 2.0)
		"shockwave":
			_draw_dotted_ring(center, radius * progress, Color(color, 1.0 - progress), 2.0)
			_draw_dotted_ring(center, radius * progress * 0.72, Color(color, 0.6 * (1.0 - progress)), 1.0)
		"fire_ring":
			_draw_dotted_ring(center, radius * (0.4 + 0.6 * progress), Color(FIRE_COLORS[0], 1.0 - progress), 3.0)
			_draw_dotted_ring(center, radius * (0.3 + 0.6 * progress), Color(FIRE_COLORS[2], 0.8 * (1.0 - progress)), 2.0)
		"electric":
			_draw_electric_ring(center, radius, color, progress)
		"explosion":
			_draw_explosion(center, radius, color, progress)
		"warning":
			_draw_warning(center, radius, color, shape)
		"flash":
			var view_size := _context.camera.view_size()
			var view := Rect2(_context.camera.global_position - view_size * 0.5, view_size).grow(8.0)
			draw_rect(view, Color(color, color.a * (1.0 - progress)))


## 매끈한 원 대신 점을 찍어 픽셀 느낌으로 (06 AI 티 안 나게)
func _draw_dotted_ring(center: Vector2, radius: float, color: Color, dot_size: float) -> void:
	var dots := maxi(12, int(radius * 1.2))
	for index: int in range(dots):
		var point := center + Vector2.from_angle(TAU * index / dots) * radius
		draw_rect(Rect2(point.round(), Vector2.ONE * dot_size), color)


## 반경이 들쭉날쭉한 고리를 매번 새로 흔들어 그린다 (지직거림)
func _draw_electric_ring(center: Vector2, radius: float, color: Color, progress: float) -> void:
	var segments := maxi(16, int(radius * 0.8))
	var ring_radius := radius * (0.85 + 0.15 * progress)
	var previous := center + Vector2(ring_radius, 0.0)
	for index: int in range(1, segments + 1):
		var jitter := randf_range(-BOLT_JAG, BOLT_JAG)
		var point := (center + Vector2.from_angle(TAU * index / segments) * (ring_radius + jitter)).round()
		draw_line(previous, point, Color(color, 0.8 * (1.0 - progress)), 3.0)
		draw_line(previous, point, Color(WHITE, 1.0 - progress), 1.0)
		previous = point


func _draw_explosion(center: Vector2, radius: float, color: Color, progress: float) -> void:
	var fill_radius := radius * (0.35 + 0.65 * minf(1.0, progress * 2.5))
	var fill_color := WHITE
	if progress > 0.4:
		fill_color = FIRE_COLORS[2]
	elif progress > 0.15:
		fill_color = FIRE_COLORS[0]
	draw_circle(center.round(), fill_radius, Color(fill_color, 0.85 * (1.0 - progress)))
	_draw_dotted_ring(center, radius * (0.6 + 0.4 * progress), Color(color, 1.0 - progress), 2.0)


func _draw_warning(center: Vector2, radius: float, color: Color, shape: Dictionary) -> void:
	var time := float(shape["time"])
	var progress := time / float(shape["life"])
	if int(time * 10.0) % 2 == 0:
		_draw_dotted_ring(center, radius, color, 1.0)
	_draw_dotted_ring(center, radius * (1.0 - progress), Color(color, 0.6), 1.0)
	draw_rect(Rect2(center.round() - Vector2(1, 0), Vector2(3, 1)), color)
	draw_rect(Rect2(center.round() - Vector2(0, 1), Vector2(1, 3)), color)
