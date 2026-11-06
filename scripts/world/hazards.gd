## [파일] scripts/world/hazards.gd
## [하는 일] 생존자를 노리는 것들을 한곳에서 움직이고 그린다: 침 뱉는 좀비의 초록 침(느리게 날아가 떨어진 곳에 산성 웅덩이), 보스가 던지는 식칼·철근(보이게 날아옴), 산성 웅덩이(안에 있으면 초당 피해), 큰 공격 전의 빨간 예고 원·예고 선(차오른 뒤 해머·폭발·산성 비·땅 갈라짐·토하기가 터짐). 모든 큰 공격은 먼저 보여서 피할 수 있게 한다.
## [쓰는 곳] scenes/run.tscn 의 World/Hazards. run.gd 가 update() 를 부르고, zombie_abilities.gd·보스 기술(boss_moves_*.gd)이 spit()·shoot()·warn()·warn_line() 을 부른다. 밤이 바뀌면 clear().
## [근거 문서] 14 §1-2·§1-3 (예고 → 공격), 12 §6 공정함(보이지 않는 공격 없음)
class_name Hazards
extends Node2D

const SPIT_HIT_DISTANCE := 5.0
const SPIT_DIRECT_DAMAGE := 8.0
const ACID_COLORS: Array[Color] = [Color("8fd14f"), Color("b6e86a"), Color("5fa83a")]
const WARNING_COLOR := Color("ff3b3b")
const MAX_PUDDLES := 40
const THROWN_HIT_DISTANCE := 5.0
const THROWN_LIFE_SECONDS := 3.0
const THROWN_LOOKS := {
	"cleaver": {"color": Color("d6dbe3"), "edge": Color("8a2f2f"), "size": Vector2(3, 3)},
	"rebar": {"color": Color("b0643a"), "edge": Color("5c3320"), "size": Vector2(4, 1)},
}

var _spits: Array[Dictionary] = []
var _puddles: Array[Dictionary] = []
var _warnings: Array[Dictionary] = []
var _thrown: Array[Dictionary] = []          # 보스가 던진 식칼·철근
var _line_warnings: Array[Dictionary] = []   # 땅 갈라짐·토하기 예고 선
var _context: RunContext
var _time: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	z_index = -1   # 좀비 발밑에 깔리게 (예고 원은 밝은 빨강이라 묻히지 않음)


## 침: from 에서 target 으로 천천히 날아가 떨어진 곳에 웅덩이. puddle = {radius, seconds, damage_per_second, source}
func spit(from_position: Vector2, target: Vector2, speed: float, puddle: Dictionary) -> void:
	var travel := target - from_position
	_spits.append({"position": from_position, "velocity": travel.normalized() * speed, "time_left": travel.length() / maxf(speed, 1.0), "puddle": puddle})
	_context.play_sound("spitter_spit")


func add_puddle(center: Vector2, radius: float, seconds: float, damage_per_second: float, source: String) -> void:
	if _puddles.size() >= MAX_PUDDLES:
		_puddles.pop_front()
	_puddles.append({"center": center, "radius": radius, "time_left": seconds, "damage_per_second": damage_per_second, "source": source})
	_context.play_sound("acid_sizzle")


## 빨간 예고 원: seconds 동안 차오른 뒤 effect 가 터진다.
## effect = {"type": "slam"|"explosion"|"acid", "damage", "push", "zombie_damage", "puddle": {...}, "source"}
func warn(center: Vector2, radius: float, seconds: float, effect: Dictionary) -> void:
	_warnings.append({"center": center, "radius": radius, "time_left": seconds, "total": seconds, "effect": effect})


## 보스가 던지는 것: 똑바로 날아가다 생존자에 닿으면 피해. look = "cleaver"(식칼) · "rebar"(철근)
func shoot(from_position: Vector2, velocity: Vector2, damage: float, source: String, look: String) -> void:
	_thrown.append({"position": from_position, "velocity": velocity, "damage": damage, "source": source, "look": look, "time_left": THROWN_LIFE_SECONDS})


## 빨간 예고 선: seconds 뒤 선을 따라 터진다.
## effect = {"type": "line_damage", "damage", "source"} 또는 {"type": "line_puddles", "count", "puddle": {radius, seconds, damage_per_second}, "source"}
func warn_line(from_position: Vector2, to_position: Vector2, width: float, seconds: float, effect: Dictionary) -> void:
	_line_warnings.append({"from": from_position, "to": to_position, "width": width, "time_left": seconds, "total": seconds, "effect": effect})


## 자동 플레이 봇이 피할 곳: [{"center", "radius"}] — 웅덩이와 예고 원
func danger_zones() -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	for puddle: Dictionary in _puddles:
		zones.append({"center": puddle["center"], "radius": puddle["radius"]})
	for warning: Dictionary in _warnings:
		zones.append({"center": warning["center"], "radius": warning["radius"]})
	for line: Dictionary in _line_warnings:
		for step: int in range(5):   # 선은 원 다섯 개로 나눠 알려 줌
			zones.append({"center": Vector2(line["from"]).lerp(line["to"], (step + 0.5) / 5.0), "radius": float(line["width"])})
	return zones


func is_warning_active() -> bool:
	return not _warnings.is_empty() or not _line_warnings.is_empty()


func clear() -> void:
	_spits.clear()
	_puddles.clear()
	_warnings.clear()
	_thrown.clear()
	_line_warnings.clear()
	queue_redraw()


func update(delta: float) -> void:
	_time += delta
	_move_spits(delta)
	_hurt_survivor_in_puddles(delta)
	_count_down_warnings(delta)
	_move_thrown(delta)
	_count_down_line_warnings(delta)
	queue_redraw()


func _move_spits(delta: float) -> void:
	var survivor := _context.survivor
	for spit_item: Dictionary in _spits:
		spit_item["position"] = Vector2(spit_item["position"]) + Vector2(spit_item["velocity"]) * delta
		spit_item["time_left"] = float(spit_item["time_left"]) - delta
		var hit_survivor := Vector2(spit_item["position"]).distance_to(survivor.position) < SPIT_HIT_DISTANCE
		if hit_survivor:
			survivor.take_damage(SPIT_DIRECT_DAMAGE, String(spit_item["puddle"]["source"]))
		if hit_survivor or float(spit_item["time_left"]) <= 0.0:
			var puddle: Dictionary = spit_item["puddle"]
			add_puddle(spit_item["position"], float(puddle["radius"]), float(puddle["seconds"]), float(puddle["damage_per_second"]), String(puddle["source"]))
			spit_item["time_left"] = -1.0
	_spits.assign(_spits.filter(func(spit_item: Dictionary) -> bool: return float(spit_item["time_left"]) > 0.0))


func _move_thrown(delta: float) -> void:
	var survivor := _context.survivor
	for item: Dictionary in _thrown:
		item["position"] = Vector2(item["position"]) + Vector2(item["velocity"]) * delta
		item["time_left"] = float(item["time_left"]) - delta
		if Vector2(item["position"]).distance_to(survivor.position) < THROWN_HIT_DISTANCE:
			survivor.take_damage(float(item["damage"]), String(item["source"]))
			item["time_left"] = -1.0
	_thrown.assign(_thrown.filter(func(item: Dictionary) -> bool: return float(item["time_left"]) > 0.0))


func _count_down_line_warnings(delta: float) -> void:
	var finished: Array[Dictionary] = []
	for line: Dictionary in _line_warnings:
		line["time_left"] = float(line["time_left"]) - delta
		if float(line["time_left"]) <= 0.0:
			finished.append(line)
	if finished.is_empty():
		return
	_line_warnings.assign(_line_warnings.filter(func(line: Dictionary) -> bool: return float(line["time_left"]) > 0.0))
	for line: Dictionary in finished:
		_set_off_line(line)


func _set_off_line(line: Dictionary) -> void:
	var from_position: Vector2 = line["from"]
	var to_position: Vector2 = line["to"]
	var effect: Dictionary = line["effect"]
	if effect["type"] == "line_puddles":
		var count := int(effect["count"])
		var puddle: Dictionary = effect["puddle"]
		for index: int in range(count):
			var spot := from_position.lerp(to_position, (index + 1.0) / count)
			add_puddle(spot, float(puddle["radius"]), float(puddle["seconds"]), float(puddle["damage_per_second"]), String(effect["source"]))
		return
	_context.effects.line(from_position, to_position, Color("ffd25a"), float(line["width"]) * 0.5, 0.25)
	_context.shake("boss_charge")
	var closest := Geometry2D.get_closest_point_to_segment(_context.survivor.position, from_position, to_position)
	if closest.distance_to(_context.survivor.position) <= float(line["width"]) * 0.5 + 2.0:
		_context.survivor.take_damage(float(effect["damage"]), String(effect["source"]))


func _hurt_survivor_in_puddles(delta: float) -> void:
	var survivor := _context.survivor
	for puddle: Dictionary in _puddles:
		puddle["time_left"] = float(puddle["time_left"]) - delta
		if survivor.position.distance_to(puddle["center"]) <= float(puddle["radius"]):
			survivor.take_damage(float(puddle["damage_per_second"]) * delta, String(puddle["source"]))
	_puddles.assign(_puddles.filter(func(puddle: Dictionary) -> bool: return float(puddle["time_left"]) > 0.0))


func _count_down_warnings(delta: float) -> void:
	var finished: Array[Dictionary] = []
	for warning: Dictionary in _warnings:
		warning["time_left"] = float(warning["time_left"]) - delta
		if float(warning["time_left"]) <= 0.0:
			finished.append(warning)
	if finished.is_empty():
		return
	_warnings.assign(_warnings.filter(func(warning: Dictionary) -> bool: return float(warning["time_left"]) > 0.0))
	for warning: Dictionary in finished:
		_set_off(warning["center"], float(warning["radius"]), warning["effect"])


## 예고가 끝난 자리에서 공격이 터진다
func _set_off(center: Vector2, radius: float, effect: Dictionary) -> void:
	var survivor := _context.survivor
	var is_inside := survivor.position.distance_to(center) <= radius
	match String(effect["type"]):
		"acid":
			var puddle: Dictionary = effect["puddle"]
			add_puddle(center, radius, float(puddle["seconds"]), float(puddle["damage_per_second"]), String(effect["source"]))
			return
		"slam":
			_context.play_sound("demolisher_slam")
			_context.effects.ring(center, radius, Color("ffd25a"), 0.3)
			_context.shake("boss_charge")
		"explosion":
			_context.play_sound("bloater_pop")
			_context.effects.burst(center, Color("b6e86a"), 14, 60.0)
			_context.effects.ring(center, radius, Color("8fd14f"), 0.3)
			_context.shake("explosion")
			_damage_zombies_around(center, radius, float(effect.get("zombie_damage", 0.0)))
	if is_inside:
		survivor.take_damage(float(effect["damage"]), String(effect["source"]))
		var away := (survivor.position - center).normalized()
		survivor.position += away * float(effect.get("push", 0.0))


func _damage_zombies_around(center: Vector2, radius: float, amount: float) -> void:
	if amount <= 0.0:
		return
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		_context.horde.hit(zombie, amount, {"knockback_from": center, "knockback": 6.0, "source": "explosion"})


func _draw() -> void:
	for puddle: Dictionary in _puddles:
		_draw_puddle(puddle)
	for warning: Dictionary in _warnings:
		_draw_warning(warning)
	for line: Dictionary in _line_warnings:
		_draw_line_warning(line)
	for item: Dictionary in _thrown:
		_draw_thrown(item)
	for spit_item: Dictionary in _spits:
		var point := Vector2(spit_item["position"]).round()
		var trail := point - Vector2(spit_item["velocity"]).normalized() * 3.0
		draw_rect(Rect2(trail.round(), Vector2.ONE), Color(ACID_COLORS[1], 0.5))
		draw_rect(Rect2(point - Vector2(1, 1), Vector2(3, 3)), ACID_COLORS[0])


## 웅덩이: 초록 점이 부글부글 (자리마다 같은 무늬가 아니게 시간으로 흔듦)
func _draw_puddle(puddle: Dictionary) -> void:
	var radius := float(puddle["radius"])
	var fade := clampf(float(puddle["time_left"]) * 1.5, 0.0, 1.0)
	draw_circle(puddle["center"], radius, Color(ACID_COLORS[2], 0.22 * fade))
	var dots := int(radius * 1.2)
	for index: int in range(dots):
		var angle := float(index) * 2.39996 + _time * 0.7
		var distance := sqrt(fposmod(float(index) * 0.618, 1.0)) * radius
		var point := Vector2(puddle["center"]) + Vector2.from_angle(angle) * distance
		draw_rect(Rect2(point.round(), Vector2.ONE), Color(ACID_COLORS[index % 3], 0.8 * fade))


## 예고 원: 테두리가 깜빡이고 안쪽이 차오른다 — 다 차면 터진다
func _draw_warning(warning: Dictionary) -> void:
	var progress := 1.0 - float(warning["time_left"]) / maxf(float(warning["total"]), 0.01)
	var radius := float(warning["radius"])
	var blink := 0.55 + 0.45 * absf(sin(_time * 14.0))
	draw_arc(warning["center"], radius, 0.0, TAU, 32, Color(WARNING_COLOR, blink), 1.0)
	draw_circle(warning["center"], radius * progress, Color(WARNING_COLOR, 0.28))


## 예고 선: 빨간 띠가 깜빡이며 앞에서부터 차오른다
func _draw_line_warning(line: Dictionary) -> void:
	var from_position: Vector2 = line["from"]
	var to_position: Vector2 = line["to"]
	var progress := 1.0 - float(line["time_left"]) / maxf(float(line["total"]), 0.01)
	var side := (to_position - from_position).normalized().orthogonal() * float(line["width"]) * 0.5
	var blink := 0.55 + 0.45 * absf(sin(_time * 14.0))
	var outline := PackedVector2Array([from_position + side, to_position + side, to_position - side, from_position - side, from_position + side])
	draw_polyline(outline, Color(WARNING_COLOR, blink), 1.0)
	var filled_end := from_position.lerp(to_position, progress)
	draw_colored_polygon(PackedVector2Array([from_position + side, filled_end + side, filled_end - side, from_position - side]), Color(WARNING_COLOR, 0.25))


## 식칼은 빙글빙글(테두리 위치가 돌아감), 철근은 날아가는 쪽으로 누운 막대
func _draw_thrown(item: Dictionary) -> void:
	var look: Dictionary = THROWN_LOOKS.get(item["look"], THROWN_LOOKS["cleaver"])
	var point := Vector2(item["position"]).round()
	var size: Vector2 = look["size"]
	if item["look"] == "rebar" and absf(Vector2(item["velocity"]).y) > absf(Vector2(item["velocity"]).x):
		size = Vector2(size.y, size.x)
	draw_rect(Rect2(point - size * 0.5, size), look["color"])
	var spin := Vector2.from_angle(_time * 20.0).round()
	draw_rect(Rect2(point + spin, Vector2.ONE), look["edge"])
