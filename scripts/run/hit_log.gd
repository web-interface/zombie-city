## [파일] scripts/run/hit_log.gd
## [하는 일] '무엇에 당했나' 기록: 생존자가 받은 피해를 출처(좀비 이름·보스 기술·웅덩이 이름)와 게임 시각으로 적어 두고, 판이 끝나면 마지막 5번 맞은 것과 마지막 5초 동안 출처별 피해 합을 묶어 준다. 계속 닿는 피해(물기·웅덩이)는 끊기지 않는 동안 한 번으로 친다.
## [쓰는 곳] scripts/world/survivor.gd 가 하나 들고 take_damage() 때 record(), 매 프레임 advance(). run.gd 가 판 끝에 summary() 를 결과에 넣고 scripts/ui/result_details.gd 가 그린다.
## [근거 문서] 15 §7-3 결과 화면 '무엇에 당했나', 12 §6 공정함(이유 모를 죽음 없음)
class_name HitLog
extends RefCounted

const RECENT_HIT_COUNT := 5
const RECENT_WINDOW_SECONDS := 5.0
## 같은 출처 피해가 이 간격 안에 이어지면 같은 한 번 (매 프레임 물리는 피해가 수십 번으로 세지지 않게)
const SAME_HIT_GAP_SECONDS := 0.4
const MAX_ONE_HIT_SECONDS := 1.0
const KEEP_SECONDS := 10.0
const TICK_BUCKET_SECONDS := 0.1

var _time: float = 0.0
var _hits: Array[Dictionary] = []      # {"source", "amount", "start", "last"} — 묶은 한 번
var _ticks: Array[Dictionary] = []     # {"source", "amount", "time"} — 마지막 5초 막대용 날것


func advance(delta: float) -> void:
	_time += delta


func record(amount: float, source: String) -> void:
	var source_name := source if not source.is_empty() else "알 수 없음"
	var last_tick: Dictionary = _ticks.back() if not _ticks.is_empty() else {}
	if not last_tick.is_empty() and last_tick["source"] == source_name and _time - float(last_tick["time"]) < TICK_BUCKET_SECONDS:
		last_tick["amount"] = float(last_tick["amount"]) + amount   # 매 프레임 피해를 잘게 쌓지 않게 묶음
	else:
		_ticks.append({"source": source_name, "amount": amount, "time": _time})
	while not _ticks.is_empty() and _time - float(_ticks[0]["time"]) > KEEP_SECONDS:
		_ticks.pop_front()
	var last: Dictionary = _hits.back() if not _hits.is_empty() else {}
	var is_same_hit: bool = not last.is_empty() and last["source"] == source_name and _time - float(last["last"]) <= SAME_HIT_GAP_SECONDS and _time - float(last["start"]) <= MAX_ONE_HIT_SECONDS
	if is_same_hit:
		last["amount"] = float(last["amount"]) + amount
		last["last"] = _time
		return
	_hits.append({"source": source_name, "amount": amount, "start": _time, "last": _time})
	if _hits.size() > RECENT_HIT_COUNT:
		_hits.pop_front()


## 결과에 넣을 묶음: {"last_hits": [{"source","amount"}…최근 5번, 오래된 것부터], "last_seconds": [{"source","amount"}…피해 큰 순], "window_seconds"}
func summary() -> Dictionary:
	var last_hits: Array[Dictionary] = []
	for hit: Dictionary in _hits:
		last_hits.append({"source": hit["source"], "amount": snappedf(float(hit["amount"]), 0.1)})
	var totals: Dictionary = {}
	for tick: Dictionary in _ticks:
		if _time - float(tick["time"]) <= RECENT_WINDOW_SECONDS:
			totals[tick["source"]] = float(totals.get(tick["source"], 0.0)) + float(tick["amount"])
	var last_seconds: Array[Dictionary] = []
	for source: String in totals.keys():
		if float(totals[source]) < 0.5:
			continue   # 막혀서 0 이 된 피해는 막대에 안 넣음
		last_seconds.append({"source": source, "amount": snappedf(float(totals[source]), 0.1)})
	last_seconds.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return float(first["amount"]) > float(second["amount"]))
	return {"last_hits": last_hits, "last_seconds": last_seconds, "window_seconds": RECENT_WINDOW_SECONDS}
