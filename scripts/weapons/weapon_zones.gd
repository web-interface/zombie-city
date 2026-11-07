## [파일] scripts/weapons/weapon_zones.gd
## [하는 일] 무기가 바닥에 남기는 장판: 불(화염병·불도끼·백드래프트)·연기 구름(최루탄 — 느려짐, 진화하면 기절)·조명탄(불 + 빛 기둥, 그 자리를 밝혀 좀비가 약해짐)·빛(구장 조명 — 하얀 빛 기둥, 빛 안 좀비는 느리고 더 아픔), 그리고 곰 덫(BearTraps). 0.25초마다 안의 좀비에게 피해를 준다. 내 것이라 하늘색·파랑·흰색(내 불 = 파란 불·흰 불)으로, 테두리 없이 점선만, 좀비 발밑에 그린다. 장판들을 CanvasGroup 하나에 모아 한 번에 투명하게 해서 겹쳐도 진해지지 않고, 설정 '내 효과 투명도'와 장판 수만큼 옅어진다. 곰 덫은 그룹 밖(또렷하게).
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 자식으로 만들고 매 프레임 update() 를 부른다. 던지는 무기(lob_area_weapon.gd)·도끼 진화(melee_arc_weapon.gd)·히든 스킬이 add_zone()·add_trap() 을 부른다. 전직 스킬 장판은 따로 scripts/world/area_effects.gd.
## [근거 문서] 15 §7-1 색 언어·§7-2 그리는 순서·§7-4 화면 정리, 14 §2-2·§3-1 (구장 조명·곰 덫), 03 §2 화염병·조명탄
class_name WeaponZones
extends Node2D

const DAMAGE_TICK_SECONDS := 0.25
const MAX_ZONES := 24                  # 장판이 이보다 많으면 가장 오래된 것부터 지운다 (성능)
const GROUND_LAYER := -4               # 바닥(-10) 위, 적 장판 채움(-1)·그림자(-3) 아래 (문서 15 §7-2)
const TRAP_LAYER := -1
## 내 장판 그룹 불투명도 = 이 값 × 설정(기본 0.6) → 기본 약 36% (문서 15 §7-1: 25~40%)
const ZONE_GROUP_OPACITY := 0.6
const CROWD_START := 4                 # 장판이 이보다 많으면 하나마다 조금씩 더 옅게 (§7-4)
const CROWD_FADE_PER_ZONE := 0.04
const CROWD_MIN_FADE := 0.6
## 무기 연출(번개·물줄기) 불투명도 = 바닥값 ~ 1 사이를 설정으로 (25%여도 번개가 사라지지는 않게)
const MIN_VISUAL_OPACITY := 0.4
const EMBERS_PER_SECOND := 3.0         # 장판 하나가 내는 불씨·연기 알갱이 수 (10 이면 좀비 위로 흰 점이 덮여 앞이 안 보였음 — 사용자 "화염병 장판 시야 확보 안 됨")
const FLARE_LIGHT_RADIUS_RATIO := 1.5  # 조명탄 빛은 장판보다 넓게
const PUFF_COUNT := 5
const FLAME_ALPHA := 1.0               # 그룹이 통째로 옅어지므로 안에서는 진하게
const FLAMES_PER_RADIUS := 0.35
const LIGHT_SPARKLE_RATIO := 0.3
const FIRE_FILL_ALPHA := 0.45          # 그룹 안 채움 — 겹쳐도 그룹이 한 번만 투명하게 함. 밝은 바탕이 좀비를 묻어서 옅게
const CLOUD_FILL_ALPHA := 0.7
const CLOUD_PUFF_ALPHA := 0.7
## 장판 피해는 소리·숫자 없이 (불과 같은 조용한 피해 — 매번 새 묶음을 만들지 않게 상수로)
const QUIET_ZONE_HIT := {"source": "fire", "show_number": false}
const LOOKS := {
	"fire": {"ground": Color("5aa9ff"), "flames": [Color("ffffff"), Color("cfeaff"), Color("8fd3ff")]},
	"flare": {"ground": Color("b8d4ff"), "flames": [Color("ffffff"), Color("eef4ff"), Color("b8d4ff")]},
	"gas": {"ground": Color("b8cde8"), "flames": [Color("ffffff"), Color("dde8f7"), Color("b8cde8")]},
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
## 내 장판을 모아 한 번에 투명하게 그리는 그룹 (전직 스킬 장판 AreaEffects 도 여기에 그린다)
var group: CanvasGroup
var _zone_canvas: Node2D
var _trap_canvas: Node2D
var _opacity_setting: float = 0.6


## 무기 장판은 좀비 발밑(세상 층)에 — 예전엔 빛 층이라 적 웅덩이를 덮었다 (사용자 '장판 구별')
func setup(context: RunContext, visuals: WeaponVisuals) -> void:
	_context = context
	_visuals = visuals
	z_as_relative = false
	z_index = GROUND_LAYER
	group = CanvasGroup.new()
	add_child(group)
	_zone_canvas = Node2D.new()
	group.add_child(_zone_canvas)
	_zone_canvas.draw.connect(_draw_zones)
	_trap_canvas = Node2D.new()
	_trap_canvas.z_as_relative = false
	_trap_canvas.z_index = TRAP_LAYER
	add_child(_trap_canvas)
	_trap_canvas.draw.connect(func() -> void: _traps.draw_on(_trap_canvas, _time))
	_traps = BearTraps.new(context, visuals)
	SaveData.changed.connect(_read_settings)
	_read_settings()


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
	var crowd_fade := clampf(1.0 - (_zones.size() - CROWD_START) * CROWD_FADE_PER_ZONE, CROWD_MIN_FADE, 1.0)
	group.self_modulate.a = ZONE_GROUP_OPACITY * _opacity_setting * crowd_fade
	_zone_canvas.queue_redraw()
	_trap_canvas.queue_redraw()


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
		_visuals.add_particle(point, Vector2(randf_range(-4.0, 4.0), -18.0), randf_range(0.4, 0.8), flames[2], WeaponVisuals.RISE_GRAVITY)   # 흰 불씨는 좀비 위에서 눈에 띄어 하늘색만


func _read_settings() -> void:
	_opacity_setting = SaveData.my_effects_opacity()
	_visuals.modulate.a = lerpf(MIN_VISUAL_OPACITY, 1.0, _opacity_setting)
	_visuals.is_flash_reduced = SaveData.is_flash_reduced()


func _draw_zones() -> void:
	for zone: Dictionary in _zones:
		var fade := clampf(float(zone["time_left"]) * 2.0, 0.0, 1.0)
		if zone["kind"] == "gas":
			_draw_cloud(zone, fade)
		else:
			_draw_fire(zone, fade)


## 파란 불(조명탄은 흰 불) 장판 + 일렁이는 불꽃 점 + 점선 가장자리
func _draw_fire(zone: Dictionary, fade: float) -> void:
	var look: Dictionary = LOOKS[zone["kind"]]
	var center := Vector2(zone["center"]).round()
	var radius := float(zone["radius"])
	var flames: Array = look["flames"]
	var flicker := 0.85 + 0.15 * sin(_time * 14.0 + center.x)
	_zone_canvas.draw_circle(center, radius, Color(look["ground"], FIRE_FILL_ALPHA * fade * flicker))
	var flame_ratio := LIGHT_SPARKLE_RATIO if zone["kind"] == "light" else 1.0   # 빛 장판은 반짝임만 조금 (하얀 점이 너무 많으면 좀비가 묻힘)
	for index: int in range(int(radius * FLAMES_PER_RADIUS * flame_ratio)):
		var point := center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * radius
		var flame_height := 3.0 if index % 5 == 0 else 2.0
		_zone_canvas.draw_rect(Rect2(point.round(), Vector2(1, flame_height)), Color(flames[index % flames.size()], FLAME_ALPHA * fade))
	var edge_color: Color = WeaponVisuals.GOLD if bool(zone["is_evolved"]) else look["ground"]
	var dots := maxi(12, int(radius * 1.2))
	for index: int in range(dots):
		if (index + int(_time * 8.0)) % 3 != 0:
			_zone_canvas.draw_rect(Rect2((center + Vector2.from_angle(TAU * index / dots) * radius).round(), Vector2.ONE), Color(edge_color, 0.6 * fade))
	if PILLAR_HEIGHTS.has(zone["kind"]):
		_draw_pillar(center, fade, look, float(PILLAR_HEIGHTS[zone["kind"]]))


## 빛 기둥(조명탄 흰빛·구장 조명 하양): 바닥에서 위로 뻗는 줄 + 꼭대기 반짝임
func _draw_pillar(center: Vector2, fade: float, look: Dictionary, height: float) -> void:
	var flicker := 0.7 + 0.3 * sin(_time * 18.0)
	_zone_canvas.draw_rect(Rect2(center + Vector2(-1.0, -height), Vector2(3.0, height)), Color(look["flames"][1], 0.35 * fade * flicker))
	_zone_canvas.draw_rect(Rect2(center + Vector2(0.0, -height), Vector2(1.0, height)), Color(look["flames"][0], 0.7 * fade * flicker))
	_zone_canvas.draw_rect(Rect2(center + Vector2(-1.0, -height - 2.0), Vector2(3.0, 3.0)), Color(WeaponVisuals.WHITE, fade * flicker))


## 연기 구름: 천천히 도는 뭉게 덩어리 몇 개. 좀비가 비쳐 보이게 옅게 (가독성 — 문서 13), 진화하면 가장자리만 금색 점선.
func _draw_cloud(zone: Dictionary, fade: float) -> void:
	var center := Vector2(zone["center"])
	var radius := float(zone["radius"])
	var flames: Array = LOOKS["gas"]["flames"]
	_zone_canvas.draw_circle(center.round(), radius, Color(flames[2], CLOUD_FILL_ALPHA * fade))
	for index: int in range(PUFF_COUNT):
		var angle := TAU * index / PUFF_COUNT + _time * 0.4
		var puff_center := center + Vector2.from_angle(angle) * radius * 0.5
		_zone_canvas.draw_circle(puff_center.round(), radius * 0.42, Color(flames[index % flames.size()], CLOUD_PUFF_ALPHA * fade))
	if bool(zone["is_evolved"]):
		var dots := maxi(12, int(radius * 1.2))
		for index: int in range(dots):
			if (index + int(_time * 6.0)) % 2 == 0:
				_zone_canvas.draw_rect(Rect2((center + Vector2.from_angle(TAU * index / dots) * radius).round(), Vector2.ONE), Color(WeaponVisuals.GOLD, 0.7 * fade))
