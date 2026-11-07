## [파일] scripts/run/flow_metrics.gd
## [하는 일] 한 밤의 '흐름' 지표를 30초 구간마다 모은다: 일반 좀비가 처음 맞고 쓰러지기까지 걸린 시간(평균), 필드 좀비 수(평균·최대), 구간 끝 레벨, 모은 조각. 큰 일(몰아치기·정예·보스·들개 무리)의 시작·끝을 적고, 다른 큰 일이 아직 진행 중이거나 15초 안에 시작한 '겹침'을 센다.
## [쓰는 곳] scripts/run/run_recorder.gd 가 들고 매 프레임 sample()·처치 때 note_kill() 을 부르고, 판 끝에 to_result() 를 결과 사전에 합친다. tools/balance_stats.py 가 표로 보여 준다.
## [근거 문서] 15 §9 목표 표(처치 시간·화면 좀비·큰 일 하나씩), 12 §5 재미 지표
class_name FlowMetrics
extends RefCounted

## 구간 길이 — 재는 단위라서 밸런스 숫자가 아니다 (15 §9 '몸풀기·몰아치기·진화 뒤'를 나눠 보려고 30초)
const WINDOW_SECONDS := 30.0

## 큰 일 시작·끝 [{night, kind, start, end}] (end 가 -1 이면 판이 끝날 때까지 안 끝남)
var big_events: Array[Dictionary] = []
var big_event_overlaps: int = 0
var _minimum_gap_seconds: float = 0.0
## 좀비 instance id → 처음 맞은 때 (밤 안 초)
var _first_hit_seconds: Dictionary = {}
## "밤:구간 번호" → 구간 누적값
var _windows: Dictionary = {}


func _init() -> void:
	_minimum_gap_seconds = float(GameData.table("spawn_curve")["night_score"]["min_gap_seconds"])


## 매 프레임: 필드 좀비 수·레벨을 쌓고, 이번 프레임에 처음 다친 일반 좀비의 때를 적는다
func sample(horde: ZombieHorde, night: int, elapsed: float, level: int) -> void:
	var window := _window(night, elapsed)
	var alive := horde.alive_count()
	window["frames"] = int(window["frames"]) + 1
	window["zombie_sum"] = int(window["zombie_sum"]) + alive
	window["zombie_max"] = maxi(int(window["zombie_max"]), alive)
	window["level"] = level
	for zombie: Zombie in horde.zombies:
		if zombie.health < zombie.max_health and not zombie.is_boss and not zombie.is_elite:
			var zombie_id := zombie.get_instance_id()
			if not _first_hit_seconds.has(zombie_id):
				_first_hit_seconds[zombie_id] = elapsed


## 일반 좀비가 쓰러짐: 처음 맞은 때부터 걸린 시간 (한 방에 쓰러지면 0)
func note_kill(zombie: Zombie, night: int, elapsed: float) -> void:
	if zombie.is_boss or zombie.is_elite:
		return
	var zombie_id := zombie.get_instance_id()
	var seconds := elapsed - float(_first_hit_seconds.get(zombie_id, elapsed))
	_first_hit_seconds.erase(zombie_id)
	var window := _window(night, elapsed)
	window["kill_seconds_sum"] = float(window["kill_seconds_sum"]) + seconds
	window["kills"] = int(window["kills"]) + 1


func note_shards(amount: float, night: int, elapsed: float) -> void:
	var window := _window(night, elapsed)
	window["shards"] = float(window["shards"]) + amount


## 큰 일이 시작됨 — 다른 큰 일이 아직 진행 중이거나 바로 앞 큰 일이 15초 안에 시작했으면 겹침
func note_big_event_started(kind: String, night: int, elapsed: float) -> void:
	for event: Dictionary in big_events:
		if int(event["night"]) != night:
			continue
		var is_still_on := float(event["end"]) < 0.0
		if is_still_on or elapsed - float(event["start"]) < _minimum_gap_seconds:
			big_event_overlaps += 1
			break
	big_events.append({"night": night, "kind": kind, "start": snappedf(elapsed, 0.1), "end": -1.0})


func note_big_event_ended(kind: String, night: int, elapsed: float) -> void:
	for index: int in range(big_events.size() - 1, -1, -1):
		var event := big_events[index]
		if int(event["night"]) == night and String(event["kind"]) == kind and float(event["end"]) < 0.0:
			event["end"] = snappedf(elapsed, 0.1)
			return


## 다음 밤: 다친 좀비 목록을 비운다 (길거리를 비우니까)
func clear_night() -> void:
	_first_hit_seconds.clear()


## 결과 사전에 합칠 묶음: flow_windows = [{night, from_second, kill_seconds, kills, zombies_average, zombies_max, level, shards}]
func to_result() -> Dictionary:
	var windows: Array[Dictionary] = []
	var keys := _windows.keys()
	keys.sort_custom(_is_earlier_window)
	for key: String in keys:
		windows.append(_summarize(_windows[key]))
	return {"flow_windows": windows, "big_events": big_events, "big_event_overlaps": big_event_overlaps}


func _summarize(window: Dictionary) -> Dictionary:
	var kills := int(window["kills"])
	var frames := maxi(int(window["frames"]), 1)
	return {
		"night": window["night"],
		"from_second": window["from_second"],
		"kill_seconds": snappedf(float(window["kill_seconds_sum"]) / maxf(float(kills), 1.0), 0.01),
		"kills": kills,
		"zombies_average": snappedf(float(window["zombie_sum"]) / float(frames), 0.1),
		"zombies_max": window["zombie_max"],
		"level": window["level"],
		"shards": snappedf(float(window["shards"]), 0.1),
	}


func _window(night: int, elapsed: float) -> Dictionary:
	var index := int(elapsed / WINDOW_SECONDS)
	var key := "%d:%d" % [night, index]
	if not _windows.has(key):
		_windows[key] = {
			"night": night, "index": index, "from_second": int(index * WINDOW_SECONDS),
			"frames": 0, "zombie_sum": 0, "zombie_max": 0, "level": 1,
			"kills": 0, "kill_seconds_sum": 0.0, "shards": 0.0,
		}
	return _windows[key]


func _is_earlier_window(first_key: String, second_key: String) -> bool:
	var first: Dictionary = _windows[first_key]
	var second: Dictionary = _windows[second_key]
	if int(first["night"]) != int(second["night"]):
		return int(first["night"]) < int(second["night"])
	return int(first["index"]) < int(second["index"])
