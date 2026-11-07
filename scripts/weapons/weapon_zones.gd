## [파일] scripts/weapons/weapon_zones.gd
## [하는 일] 무기가 바닥에 남기는 장판: 불(화염병·불도끼·백드래프트)·연기 구름(최루탄 — 느려짐, 진화하면 기절)·조명탄(불 + 빛 기둥, 그 자리를 밝혀 좀비가 약해짐)·빛(구장 조명 — 하얀 빛 기둥, 빛 안 좀비는 느리고 더 아픔), 그리고 곰 덫(BearTraps). 0.25초마다 안의 좀비에게 피해를 주고, 주황 장판 + 떠오르는 불씨 / 뭉게 구름으로 그린다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 자식으로 만들고 매 프레임 update() 를 부른다. 던지는 무기(lob_area_weapon.gd)·도끼 진화(melee_arc_weapon.gd)·히든 스킬이 add_zone()·add_trap() 을 부른다. 전직 스킬 장판은 따로 scripts/world/area_effects.gd.
## [근거 문서] 14 §2-2·§2-7 (불 = 주황 장판 + 불씨)·§3-1 (구장 조명·곰 덫), 03 §2 화염병·조명탄
class_name WeaponZones
extends Node2D

const DAMAGE_TICK_SECONDS := 0.25
const MAX_ZONES := 24                  # 장판이 이보다 많으면 가장 오래된 것부터 지운다 (성능)
const GROUND_LAYER := -1               # 좀비 발밑에 깔리게
const EMBERS_PER_SECOND := 10.0        # 장판 하나가 내는 불씨·연기 알갱이 수
const FLARE_LIGHT_RADIUS_RATIO := 1.5  # 조명탄 빛은 장판보다 넓게
const PUFF_COUNT := 5
const FLAME_ALPHA := 0.7               # 불꽃 점 — 좀비가 가려지지 않을 만큼만 (문서 13 가독성)
const FLAMES_PER_RADIUS := 0.9
const LIGHT_SPARKLE_RATIO := 0.3
const FIRE_FILL_ALPHA := 0.12          # 불바다처럼 여러 장판이 겹쳐도 좀비가 비쳐 보이게
const CLOUD_FILL_ALPHA := 0.07
const CLOUD_PUFF_ALPHA := 0.1
## 장판 피해는 소리·숫자 없이 (불과 같은 조용한 피해 — 매번 새 묶음을 만들지 않게 상수로)
const QUIET_ZONE_HIT := {"source": "fire", "show_number": false}
const LOOKS := {
	"fire": {"ground": Color("ff7a2a"), "flames": [Color("ffe08a"), Color("ff9a3c"), Color("ff5a2a")]},
	"flare": {"ground": Color("ff4d6d"), "flames": [Color("ffd0d8"), Color("ff7a90"), Color("ff4d6d")]},
	"gas": {"ground": Color("9fb39a"), "flames": [Color("c9d6c3"), Color("9fb39a"), Color("7d8f78")]},
	"light": {"ground": Color("fff2b0"), "flames": [Color("ffffff"), Color("fffbe0"), Color("ffe9a0")]},
}
## 빛 기둥이 서는 장판 종류 → 기둥 높이 (구장 조명은 더 높게)
const PILLAR_HEIGHTS := {"flare": 44.0, "light": 64.0}

var _zones: Array[Dictionary] = []
var _context: RunContext
var _visuals: WeaponVisuals
var _tick_timer: float = 0.0
var _time: float = 0.0
var _traps: BearTraps


func setup(context: RunContext, visuals: WeaponVisuals) -> void:
	_context = context
	_visuals = visuals
	z_as_relative = false
	z_index = GROUND_LAYER
	_traps = BearTraps.new(context, visuals)


## kind: "fire" · "gas" · "flare". stun_seconds 가 있으면 깔리는 순간 안의 좀비를 기절시킨다 (진압 작전).
func add_zone(kind: String, center: Vector2, radius: float, seconds: float, damage_per_second: float, slow_ratio: float = 1.0, stun_seconds: float = 0.0, is_evolved: bool = false) -> void:
	if _zones.size() >= MAX_ZONES:
		_zones.pop_front()
	_zones.append({"kind": kind, "center": center, "radius": radius, "time_left": seconds, "total": seconds,
		"damage_per_second": damage_per_second, "slow_ratio": slow_ratio, "is_evolved": is_evolved})
	if stun_seconds > 0.0:
		var boss_multiplier := float(_context.status_rules["boss_stun_multiplier"])
		for zombie: Zombie in _context.horde.in_radius(center, radius):
			zombie.stun(stun_seconds * (boss_multiplier if zombie.is_boss else 1.0))
	if kind == "flare":
		_context.lighting.add_temporary_light(center, radius * FLARE_LIGHT_RADIUS_RATIO, seconds)
	elif kind == "light":   # 구장 조명: 장판 자체가 빛 — 빛 안 좀비는 느리고 더 아프다 (빛과 어둠 규칙)
		_context.lighting.add_temporary_light(center, radius, seconds)


## 곰 덫 놓기 (밟으면 닫힘 — BearTraps)
func add_trap(center: Vector2, trigger_radius: float, seconds: float, damage: float, bind_seconds: float, blast_radius: float, trigger_sound: String, is_evolved: bool) -> void:
	_traps.add(center, trigger_radius, seconds, damage, bind_seconds, blast_radius, trigger_sound, is_evolved)


## 판이 새로 시작될 때(다음 밤 등) 장판을 비운다
func clear() -> void:
	_zones.clear()
	_traps.clear()


func update(delta: float) -> void:
	_time += delta
	_tick_timer += delta
	var is_damage_tick := _tick_timer >= DAMAGE_TICK_SECONDS
	if is_damage_tick:
		_tick_timer = 0.0
	var write_index := 0
	for zone: Dictionary in _zones:
		zone["time_left"] = float(zone["time_left"]) - delta
		if is_damage_tick:
			_damage_zombies_in(zone)
		_spawn_embers(zone, delta)
		if float(zone["time_left"]) > 0.0:
			_zones[write_index] = zone
			write_index += 1
	_zones.resize(write_index)
	_traps.update(delta)
	queue_redraw()


func _damage_zombies_in(zone: Dictionary) -> void:
	var tick_damage := float(zone["damage_per_second"]) * DAMAGE_TICK_SECONDS * _context.survivor.stats.value("damage_multiplier")
	var slow_ratio := float(zone["slow_ratio"])
	for zombie: Zombie in _context.horde.in_radius(zone["center"], float(zone["radius"])):
		if slow_ratio < 1.0:
			zombie.slow(slow_ratio, DAMAGE_TICK_SECONDS * 2.0)
		if tick_damage > 0.0:
			_context.horde.hit(zombie, tick_damage, QUIET_ZONE_HIT)


## 불은 떠오르는 불씨, 구름은 천천히 피어오르는 연기 (알갱이는 WeaponVisuals 고리 버퍼)
func _spawn_embers(zone: Dictionary, delta: float) -> void:
	if randf() > EMBERS_PER_SECOND * delta:
		return
	var radius := float(zone["radius"])
	var point := Vector2(zone["center"]) + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
	var flames: Array = LOOKS[zone["kind"]]["flames"]
	if zone["kind"] == "gas":
		_visuals.puff(point, flames.pick_random(), 1, 2.0)
	else:
		_visuals.add_particle(point, Vector2(randf_range(-4.0, 4.0), -18.0), randf_range(0.4, 0.8), flames.pick_random(), WeaponVisuals.RISE_GRAVITY)


func _draw() -> void:
	_traps.draw_on(self, _time)
	for zone: Dictionary in _zones:
		var fade := clampf(float(zone["time_left"]) * 2.0, 0.0, 1.0)
		if zone["kind"] == "gas":
			_draw_cloud(zone, fade)
		else:
			_draw_fire(zone, fade)


## 주황(조명탄은 분홍) 장판 + 일렁이는 불꽃 점 + 가장자리
func _draw_fire(zone: Dictionary, fade: float) -> void:
	var look: Dictionary = LOOKS[zone["kind"]]
	var center := Vector2(zone["center"]).round()
	var radius := float(zone["radius"])
	var flames: Array = look["flames"]
	var flicker := 0.85 + 0.15 * sin(_time * 14.0 + center.x)
	draw_circle(center, radius, Color(look["ground"], FIRE_FILL_ALPHA * fade))
	draw_circle(center, radius * 0.62, Color(flames[1], FIRE_FILL_ALPHA * fade * flicker))   # 가운데가 더 밝게 타오름
	var flame_ratio := LIGHT_SPARKLE_RATIO if zone["kind"] == "light" else 1.0   # 빛 장판은 반짝임만 조금 (하얀 점이 너무 많으면 좀비가 묻힘)
	for index: int in range(int(radius * FLAMES_PER_RADIUS * flame_ratio)):
		var point := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
		var flame_height := 3.0 if index % 5 == 0 else 2.0
		draw_rect(Rect2(point.round(), Vector2(1, flame_height)), Color(flames[index % flames.size()], FLAME_ALPHA * fade))
	var edge_color: Color = WeaponVisuals.GOLD if bool(zone["is_evolved"]) else look["ground"]
	var dots := maxi(12, int(radius * 1.2))
	for index: int in range(dots):
		if (index + int(_time * 8.0)) % 3 != 0:
			draw_rect(Rect2((center + Vector2.from_angle(TAU * index / dots) * radius).round(), Vector2.ONE), Color(edge_color, 0.6 * fade))
	if PILLAR_HEIGHTS.has(zone["kind"]):
		_draw_pillar(center, fade, look, float(PILLAR_HEIGHTS[zone["kind"]]))


## 빛 기둥(조명탄 분홍·구장 조명 하양): 바닥에서 위로 뻗는 줄 + 꼭대기 반짝임
func _draw_pillar(center: Vector2, fade: float, look: Dictionary, height: float) -> void:
	var flicker := 0.7 + 0.3 * sin(_time * 18.0)
	draw_rect(Rect2(center + Vector2(-1.0, -height), Vector2(3.0, height)), Color(look["flames"][1], 0.35 * fade * flicker))
	draw_rect(Rect2(center + Vector2(0.0, -height), Vector2(1.0, height)), Color(look["flames"][0], 0.7 * fade * flicker))
	draw_rect(Rect2(center + Vector2(-1.0, -height - 2.0), Vector2(3.0, 3.0)), Color(WeaponVisuals.WHITE, fade * flicker))


## 연기 구름: 천천히 도는 뭉게 덩어리 몇 개. 좀비가 비쳐 보이게 옅게 (가독성 — 문서 13), 진화하면 가장자리만 금색 점선.
func _draw_cloud(zone: Dictionary, fade: float) -> void:
	var center := Vector2(zone["center"])
	var radius := float(zone["radius"])
	var flames: Array = LOOKS["gas"]["flames"]
	draw_circle(center.round(), radius, Color(flames[2], CLOUD_FILL_ALPHA * fade))
	for index: int in range(PUFF_COUNT):
		var angle := TAU * index / PUFF_COUNT + _time * 0.4
		var puff_center := center + Vector2.from_angle(angle) * radius * 0.5
		draw_circle(puff_center.round(), radius * 0.42, Color(flames[index % flames.size()], CLOUD_PUFF_ALPHA * fade))
	if bool(zone["is_evolved"]):
		var dots := maxi(12, int(radius * 1.2))
		for index: int in range(dots):
			if (index + int(_time * 6.0)) % 2 == 0:
				draw_rect(Rect2((center + Vector2.from_angle(TAU * index / dots) * radius).round(), Vector2.ONE), Color(WeaponVisuals.GOLD, 0.7 * fade))
