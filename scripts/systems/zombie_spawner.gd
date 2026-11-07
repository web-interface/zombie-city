## [파일] scripts/systems/zombie_spawner.gd
## [하는 일] 좀비를 만든다(뱀서식 '최소 마릿수'): 밤 감독이 정한 지금 박자의 필드 최소 좀비보다 적으면 빠르게 채우고, 많으면 조금씩만 더 낸다. 종류는 나오기 시작하는 밤·때·비율대로(숨 돌리기·보스 때는 기본 좀비만), 자리는 화면 바로 바깥(가는 쪽 앞에서 더 자주). 몇 초 동안 거의 안 움직이면 알림 없이 더 많이·빠르게 몰려온다(약한 제자리 압박 — 가만히 서서 버티기 막기). 밤이 지날수록 체력·피해·빠르기가 커지고(night_cycle), 정예 자리·드문 무작위 정예를 금빛 정예로 만든다.
## [쓰는 곳] scenes/run.tscn 의 Systems/ZombieSpawner. run.gd 가 매 프레임 update() 를 부른다. 밤 감독(night_director.gd)이 spawn_elite() 를, 이벤트(horde_events.gd)·보스(boss_moves_*.gd)가 spawn_zombie() 를 쓴다.
## [근거 문서] 15 §3-1 최소 마릿수·§3-2 체력, 14 §1-2 정예, data/spawn_curve.json
class_name ZombieSpawner
extends Node

const EVENT_EXTRA_ZOMBIES := 40   # 포위·떼 돌진·부하 부르기는 상한보다 이만큼 더 허용 (이벤트가 통째로 빠지지 않게)

var _context: RunContext
var _director: NightDirector
var _curve: Dictionary = {}
var _spawn_budget: float = 0.0
## 몇 초 동안 거의 안 움직였나 (data/spawn_curve.json idle_pressure — 알림 없음)
var _is_idle: bool = false
## 제자리에 머문 초 — 오래 머물수록 더 많이 몰려온다
var _idle_seconds: float = 0.0
var _recent_positions: Array[Vector2] = []
var _sample_timer: float = 0.0


func setup(context: RunContext, director: NightDirector) -> void:
	_context = context
	_director = director
	_curve = GameData.table("spawn_curve")


## 다음 밤 시작: 쌓인 몫을 지운다
func reset_for_new_night() -> void:
	_spawn_budget = 0.0
	_is_idle = false
	_idle_seconds = 0.0
	_recent_positions.clear()


func update(delta: float) -> void:
	_track_idle(delta)
	var alive := _context.horde.alive_count()
	_idle_seconds = _idle_seconds + delta if _is_idle else 0.0
	var idle_multiplier := 1.0 + float(_curve["idle_pressure"]["minimum_growth_per_second"]) * _idle_seconds
	var shortage := roundi(_director.minimum_alive() * idle_multiplier) - alive
	var rate := _director.trickle_per_second()
	if shortage > 0:
		var fill := clampf(shortage * float(_curve["fill_ratio_per_second"]), float(_curve["fill_min_per_second"]), float(_curve["fill_max_per_second"]))
		rate = maxf(rate, fill)
	_spawn_budget += rate * delta
	var room := int(_curve["max_zombies_on_field"]) - alive
	while _spawn_budget >= 1.0 and room > 0:
		_spawn_budget -= 1.0
		room -= 1
		spawn_zombie(_pick_kind(_context.elapsed_seconds), _spawn_position(), true)
	_spawn_budget = minf(_spawn_budget, float(_curve["max_stored_spawns"]))   # 꽉 찼을 때 쌓인 몫이 한꺼번에 쏟아지지 않게


## 좀비 하나를 이번 밤의 세기로 만든다 (체력·피해·빠르기 배율, 드문 무작위 정예). 이벤트·보스 새끼도 이걸 쓴다.
func spawn_zombie(kind_id: String, at_position: Vector2, can_be_elite: bool) -> Zombie:
	if _context.horde.alive_count() >= int(_curve["max_zombies_on_field"]) + EVENT_EXTRA_ZOMBIES:
		return null   # 이벤트·보스 부하도 상한을 지킨다 (웹·폰 성능 — 검수에서 377마리까지 감)
	var nights := _context.night_cycle
	var zombie := _context.horde.spawn(kind_id, at_position, nights.zombie_health_multiplier(_context.elapsed_seconds))
	zombie.contact_damage_per_second *= nights.contact_damage_multiplier()
	zombie.move_speed *= nights.speed_multiplier()
	if can_be_elite and _can_be_random_elite(kind_id) and randf() < nights.elite_chance() and _director.can_start_random_elite():
		_make_elite(zombie)
		_director.note_random_elite(zombie)
	if _is_idle:
		var idle: Dictionary = _curve["idle_pressure"]
		zombie.boost_speed(float(idle["speed_multiplier"]), float(idle["speed_seconds"]))
	return zombie


## 0.5초마다 생존자 위치를 적어 두고, 정해진 시간 내내 좁은 곳에만 있었으면 제자리 (15 §3-1 은 빼라고 했지만 '가만히' 봇이 40초 안에 쓰러져야 해서 알림 없이 약하게 남김)
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
	_is_idle = _recent_positions.size() >= needed
	for past: Vector2 in _recent_positions:
		if past.distance_to(here) > float(idle["min_travel"]):
			_is_idle = false
			return


## 정예 자리: 화면 바로 바깥 가는 쪽 앞에서 금빛 정예 한 마리 (밤 감독이 부름)
func spawn_elite(kind_id: String) -> Zombie:
	var zombie := spawn_zombie(kind_id, _spawn_position(), false)
	if zombie != null:
		_make_elite(zombie)
	return zombie


func _make_elite(zombie: Zombie) -> void:
	zombie.make_elite(_curve["elite"])
	_context.play_sound("elite_appear")


func _can_be_random_elite(kind_id: String) -> bool:
	var elite_rules: Dictionary = _curve["elite"]
	return _context.elapsed_seconds >= float(elite_rules["from_second"]) and not elite_rules["not_for_kinds"].has(kind_id)


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
	if not _director.allows_special_kinds() and not _curve["basic_kinds"].has(kind["kind"]):
		return false
	var first_night := int(kind["from_night"])
	var earlier := 0.0 if kind["kind"] == "walker" else _context.night_cycle.special_zombie_earlier_seconds()   # 감염도 2
	return night > first_night or (night == first_night and elapsed >= float(kind["from_second"]) - earlier)


## 화면 바로 바깥 (뱀서): 생존자가 움직이는 쪽 앞에서 조금 더 자주 나와 앞이 막히는 긴장을 만든다.
func _spawn_position() -> Vector2:
	var survivor := _context.survivor
	var angle := randf() * TAU
	var spread := float(_curve["spawn_ahead_spread_radians"])
	if survivor.moving_direction.length() > 0.1 and randf() < float(_curve["spawn_ahead_chance"]):
		angle = survivor.moving_direction.angle() + randf_range(-spread, spread)
	var direction := Vector2.from_angle(angle)
	var half_view := _context.camera.view_size() * 0.5 + Vector2.ONE * float(_curve["spawn_margin_outside_view"])
	var to_edge := minf(half_view.x / maxf(absf(direction.x), 0.001), half_view.y / maxf(absf(direction.y), 0.001))
	var spot := _context.camera.global_position + direction * to_edge
	return _context.props.push_out(spot, 6.0)
