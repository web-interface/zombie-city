## [파일] scripts/world/survivor_stats.gd
## [하는 일] 생존자 능력치 계산. 기본값(run_rules 의 survivor_base_stats + 생존자 표)에 특성·장비 단계·전직이 주는 바꾸기(add 더하기 / multiply 곱하기)를 차례로 적용해 최종 능력치를 만든다.
## [쓰는 곳] scripts/world/survivor.gd 가 가지고 있고, 무기·스킬·시스템이 survivor.stats.value("crit_chance") 처럼 읽는다.
## [근거 문서] 03 §1·§1-2·§3, data/run_rules.json survivor_base_stats
class_name SurvivorStats
extends RefCounted

## 능력치가 바뀌면 알린다 (체력 막대·이동 속도 등 다시 반영)
signal changed

var _base: Dictionary = {}
var _sources: Dictionary = {}   # 이름 → 바꾸기 묶음 목록 (예: "gear:vest" → [ {add:{max_health:20}}, … ])
var _final: Dictionary = {}


func _init(base_values: Dictionary) -> void:
	_base = base_values.duplicate(true)
	_rebuild()


## 바꾸기 묶음을 이름표와 함께 기억한다. 같은 이름표로 다시 부르면 덮어쓴다 (장비 단계가 오를 때).
func set_source(source_name: String, modifier_list: Array) -> void:
	_sources[source_name] = modifier_list.duplicate(true)
	_rebuild()


func value(stat_name: String) -> float:
	if not _final.has(stat_name):
		push_error("SurvivorStats: '%s' 능력치가 없음 (run_rules.json survivor_base_stats 확인)" % stat_name)
		return 0.0
	return float(_final[stat_name])


func is_on(flag_name: String) -> bool:
	return value(flag_name) >= 1.0


## 더하기를 먼저 모두 하고 곱하기를 나중에 한다 — 장비를 얻는 순서와 상관없이 결과가 같게.
func _rebuild() -> void:
	_final = _base.duplicate(true)
	for modifier_list: Array in _sources.values():
		for modifier: Dictionary in modifier_list:
			_apply_part(modifier.get("add", {}), false)
	for modifier_list: Array in _sources.values():
		for modifier: Dictionary in modifier_list:
			_apply_part(modifier.get("multiply", {}), true)
	changed.emit()


func _apply_part(changes: Dictionary, is_multiply: bool) -> void:
	for stat_name: String in changes.keys():
		if not _final.has(stat_name):
			push_error("SurvivorStats: 바꾸기에 모르는 능력치 '%s'" % stat_name)
			continue
		var amount := float(changes[stat_name])
		_final[stat_name] = float(_final[stat_name]) * amount if is_multiply else float(_final[stat_name]) + amount
