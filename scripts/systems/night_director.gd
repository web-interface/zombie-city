## [파일] scripts/systems/night_director.gd
## [하는 일] 밤 감독: 한 밤(3분)의 박자표를 들고 지금 박자(몸풀기·쌓기·몰아치기·숨 돌리기·보스·진화 뒤 몰아치기·착륙)의 '필드 최소 좀비'를 정하고, 큰 일(몰아치기·정예·보스·들개 무리)을 정해진 자리에 하나씩 시작한다. 다른 큰 일이 진행 중이거나 15초가 안 지났으면 기다린다(최대 25초). 정예·보스가 살아 있으면 최소 마릿수를 절반 아래로. 시간 줄에 보여 줄 앞으로 올 일도 알려 준다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 매 프레임 update() 를 부르고 밤이 바뀌면 reset_for_new_night(). zombie_spawner.gd 가 minimum_alive()·trickle_per_second()·allows_special_kinds()·can_start_random_elite() 를 묻는다. scripts/ui/night_timeline.gd 가 timeline_marks() 를 읽고, run_recorder.gd 가 big_event_started·ended 를 듣는다.
## [근거 문서] 15 §3-1 시간표·큰 일은 하나씩, data/spawn_curve.json minimum_segments·night_score
class_name NightDirector
extends RefCounted

signal big_event_started(kind: String)
signal big_event_ended(kind: String)

## 이번 밤의 보스가 쓰러졌나 (진화 뒤 몰아치기 — 보스 구간 최소가 바뀜)
var is_boss_defeated: bool = false
var _context: RunContext
var _spawner: ZombieSpawner
var _events: HordeEvents
var _bosses: BossDirector
var _curve: Dictionary = {}
var _score: Dictionary = {}
## 이번 밤의 큰 일 [{kind, at_second, is_started, started_second}] (때 순서)
var _plan: Array[Dictionary] = []
## 진행 중인 큰 일 [{kind, ends_at_second(INF = 쓰러질 때까지), zombie}]
var _active: Array[Dictionary] = []
var _last_start_second: float = -INF


func setup(context: RunContext, spawner: ZombieSpawner, events: HordeEvents, bosses: BossDirector) -> void:
	_context = context
	_spawner = spawner
	_events = events
	_bosses = bosses
	_curve = GameData.table("spawn_curve")
	_score = _curve["night_score"]
	context.horde.zombie_died.connect(_on_zombie_died)
	reset_for_new_night()


func reset_for_new_night() -> void:
	is_boss_defeated = false
	_active.clear()
	_last_start_second = -INF
	_plan = _build_plan(_context.night_cycle.night)


func update(_delta: float) -> void:
	var elapsed := _context.elapsed_seconds
	for index: int in range(_active.size() - 1, -1, -1):
		if elapsed >= float(_active[index]["ends_at_second"]):
			_end_active(index)
	for event: Dictionary in _plan:
		if bool(event["is_started"]) or elapsed < float(event["at_second"]):
			continue
		if _must_wait(float(event["at_second"]), elapsed):
			return   # 앞의 큰 일이 기다리는 동안 뒤의 것이 먼저 끼어들지 않게
		_start(event, elapsed)
		return


## 지금 박자의 필드 최소 좀비 (밤 배율·정예/보스가 주인공이면 절반 아래)
func minimum_alive() -> int:
	var segment := current_segment()
	var progress := inverse_lerp(float(segment["from_second"]), float(segment["to_second"]), _context.elapsed_seconds)
	var minimum := lerpf(float(segment["minimum_start"]), float(segment["minimum_end"]), clampf(progress, 0.0, 1.0))
	if is_boss_defeated and segment.has("minimum_after_boss_defeated"):
		minimum = float(segment["minimum_after_boss_defeated"])
	if _is_featured_enemy_alive(segment):
		minimum *= float(_score["featured_minimum_ratio"])
	return roundi(minimum * _context.night_cycle.minimum_multiplier())


## 최소보다 많을 때 조금씩 더 나오는 수 (초당)
func trickle_per_second() -> float:
	var segment := current_segment()
	if is_boss_defeated and segment.has("trickle_after_boss_defeated"):
		return float(segment["trickle_after_boss_defeated"])
	return float(segment["trickle_per_second"])


## 숨 돌리기·보스 구간엔 특수 좀비 없이 기본 좀비만 (15 §3-1)
func allows_special_kinds() -> bool:
	return not bool(current_segment().get("only_basic_kinds", false))


func current_segment() -> Dictionary:
	var elapsed := _context.elapsed_seconds
	for segment: Dictionary in _curve["minimum_segments"]:
		if elapsed < float(segment["to_second"]):
			return segment
	return _curve["minimum_segments"].back()


## 무작위 정예도 '큰 일 하나씩'을 따른다: 무대가 비었고, 15초가 지났고, 다음 큰 일이 넉넉히 남았을 때만
func can_start_random_elite() -> bool:
	var elapsed := _context.elapsed_seconds
	if not _active.is_empty() or elapsed - _last_start_second < float(_score["min_gap_seconds"]) or not allows_special_kinds():
		return false
	for event: Dictionary in _plan:
		if not bool(event["is_started"]) and float(event["at_second"]) - elapsed < float(_score["random_elite_clear_seconds"]):
			return false
	return true


func note_random_elite(zombie: Zombie) -> void:
	_begin("elite", INF, zombie)


## 이번 밤 지난 초 (시간 줄이 진행 막대를 그림)
func elapsed_seconds() -> float:
	return _context.elapsed_seconds


## 시간 줄 표시 [{kind, second, is_done}] — 기다리는 큰 일은 지금 때에 붙어 따라온다
func timeline_marks() -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	for event: Dictionary in _plan:
		var kind := String(event["kind"])
		if kind != "elite" and kind != "boss":
			continue
		var is_started := bool(event["is_started"])
		var second := float(event["started_second"]) if is_started else maxf(float(event["at_second"]), _context.elapsed_seconds)
		marks.append({"kind": kind, "second": second, "is_done": is_started})
	return marks


## 이번 밤 악보: 몰아치기 1 + 정예 자리(밤이 갈수록 늘어남) + 보스 1 + (둘째 밤부터) 들개 무리
func _build_plan(night: int) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var rush: Dictionary = _score["rush"]
	plan.append(_plan_entry(String(_context.night_cycle.pick_rotating(rush["kinds"])), float(rush["at_second"])))
	var elite: Dictionary = _score["elite"]
	var slot_count := int(elite["slots_base"]) + int(float(night - 1) / float(elite["slot_every_nights"]))
	var slots: Array = elite["slot_seconds"]
	for index: int in range(mini(slot_count, slots.size())):
		plan.append(_plan_entry("elite", float(slots[index])))
	plan.append(_plan_entry("boss", float(_score["boss"]["at_second"])))
	var hounds: Dictionary = _score["hound_pack"]
	if night >= int(hounds["from_night"]):
		plan.append(_plan_entry("hound_pack", float(hounds["at_second"])))
	plan.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return float(first["at_second"]) < float(second["at_second"]))
	return plan


func _plan_entry(kind: String, at_second: float) -> Dictionary:
	return {"kind": kind, "at_second": at_second, "is_started": false, "started_second": 0.0}


## 다른 큰 일이 진행 중이거나 15초가 안 지났으면 기다린다 — 단, 제 자리에서 25초 넘게 밀리면 그냥 시작
func _must_wait(at_second: float, elapsed: float) -> bool:
	if elapsed - at_second >= float(_score["hold_max_seconds"]):
		return false
	return not _active.is_empty() or elapsed - _last_start_second < float(_score["min_gap_seconds"])


func _start(event: Dictionary, elapsed: float) -> void:
	event["is_started"] = true
	event["started_second"] = elapsed
	var kind := String(event["kind"])
	match kind:
		"stampede", "encircle":
			_events.start_rush(kind)
			_begin(kind, elapsed + float(_score["rush"]["active_seconds"]), null)
		"hound_pack":
			_events.send_hound_pack()
			_begin(kind, elapsed + float(_score["hound_pack"]["active_seconds"]), null)
		"elite":
			var zombie := _spawner.spawn_elite(String(_score["elite"]["kind"]))
			if zombie != null:
				_events.announce(String(_curve["elite"]["banner"]))
				_begin(kind, INF, zombie)
		"boss":
			_bosses.spawn_night_boss()
			_begin(kind, INF, null)


func _begin(kind: String, ends_at_second: float, zombie: Zombie) -> void:
	_active.append({"kind": kind, "ends_at_second": ends_at_second, "zombie": zombie})
	_last_start_second = _context.elapsed_seconds
	big_event_started.emit(kind)


func _end_active(index: int) -> void:
	var kind := String(_active[index]["kind"])
	_active.remove_at(index)
	big_event_ended.emit(kind)


func _on_zombie_died(zombie: Zombie) -> void:
	if zombie.is_boss:
		is_boss_defeated = true
	for index: int in range(_active.size()):
		var entry := _active[index]
		var is_this_elite: bool = entry["zombie"] == zombie
		if is_this_elite or (zombie.is_boss and entry["kind"] == "boss"):
			_end_active(index)
			return


## 정예가 살아 있거나, 보스가 보스 구간 밖까지 살아 있으면 그쪽이 주인공 (보스 구간 최소는 이미 보스에 맞춤)
func _is_featured_enemy_alive(segment: Dictionary) -> bool:
	for entry: Dictionary in _active:
		if entry["kind"] == "elite":
			return true
	return _bosses.alive_boss_count() > 0 and segment["beat"] != "boss"
