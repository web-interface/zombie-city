## [파일] scripts/world/area_effects.gd
## [하는 일] 바닥에 남아 시간 동안 피해를 주는 장판: 불 장판(화염 전문가 전직)·독 구름(역학조사관 전직). 0.25초마다 안에 있는 좀비에게 피해를 준다. 내 것이라 파란 불·푸른 구름으로, 무기 장판 그룹(WeaponZones.group)에 그려 겹쳐도 진해지지 않고 적 웅덩이보다 아래에 깔린다.
## [쓰는 곳] scenes/run.tscn 의 World/AreaEffects. 스킬(scripts/skills/skill_runner.gd)이 add_fire_zone()·add_poison_cloud() 를 부른다.
## [근거 문서] 15 §7-1 색 언어·§7-2 그리는 순서, 03 §1-2 전직 (화염 전문가·역학조사관), 02 §12 손맛
class_name AreaEffects
extends Node2D

const DAMAGE_TICK_SECONDS := 0.25
const FIRE_COLORS: Array[Color] = [Color("ffffff"), Color("9fd8ff"), Color("5aa9ff")]
const POISON_COLORS: Array[Color] = [Color("dfe6ff"), Color("c4d2ff"), Color("9fb4ff")]

var _zones: Array[Dictionary] = []
var _context: RunContext
var _tick_timer: float = 0.0
var _canvas: Node2D


func setup(context: RunContext) -> void:
	_context = context
	_canvas = Node2D.new()
	context.weapon_rack.zones.group.add_child(_canvas)
	_canvas.draw.connect(_draw_zones)


func add_fire_zone(center: Vector2, radius: float, seconds: float, damage_per_second: float) -> void:
	_zones.append({"kind": "fire", "center": center, "radius": radius, "time_left": seconds, "damage_per_second": damage_per_second})


func add_poison_cloud(center: Vector2, radius: float, seconds: float, damage_per_second: float) -> void:
	_zones.append({"kind": "poison", "center": center, "radius": radius, "time_left": seconds, "damage_per_second": damage_per_second})


## 다음 밤으로 넘어갈 때 장판을 비운다
func clear() -> void:
	_zones.clear()
	_canvas.queue_redraw()


func update(delta: float) -> void:
	_tick_timer += delta
	var is_damage_tick := _tick_timer >= DAMAGE_TICK_SECONDS
	if is_damage_tick:
		_tick_timer = 0.0
	for zone: Dictionary in _zones:
		zone["time_left"] = float(zone["time_left"]) - delta
		if is_damage_tick:
			_damage_zombies_in(zone)
	_zones.assign(_zones.filter(func(zone: Dictionary) -> bool: return float(zone["time_left"]) > 0.0))
	_canvas.queue_redraw()


func _damage_zombies_in(zone: Dictionary) -> void:
	var tick_damage := float(zone["damage_per_second"]) * DAMAGE_TICK_SECONDS
	for zombie: Zombie in _context.horde.in_radius(zone["center"], float(zone["radius"])):
		if zone["kind"] == "poison":
			zombie.apply_poison(float(zone["damage_per_second"]) * _context.survivor.stats.value("poison_damage_multiplier"), float(_context.status_rules["poison_cloud_apply_seconds"]))
		else:
			_context.horde.hit(zombie, tick_damage, {"source": "fire", "show_number": false})


func _draw_zones() -> void:
	for zone: Dictionary in _zones:
		var colors := FIRE_COLORS if zone["kind"] == "fire" else POISON_COLORS
		var radius := float(zone["radius"])
		var fade := clampf(float(zone["time_left"]) * 2.0, 0.0, 1.0)
		_canvas.draw_circle(Vector2(zone["center"]).round(), radius, Color(colors[2], 0.75 * fade))   # 그룹이 한 번에 옅게 하므로 안에서는 진하게
		var flame_count := int(radius * 1.5)
		for index: int in range(flame_count):
			var angle := randf() * TAU
			var distance := sqrt(randf()) * radius
			var point := Vector2(zone["center"]) + Vector2.from_angle(angle) * distance
			_canvas.draw_rect(Rect2(point.round(), Vector2(1, 2) if zone["kind"] == "fire" else Vector2.ONE * 2.0), Color(colors.pick_random(), fade))
