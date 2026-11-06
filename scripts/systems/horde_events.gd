## [파일] scripts/systems/horde_events.gd
## [하는 일] 밤 중간의 위기 이벤트: '포위'(생존자 둘레 원으로 좀비 떼, 한 군데 틈), '떼 돌진'(빨간 화살표 예고 뒤 한쪽에서 달리는 좀비가 줄지어 몰려옴), 둘째 밤부터 '들개 무리'(한쪽에서 4~6마리). 제자리 압박이 처음 걸리면 알림도 띄운다. 시각은 data/spawn_curve.json 의 events_by_night·hound_packs.
## [쓰는 곳] scenes/run.tscn 의 Systems/HordeEvents. run.gd 가 update() 를 부르고 event_started 로 재난문자 알림을 띄운다. 좀비는 ZombieSpawner.spawn_zombie() 로 만든다.
## [근거 문서] 14 §1-4 이벤트, 13 조사 반영(몰아치기와 숨 돌리기의 파도), 12 §6 공정함(예고)
class_name HordeEvents
extends Node

signal event_started(banner_text: String)

const WARNING_COLOR := Color("ff3b3b")

var _context: RunContext
var _spawner: ZombieSpawner
var _curve: Dictionary = {}
var _schedule: Array = []
var _next_index: int = 0
var _next_pack_second: float = INF
var _pending_stampede: Dictionary = {}
var _was_idle: bool = false
var _idle_warned: bool = false   # 제자리 압박 알림은 판에 한 번


func setup(context: RunContext, spawner: ZombieSpawner) -> void:
	_context = context
	_spawner = spawner
	_curve = GameData.table("spawn_curve")
	reset_for_new_night()


func reset_for_new_night() -> void:
	_schedule = _context.night_cycle.pick_for_night(_curve["events_by_night"])
	_next_index = 0
	_pending_stampede = {}
	var packs: Dictionary = _curve["hound_packs"]
	_next_pack_second = float(packs["first_second"]) if _context.night_cycle.night >= int(packs["from_night"]) else INF


func update(delta: float) -> void:
	var elapsed := _context.elapsed_seconds
	if _next_index < _schedule.size() and elapsed >= float(_schedule[_next_index]["at_second"]):
		_start_event(String(_schedule[_next_index]["kind"]))
		_next_index += 1
	if elapsed >= _next_pack_second:
		_next_pack_second += float(_curve["hound_packs"]["every_seconds"])
		_send_hound_pack()
	if _spawner.is_idle_pressure and not _was_idle and not _idle_warned:
		_idle_warned = true
		event_started.emit(String(_curve["idle_pressure"]["banner"]))
	_was_idle = _spawner.is_idle_pressure
	if not _pending_stampede.is_empty():
		_pending_stampede["time_left"] = float(_pending_stampede["time_left"]) - delta
		if float(_pending_stampede["time_left"]) <= 0.0:
			_release_stampede(_pending_stampede["direction"])
			_pending_stampede = {}


func _start_event(kind: String) -> void:
	match kind:
		"encircle":
			_encircle()
		"stampede":
			_warn_stampede()


## 생존자 둘레 원으로 좀비 떼 — 한 군데 틈을 남겨 빠져나갈 길이 있게
func _encircle() -> void:
	var rules: Dictionary = _curve["encircle"]
	var count := int(rules["count"])
	var gap_center := randf() * TAU
	var gap_half := float(rules["gap_radians"]) * 0.5
	for index: int in range(count):
		var angle := gap_center + gap_half + (TAU - gap_half * 2.0) * float(index) / float(count)
		var spot := _context.survivor.position + Vector2.from_angle(angle) * float(rules["radius"])
		_spawner.spawn_zombie(String(rules["kind"]), _context.props.push_out(spot, 6.0), false)
	_context.play_sound("encircle_alarm")
	event_started.emit(String(rules["banner"]))


## 떼 돌진 예고: 몰려올 쪽에서 생존자 쪽으로 빨간 화살표가 깜빡인다
func _warn_stampede() -> void:
	var rules: Dictionary = _curve["stampede"]
	var direction := Vector2.from_angle(randf() * TAU)
	var seconds := float(rules["warning_seconds"])
	var center := _context.survivor.position
	for offset: float in [-16.0, 0.0, 16.0]:
		var side := direction.orthogonal() * offset
		_context.effects.line(center + direction * 120.0 + side, center + direction * 40.0 + side, WARNING_COLOR, 2.0, seconds, true)
	_pending_stampede = {"direction": direction, "time_left": seconds}
	_context.play_sound("stampede_rumble")
	event_started.emit(String(rules["banner"]))


func _release_stampede(direction: Vector2) -> void:
	var rules: Dictionary = _curve["stampede"]
	var start := _context.survivor.position + direction * float(rules["distance"])
	var spacing := float(rules["row_spacing"])
	var count := int(rules["count"])
	for index: int in range(count):
		var row := floori(index / 5.0)   # 다섯 마리씩 한 줄
		var column := index % 5 - 2
		var spot := start + direction * spacing * row + direction.orthogonal() * spacing * column
		_spawner.spawn_zombie(String(rules["kind"]), spot, false)


func _send_hound_pack() -> void:
	var packs: Dictionary = _curve["hound_packs"]
	var direction := Vector2.from_angle(randf() * TAU)
	var center := _context.survivor.position + direction * float(_curve["spawn_distance"])
	var size := randi_range(int(packs["pack_size_min"]), int(packs["pack_size_max"]))
	for index: int in range(size):
		var spot := center + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * float(packs["spread"])
		_spawner.spawn_zombie("hound", _context.props.push_out(spot, 4.0), false)
	_context.play_sound("hound_bark")
