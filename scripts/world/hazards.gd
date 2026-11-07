## [파일] scripts/world/hazards.gd
## [하는 일] 생존자를 노리는 것들을 한곳에서 움직인다: 침 뱉는 좀비의 침(떨어진 곳에 산성 웅덩이), 보스가 던지는 식칼·철근, 산성 웅덩이(안에 있으면 초당 피해), 큰 공격 전의 빨간 예고 원·예고 선. 웅덩이 채움·빗금(주황빨강·자홍)은 좀비 발밑인 여기서 그리고, 테두리·예고·날아오는 것은 맨 위 적 층(HazardOverlay)이 한 번 더 그린다. 생존자가 웅덩이 안에 있는지 알려 준다.
## [쓰는 곳] scenes/run.tscn 의 World/Hazards. run.gd 가 update() 를 부르고, zombie_abilities.gd·보스 기술(boss_moves_*.gd)이 spit()·shoot()·warn()·warn_line() 을 부른다. 밤이 바뀌면 clear(). HitFeedback 이 zone_appeared·is_survivor_in_zone 을 본다.
## [근거 문서] 15 §7 보이는 규칙(색 언어·그리는 순서·장판 안 알림), 14 §1-2·§1-3 (예고 → 공격), 12 §6 공정함
class_name Hazards
extends Node2D

## 적 장판이 새로 깔렸다 (첫 판 알림 — HitFeedback)
signal zone_appeared

const SPIT_HIT_DISTANCE := 5.0
const SPIT_DIRECT_DAMAGE := 8.0
const MAX_PUDDLES := 40
const THROWN_HIT_DISTANCE := 5.0
const THROWN_LIFE_SECONDS := 3.0
## 적 장판 채움: 주황빨강 바탕 + 자홍 빗금 (문서 15 §7-1 — 내 효과에는 이 색을 안 씀)
const ZONE_FILL_COLOR := Color("ff4a1c")
const ZONE_HATCH_COLOR := Color("ff2fa0")
const ZONE_FILL_ALPHA := 0.24
const ZONE_HATCH_ALPHA := 0.6
const HATCH_GAP := 4
const BLAST_COLOR := Color("ff5a2a")

## 생존자가 지금 적 웅덩이 안에 있나 (가장자리 빨강·발밑 고리·지글 소리)
var is_survivor_in_zone: bool = false
var _spits: Array[Dictionary] = []
var _puddles: Array[Dictionary] = []
var _warnings: Array[Dictionary] = []
var _thrown: Array[Dictionary] = []          # 보스가 던진 식칼·철근
var _line_warnings: Array[Dictionary] = []   # 땅 갈라짐·토하기 예고 선
var _context: RunContext
var _overlay: HazardOverlay


func setup(context: RunContext) -> void:
	_context = context
	z_index = -1   # 채움·빗금은 좀비 발밑 (테두리는 맨 위 적 층이 다시 — 문서 15 §7-2)
	_overlay = HazardOverlay.new()
	add_child(_overlay)
	_overlay.setup(context, {"puddles": _puddles, "warnings": _warnings, "line_warnings": _line_warnings, "thrown": _thrown, "spits": _spits})


## 침: from 에서 target 으로 천천히 날아가 떨어진 곳에 웅덩이. puddle = {radius, seconds, damage_per_second, source}
func spit(from_position: Vector2, target: Vector2, speed: float, puddle: Dictionary) -> void:
	var travel := target - from_position
	_spits.append({"position": from_position, "velocity": travel.normalized() * speed, "time_left": travel.length() / maxf(speed, 1.0), "puddle": puddle})
	_context.play_sound("spitter_spit")


func add_puddle(center: Vector2, radius: float, seconds: float, damage_per_second: float, source: String) -> void:
	if _puddles.size() >= MAX_PUDDLES:
		_puddles.pop_front()
	_puddles.append({"center": center, "radius": radius, "time_left": seconds, "damage_per_second": damage_per_second, "source": source, "has_survivor": false})
	_context.play_sound("acid_sizzle")
	zone_appeared.emit()


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


## 고수 봇이 옆으로 비킬 것: 날아오는 침·식칼·철근 [{"position", "velocity", …}]
func incoming_shots() -> Array[Dictionary]:
	var shots: Array[Dictionary] = _spits.duplicate()
	shots.append_array(_thrown)
	return shots


func is_warning_active() -> bool:
	return not _warnings.is_empty() or not _line_warnings.is_empty()


func clear() -> void:
	_spits.clear()
	_puddles.clear()
	_warnings.clear()
	_thrown.clear()
	_line_warnings.clear()
	is_survivor_in_zone = false
	queue_redraw()


func update(delta: float) -> void:
	_overlay.advance(delta)
	_move_spits(delta)
	_hurt_survivor_in_puddles(delta)
	_count_down_warnings(delta)
	_move_thrown(delta)
	_count_down_line_warnings(delta)
	queue_redraw()
	_overlay.queue_redraw()


func _move_spits(delta: float) -> void:
	var survivor := _context.survivor
	for spit_item: Dictionary in _spits:
		spit_item["position"] = Vector2(spit_item["position"]) + Vector2(spit_item["velocity"]) * delta
		spit_item["time_left"] = float(spit_item["time_left"]) - delta
		var hit_survivor := Vector2(spit_item["position"]).distance_to(survivor.position) < SPIT_HIT_DISTANCE
		if hit_survivor:
			survivor.take_damage(SPIT_DIRECT_DAMAGE, String(spit_item["puddle"]["source"]), spit_item["position"])
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
			survivor.take_damage(float(item["damage"]), String(item["source"]), item["position"])
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
	_context.effects.line(from_position, to_position, BLAST_COLOR, float(line["width"]) * 0.5, 0.25)
	_context.shake("boss_charge")
	var closest := Geometry2D.get_closest_point_to_segment(_context.survivor.position, from_position, to_position)
	if closest.distance_to(_context.survivor.position) <= float(line["width"]) * 0.5 + 2.0:
		_context.survivor.take_damage(float(effect["damage"]), String(effect["source"]), closest)


func _hurt_survivor_in_puddles(delta: float) -> void:
	var survivor := _context.survivor
	is_survivor_in_zone = false
	for puddle: Dictionary in _puddles:
		puddle["time_left"] = float(puddle["time_left"]) - delta
		puddle["has_survivor"] = survivor.position.distance_to(puddle["center"]) <= float(puddle["radius"])
		if bool(puddle["has_survivor"]):
			is_survivor_in_zone = true
			survivor.take_damage(float(puddle["damage_per_second"]) * delta, String(puddle["source"]), puddle["center"])
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
			_context.effects.ring(center, radius, BLAST_COLOR, 0.3)
			_context.shake("boss_charge")
		"explosion":
			_context.play_sound("bloater_pop")
			_context.effects.burst(center, ZONE_HATCH_COLOR, 14, 60.0)
			_context.effects.ring(center, radius, BLAST_COLOR, 0.3)
			_context.shake("explosion")
			_damage_zombies_around(center, radius, float(effect.get("zombie_damage", 0.0)))
	if is_inside:
		survivor.take_damage(float(effect["damage"]), String(effect["source"]), center)
		var away := (survivor.position - center).normalized()
		survivor.position += away * float(effect.get("push", 0.0))


func _damage_zombies_around(center: Vector2, radius: float, amount: float) -> void:
	if amount <= 0.0:
		return
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		_context.horde.hit(zombie, amount, {"knockback_from": center, "knockback": 6.0, "source": "explosion"})


## 웅덩이 채움(옅은 주황빨강) + 자홍 빗금 — 좀비 발밑. 테두리·거품은 HazardOverlay 가 맨 위에 한 번 더.
func _draw() -> void:
	for puddle: Dictionary in _puddles:
		var center := Vector2(puddle["center"]).round()
		var radius := float(puddle["radius"])
		var fade := clampf(float(puddle["time_left"]) * 1.5, 0.0, 1.0)
		draw_circle(center, radius, Color(ZONE_FILL_COLOR, ZONE_FILL_ALPHA * fade))
		HazardOverlay.draw_hatch(self, center, radius, HATCH_GAP, Color(ZONE_HATCH_COLOR, ZONE_HATCH_ALPHA * fade))
