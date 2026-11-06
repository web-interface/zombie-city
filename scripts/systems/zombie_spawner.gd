## [파일] scripts/systems/zombie_spawner.gd
## [하는 일] 시간표대로 좀비를 만든다: 지난 시간에 따라 초당 나오는 수(구간별로 점점 늘어남)와 종류(나오기 시작하는 때·비율)를 정하고, 생존자 둘레 화면 밖 고리에서 만든다. 시간이 갈수록 체력이 늘어난다. 탈출 버티기 때는 더 몰려온다.
## [쓰는 곳] scenes/run.tscn 의 Systems/ZombieSpawner. run.gd 가 매 프레임 update() 를 부른다.
## [근거 문서] 03 §6 늘어나는 정도, 02 §3 한 판 시간표, data/spawn_curve.json
class_name ZombieSpawner
extends Node

var _context: RunContext
var _curve: Dictionary = {}
var _spawn_budget: float = 0.0
var _calm_seconds_left: float = 0.0
var is_extraction_rush: bool = false


func setup(context: RunContext) -> void:
	_context = context
	_curve = GameData.table("spawn_curve")


## 보스를 잡은 뒤 잠깐 숨 돌리기: 좀비가 덜 나온다 (몰아치기와 쉬기의 파도 — 문서 13)
func start_calm() -> void:
	_calm_seconds_left = float(_curve["calm_after_boss_seconds"])


func update(delta: float) -> void:
	var elapsed := _context.elapsed_seconds
	_calm_seconds_left = maxf(_calm_seconds_left - delta, 0.0)
	var rate := spawn_rate_at(elapsed) * (float(_curve["extraction_spawn_multiplier"]) if is_extraction_rush else 1.0)
	if _calm_seconds_left > 0.0:
		rate *= float(_curve["calm_spawn_multiplier"])
	_spawn_budget += rate * delta
	var room := int(_curve["max_zombies_on_field"]) - _context.horde.alive_count()
	while _spawn_budget >= 1.0 and room > 0:
		_spawn_budget -= 1.0
		room -= 1
		_spawn_one(elapsed)
	_spawn_budget = minf(_spawn_budget, float(_curve["max_stored_spawns"]))   # 꽉 찼을 때 쌓인 몫이 한꺼번에 쏟아지지 않게


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


func _spawn_one(elapsed: float) -> void:
	var kind_id := _pick_kind(elapsed)
	var health_multiplier := 1.0 + elapsed * float(_curve["health_growth_per_second"])
	_context.horde.spawn(kind_id, _spawn_position(), health_multiplier)


func _pick_kind(elapsed: float) -> String:
	var available: Array[Dictionary] = []
	var total_weight := 0.0
	for kind: Dictionary in _curve["kinds"]:
		if elapsed >= float(kind["from_second"]):
			available.append(kind)
			total_weight += float(kind["weight"])
	var roll := randf() * total_weight
	for kind: Dictionary in available:
		roll -= float(kind["weight"])
		if roll <= 0.0:
			return String(kind["kind"])
	return String(available.back()["kind"])


## 생존자 둘레 화면 밖 고리. 움직이는 쪽에서 조금 더 자주 나오게 해 앞이 막히는 긴장을 만든다.
func _spawn_position() -> Vector2:
	var survivor := _context.survivor
	var angle := randf() * TAU
	var spread := float(_curve["spawn_ahead_spread_radians"])
	if survivor.moving_direction.length() > 0.1 and randf() < float(_curve["spawn_ahead_chance"]):
		angle = survivor.moving_direction.angle() + randf_range(-spread, spread)
	var spot := survivor.position + Vector2.from_angle(angle) * float(_curve["spawn_distance"])
	return _context.props.push_out(spot, 6.0)
