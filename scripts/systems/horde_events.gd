## [파일] scripts/systems/horde_events.gd
## [하는 일] 큰 일 중 '무리'를 실제로 일으킨다: 몰아치기 = '떼 돌진'(빨간 화살표 1.5초 예고 뒤 한쪽에서 달리는 좀비가 줄지어 몰려옴) 또는 '포위'(생존자 둘레 원, 한 군데 틈), '들개 무리'(한쪽에서 4~6마리). 언제 일으킬지는 밤 감독이 정한다. 정예 출현 같은 알림도 대신 띄운다.
## [쓰는 곳] scenes/run.tscn 의 Systems/HordeEvents. 밤 감독(night_director.gd)이 start_rush()·send_hound_pack()·announce() 를 부르고, run.gd 가 update() 를 부르며 event_started 로 재난문자 알림을 띄운다. 좀비는 ZombieSpawner.spawn_zombie() 로 만든다.
## [근거 문서] 15 §3-1 몰아치기, 13 조사 반영(몰아치기와 숨 돌리기의 파도), 12 §6 공정함(예고)
class_name HordeEvents
extends Node

signal event_started(banner_text: String)

const WARNING_COLOR := Color("ff3b3b")

var _context: RunContext
var _spawner: ZombieSpawner
var _curve: Dictionary = {}
var _pending_stampede: Dictionary = {}


func setup(context: RunContext, spawner: ZombieSpawner) -> void:
	_context = context
	_spawner = spawner
	_curve = GameData.table("spawn_curve")


func reset_for_new_night() -> void:
	_pending_stampede = {}


## 예고가 끝난 떼 돌진을 풀어놓는다
func update(delta: float) -> void:
	if _pending_stampede.is_empty():
		return
	_pending_stampede["time_left"] = float(_pending_stampede["time_left"]) - delta
	if float(_pending_stampede["time_left"]) <= 0.0:
		_release_stampede(_pending_stampede["direction"])
		_pending_stampede = {}


## 몰아치기: "stampede"(떼 돌진) · "encircle"(포위)
func start_rush(kind: String) -> void:
	match kind:
		"encircle":
			_encircle()
		"stampede":
			_warn_stampede()


func announce(banner_text: String) -> void:
	event_started.emit(banner_text)


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


func send_hound_pack() -> void:
	var packs: Dictionary = _curve["hound_packs"]
	var direction := Vector2.from_angle(randf() * TAU)
	var center := _context.survivor.position + direction * float(_curve["spawn_distance"])
	var size := randi_range(int(packs["pack_size_min"]), int(packs["pack_size_max"]))
	for index: int in range(size):
		var spot := center + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * float(packs["spread"])
		_spawner.spawn_zombie("hound", _context.props.push_out(spot, 4.0), false)
	_context.play_sound("hound_bark")
