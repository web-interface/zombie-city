## [파일] scripts/systems/zombie_spawner.gd
## [하는 일] 시간표대로 좀비를 만든다: 지난 시간에 따라 초당 나오는 수(구간별로 점점 늘어남)와 종류(나오기 시작하는 밤·때·비율)를 정하고, 생존자 둘레 화면 밖 고리에서 만든다. 밤이 지날수록 체력·수·피해·빠르기가 커지고(night_cycle), 가끔 금빛 정예가 나온다. 탈출 버티기 때, 그리고 생존자가 제자리에 오래 있으면(제자리 압박) 더 몰려온다.
## [쓰는 곳] scenes/run.tscn 의 Systems/ZombieSpawner. run.gd 가 매 프레임 update() 를 부른다. 이벤트(horde_events.gd)·보스(boss_attacks.gd)도 spawn_zombie() 로 만든다.
## [근거 문서] 14 §1 끝없는 밤·§1-2 정예, 03 §6 늘어나는 정도, 02 §3 한 밤 시간표, data/spawn_curve.json
class_name ZombieSpawner
extends Node

const EVENT_EXTRA_ZOMBIES := 40   # 포위·떼 돌진·부하 부르기는 상한보다 이만큼 더 허용 (이벤트가 통째로 빠지지 않게)

var _context: RunContext
var _curve: Dictionary = {}
var _spawn_budget: float = 0.0
var _calm_seconds_left: float = 0.0
var is_extraction_rush: bool = false
## 4초 동안 거의 안 움직였나 — 가만히 서서 버티기를 막는다 (data/spawn_curve.json idle_pressure)
var is_idle_pressure: bool = false
var _recent_positions: Array[Vector2] = []
var _sample_timer: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	_curve = GameData.table("spawn_curve")


## 다음 밤 시작: 쌓인 몫·숨 돌리기·탈출 몰림을 지운다
func reset_for_new_night() -> void:
	_spawn_budget = 0.0
	_calm_seconds_left = 0.0
	is_extraction_rush = false
	is_idle_pressure = false
	_recent_positions.clear()


## 보스를 잡은 뒤 잠깐 숨 돌리기: 좀비가 덜 나온다 (몰아치기와 쉬기의 파도 — 문서 13)
func start_calm() -> void:
	_calm_seconds_left = float(_curve["calm_after_boss_seconds"])


func update(delta: float) -> void:
	var elapsed := _context.elapsed_seconds
	_calm_seconds_left = maxf(_calm_seconds_left - delta, 0.0)
	_track_idle(delta)
	var rate := spawn_rate_at(elapsed) * _context.night_cycle.spawn_multiplier()
	if is_idle_pressure:
		rate *= float(_curve["idle_pressure"]["spawn_multiplier"])
	if is_extraction_rush:
		rate *= float(_curve["extraction_spawn_multiplier"])
	if _calm_seconds_left > 0.0:
		rate *= float(_curve["calm_spawn_multiplier"])
	_spawn_budget += rate * delta
	var room := int(_curve["max_zombies_on_field"]) - _context.horde.alive_count()
	while _spawn_budget >= 1.0 and room > 0:
		_spawn_budget -= 1.0
		room -= 1
		spawn_zombie(_pick_kind(elapsed), _spawn_position(), true)
	_spawn_budget = minf(_spawn_budget, float(_curve["max_stored_spawns"]))   # 꽉 찼을 때 쌓인 몫이 한꺼번에 쏟아지지 않게


## 좀비 하나를 이번 밤의 세기로 만든다 (체력·피해·빠르기 배율, 정예 확률). 이벤트·보스 새끼도 이걸 쓴다.
func spawn_zombie(kind_id: String, at_position: Vector2, can_be_elite: bool) -> Zombie:
	if _context.horde.alive_count() >= int(_curve["max_zombies_on_field"]) + EVENT_EXTRA_ZOMBIES:
		return null   # 이벤트·보스 부하도 상한을 지킨다 (웹·폰 성능 — 검수에서 377마리까지 감)
	var nights := _context.night_cycle
	var zombie := _context.horde.spawn(kind_id, at_position, nights.zombie_health_multiplier(_context.elapsed_seconds))
	zombie.contact_damage_per_second *= nights.contact_damage_multiplier()
	zombie.move_speed *= nights.speed_multiplier()
	var elite_rules: Dictionary = _curve["elite"]
	if can_be_elite and _context.elapsed_seconds >= float(elite_rules["from_second"]) and not elite_rules["not_for_kinds"].has(kind_id) and randf() < nights.elite_chance():
		zombie.make_elite(elite_rules)
		_context.play_sound("elite_appear")
	if is_idle_pressure:
		var idle: Dictionary = _curve["idle_pressure"]
		zombie.boost_speed(float(idle["speed_multiplier"]), float(idle["speed_seconds"]))
	return zombie


## 0.5초마다 생존자 위치를 적어 두고, 4초 내내 30점 안에만 있었으면 '제자리 압박'
func _track_idle(delta: float) -> void:
	var idle: Dictionary = _curve["idle_pressure"]
	_sample_timer -= delta
	if _sample_timer > 0.0:
		return
	_sample_timer = float(idle["sample_every_seconds"])
	var here := _context.survivor.position
	_recent_positions.append(here)
	var needed := int(float(idle["window_seconds"]) / float(idle["sample_every_seconds"]))
	if _recent_positions.size() > needed:
		_recent_positions.pop_front()
	is_idle_pressure = _recent_positions.size() >= needed
	for past: Vector2 in _recent_positions:
		if past.distance_to(here) > float(idle["min_travel"]):
			is_idle_pressure = false
			return


## 구간 안에서 시작값 → 끝값으로 고르게 늘어나는 초당 수
func spawn_rate_at(elapsed: float) -> float:
	for segment: Dictionary in _curve["spawn_rate_segments"]:
		var start := float(segment["from_second"])
		var finish := float(segment["to_second"])
		if elapsed >= start and elapsed < finish:
			var progress := (elapsed - start) / (finish - start)
			return lerpf(float(segment["per_second_start"]), float(segment["per_second_end"]), progress)
	var last: Dictionary = _curve["spawn_rate_segments"].back()
	return float(last["per_second_end"])


## 이번 밤에 나올 수 있는 종류 중 비율대로 하나. 처음 나오는 밤보다 뒤의 밤이면 처음부터 나온다.
func _pick_kind(elapsed: float) -> String:
	var night := _context.night_cycle.night
	var total_weight := 0.0
	for kind: Dictionary in _curve["kinds"]:
		if _is_kind_available(kind, night, elapsed):
			total_weight += float(kind["weight"])
	var roll := randf() * total_weight
	for kind: Dictionary in _curve["kinds"]:
		if not _is_kind_available(kind, night, elapsed):
			continue
		roll -= float(kind["weight"])
		if roll <= 0.0:
			return String(kind["kind"])
	return "walker"


func _is_kind_available(kind: Dictionary, night: int, elapsed: float) -> bool:
	var first_night := int(kind["from_night"])
	var earlier := 0.0 if kind["kind"] == "walker" else _context.night_cycle.special_zombie_earlier_seconds()   # 감염도 2
	return night > first_night or (night == first_night and elapsed >= float(kind["from_second"]) - earlier)


## 생존자 둘레 화면 밖 고리. 움직이는 쪽에서 조금 더 자주 나오게 해 앞이 막히는 긴장을 만든다.
func _spawn_position() -> Vector2:
	var survivor := _context.survivor
	var angle := randf() * TAU
	var spread := float(_curve["spawn_ahead_spread_radians"])
	if survivor.moving_direction.length() > 0.1 and randf() < float(_curve["spawn_ahead_chance"]):
		angle = survivor.moving_direction.angle() + randf_range(-spread, spread)
	var distance := float(_curve["spawn_distance"]) * (float(_curve["idle_pressure"]["spawn_distance_ratio"]) if is_idle_pressure else 1.0)
	var spot := survivor.position + Vector2.from_angle(angle) * distance
	return _context.props.push_out(spot, 6.0)
