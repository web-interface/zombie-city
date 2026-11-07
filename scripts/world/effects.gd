## [파일] scripts/world/effects.gd
## [하는 일] 눈에 보이기만 하는 효과를 한 노드에서 한 번에 그린다: 피해 숫자(치명타는 크게·노랗게), 체액·불꽃 튀기, 퍼지는 고리, 선(보스 돌진 예고·저격), 근접 휘두르기 궤적, 총구 불꽃. 깜빡이는 선(보스 돌진·떼 돌진 예고 = 적 경고)은 맨 위 적 층에 그린다. 설정 '피해 숫자'를 끄면 숫자를 안 띄운다. 게임 규칙에는 영향이 없다.
## [쓰는 곳] scenes/run.tscn 의 World/Effects. 좀비 무리·무기·스킬·보스 담당이 RunContext.effects 로 부른다.
## [근거 문서] 15 §7-2 그리는 순서·§7-4 설정, 02 §12 손맛, 06 손맛 목록·AI 티(빛도 픽셀 단계로)
class_name Effects
extends Node2D

const NUMBER_RISE_SPEED := 18.0
const NUMBER_SECONDS := 0.55
const NUMBER_FONT_SIZE := 10

var _numbers: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _lines: Array[Dictionary] = []
var _arcs: Array[Dictionary] = []
var _max_numbers: int = 40
var _font: Font
var _warning_canvas: Node2D   # 적 경고 선 (밤 어둠·안개·내 효과 위)
var _is_numbers_on: bool = true


func _ready() -> void:
	_font = load("res://fonts/Galmuri9.ttf")
	z_index = 20
	var warning_layer := CanvasLayer.new()
	warning_layer.layer = HazardOverlay.ENEMY_LAYER
	warning_layer.follow_viewport_enabled = true
	add_child(warning_layer)
	_warning_canvas = Node2D.new()
	warning_layer.add_child(_warning_canvas)
	_warning_canvas.draw.connect(_draw_warning_lines)
	SaveData.changed.connect(func() -> void: _is_numbers_on = SaveData.is_damage_numbers_on())
	_is_numbers_on = SaveData.is_damage_numbers_on()


func setup(max_damage_numbers: int) -> void:
	_max_numbers = max_damage_numbers


func show_damage_number(at_position: Vector2, amount: float, is_crit: bool) -> void:
	if not _is_numbers_on:
		return
	if _numbers.size() >= _max_numbers:
		_numbers.pop_front()
	var jitter := Vector2(randf_range(-3.0, 3.0), 0.0)
	_numbers.append({"position": at_position + Vector2(0, -10) + jitter, "text": str(maxi(1, roundi(amount))), "time": 0.0, "is_crit": is_crit})


## 회복하면 초록 '+숫자' (회복 효과가 눈에 보이게)
func show_heal_number(at_position: Vector2, amount: float) -> void:
	if amount < 1.0:
		return
	if _numbers.size() >= _max_numbers:
		_numbers.pop_front()
	_numbers.append({"position": at_position + Vector2(0, -14), "text": "+%d" % roundi(amount), "time": 0.0, "is_crit": false, "is_heal": true})


func burst(at_position: Vector2, color: Color, count: int, speed: float = 40.0) -> void:
	for index: int in range(count):
		var direction := Vector2.from_angle(randf() * TAU)
		_particles.append({"position": at_position, "velocity": direction * randf_range(speed * 0.4, speed), "time": 0.0, "life": randf_range(0.25, 0.5), "color": color})


func ring(center: Vector2, radius: float, color: Color, seconds: float) -> void:
	_rings.append({"center": center, "radius": radius, "color": color, "time": 0.0, "life": seconds})


func line(from_position: Vector2, to_position: Vector2, color: Color, width: float, seconds: float, is_blinking: bool = false) -> void:
	_lines.append({"from": from_position, "to": to_position, "color": color, "width": width, "time": 0.0, "life": seconds, "is_blinking": is_blinking})


func swing_arc(center: Vector2, direction: Vector2, radius: float, color: Color) -> void:
	_arcs.append({"center": center, "angle": direction.angle(), "radius": radius, "color": color, "time": 0.0, "life": 0.12})


func muzzle_flash(at_position: Vector2, direction: Vector2) -> void:
	burst(at_position + direction * 4.0, Color("ffe066"), 2, 25.0)


func _process(delta: float) -> void:
	_age(_numbers, delta, NUMBER_SECONDS)
	_age(_particles, delta, -1.0)
	_age(_rings, delta, -1.0)
	_age(_lines, delta, -1.0)
	_age(_arcs, delta, -1.0)
	for particle: Dictionary in _particles:
		particle["position"] += particle["velocity"] * delta
		particle["velocity"] *= 0.9
	queue_redraw()
	_warning_canvas.queue_redraw()


func _age(items: Array[Dictionary], delta: float, fixed_life: float) -> void:
	for item: Dictionary in items:
		item["time"] = float(item["time"]) + delta
	items.assign(items.filter(func(item: Dictionary) -> bool:
		return float(item["time"]) < (fixed_life if fixed_life > 0.0 else float(item["life"]))))


func _draw() -> void:
	for particle: Dictionary in _particles:
		var fade := 1.0 - float(particle["time"]) / float(particle["life"])
		draw_rect(Rect2(Vector2(particle["position"]).round(), Vector2.ONE), Color(particle["color"], fade))
	for ring_item: Dictionary in _rings:
		_draw_ring(ring_item)
	for line_item: Dictionary in _lines:
		if not bool(line_item["is_blinking"]):
			_draw_line_item(self, line_item)
	for arc_item: Dictionary in _arcs:
		var progress := float(arc_item["time"]) / float(arc_item["life"])
		var start := float(arc_item["angle"]) - PI * 0.5
		draw_arc(arc_item["center"], float(arc_item["radius"]), start, start + PI * progress, 10, Color(arc_item["color"], 1.0 - progress * 0.6), 2.0)
	for number: Dictionary in _numbers:
		_draw_number(number)


func _draw_ring(ring_item: Dictionary) -> void:
	var progress := float(ring_item["time"]) / float(ring_item["life"])
	var radius := float(ring_item["radius"]) * (0.3 + 0.7 * progress)
	var color: Color = ring_item["color"]
	# 매끈한 원 대신 점을 찍어 픽셀 느낌으로 (06 AI 티 안 나게)
	var dots := maxi(12, int(radius * 1.2))
	for index: int in range(dots):
		var point := Vector2(ring_item["center"]) + Vector2.from_angle(TAU * index / dots) * radius
		draw_rect(Rect2(point.round(), Vector2.ONE * 2.0), Color(color, 1.0 - progress))


## 깜빡이는 선은 보스·떼 돌진 예고뿐이라 적 층에 (문서 15 §7-2 — 적 예고는 맨 위)
func _draw_warning_lines() -> void:
	for line_item: Dictionary in _lines:
		if bool(line_item["is_blinking"]):
			_draw_line_item(_warning_canvas, line_item)


func _draw_line_item(canvas: CanvasItem, line_item: Dictionary) -> void:
	if bool(line_item["is_blinking"]) and int(float(line_item["time"]) * 12.0) % 2 == 1:
		return
	var fade := 1.0 - float(line_item["time"]) / float(line_item["life"]) * 0.5
	canvas.draw_line(line_item["from"], line_item["to"], Color(line_item["color"], fade), float(line_item["width"]))


func _draw_number(number: Dictionary) -> void:
	var age := float(number["time"])
	var draw_position := Vector2(number["position"]) + Vector2(0, -NUMBER_RISE_SPEED * age)
	var is_crit := bool(number["is_crit"])
	var color := Color("ffd166") if is_crit else Color.WHITE
	if bool(number.get("is_heal", false)):
		color = Color("8ff59a")
	var size := NUMBER_FONT_SIZE + (3 if is_crit else 0)
	var fade := 1.0 - maxf(0.0, age - NUMBER_SECONDS * 0.6) / (NUMBER_SECONDS * 0.4)
	draw_string_outline(_font, draw_position.round(), number["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, size, 2, Color(0.06, 0.06, 0.09, fade))
	draw_string(_font, draw_position.round(), number["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(color, fade))
