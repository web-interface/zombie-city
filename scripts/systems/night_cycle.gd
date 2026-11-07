## [파일] scripts/systems/night_cycle.gd
## [하는 일] 끝없는 밤의 '몇째 밤'과 그 밤의 세기를 들고 있다: 좀비 체력(시간 성장을 밤 사이에도 이어 감)·나오는 수·닿는 피해·빠르기·보스 체력·정예 확률 배율, 밤 이름("둘째 밤"), 그 밤의 분위기(날씨·어둠 색 — data/night_themes.json). 다음 밤으로 넘기면 숫자만 하나 올린다.
## [쓰는 곳] RunContext.night_cycle 로 들고 다닌다. zombie_spawner·boss_director·horde_events 가 배율을 묻고, night_flow.gd 가 advance() 를 부르고, HUD·기록이 night 를, weather.gd 가 theme() 을 읽는다.
## [근거 문서] 14 §1-1 밤 이어가기·§3 감염도·오늘의 도전, data/run_rules.json nights, data/spawn_curve.json, data/infection.json
class_name NightCycle
extends RefCounted

var night: int = 1
var _rules: Dictionary = {}
var _health_growth_per_second: float = 0.0
## 감염도·오늘의 도전 배율 (RunModifiers.run_multipliers — 판 시작 때 한 번)
var _run_modifiers: Dictionary = {}
## 훈장 배율 {"multiply": {키: 배}, "add": {키: 더함}} — 위험 훈장 '좀비 +30%' 같은 것 (scripts/systems/medals.gd 가 채움)
var medal_modifiers: Dictionary = {"multiply": {}, "add": {}}


func _init() -> void:
	_rules = GameData.rules("nights")
	_health_growth_per_second = float(GameData.table("spawn_curve")["health_growth_per_second"])
	_run_modifiers = RunModifiers.run_multipliers()


func advance() -> void:
	night += 1


func night_seconds() -> float:
	return float(_rules["night_seconds"])


## "둘째 밤" — 열째 밤 뒤로는 "11번째 밤"
func night_name(night_number: int = -1) -> String:
	var number := night if night_number < 0 else night_number
	var names: Array = _rules["names"]
	if number <= names.size():
		return "%s 밤" % names[number - 1]
	return "%d번째 밤" % number


## 지난 밤들의 시간까지 이어서 늘어나는 체력 배율 — 강해진 생존자에게 둘째 밤 시작이 시시하지 않게
func zombie_health_multiplier(elapsed_seconds: float) -> float:
	return (1.0 + _health_growth_per_second * (elapsed_seconds + night_seconds() * (night - 1))) * _modifier("zombie_health", 1.0)


func spawn_multiplier() -> float:
	return (1.0 + float(_rules["spawn_growth_per_night"]) * (night - 1)) * _modifier("zombie_count", 1.0)


func contact_damage_multiplier() -> float:
	return (1.0 + float(_rules["contact_damage_growth_per_night"]) * (night - 1)) * _modifier("zombie_contact_damage", 1.0)


func speed_multiplier() -> float:
	var growth := minf(1.0 + float(_rules["speed_growth_per_night"]) * (night - 1), float(_rules["max_speed_multiplier"]))
	return growth * float(theme().get("zombie_speed_multiplier", 1.0)) * _modifier("zombie_speed", 1.0)


## 그 밤의 분위기 {name, darkness, weather, zombie_speed_multiplier} — 첫째 밤은 첫 칸, 그 뒤는 둘째 칸부터 돌아가며
func theme() -> Dictionary:
	var themes: Array = GameData.table("night_themes")["themes"]
	if night <= 1 or themes.size() <= 1:
		return themes[0]
	return themes[1 + (night - 2) % (themes.size() - 1)]


func boss_health_multiplier() -> float:
	return (1.0 + float(_rules["boss_health_growth_per_night"]) * (night - 1)) * _modifier("zombie_health", 1.0) * _modifier("boss_health", 1.0)


func elite_chance() -> float:
	return (float(_rules["elite_chance_first_night"]) + float(_rules["elite_chance_growth_per_night"]) * (night - 1)) * _modifier("elite_chance", 1.0)


func heal_ratio_between_nights() -> float:
	return float(_rules["heal_ratio_between_nights"])


## 밤마다 달라지는 목록(보스 시간표·이벤트)에서 이번 밤 것을 고른다. 목록보다 뒤의 밤은 마지막 것을 쓴다.
func pick_for_night(per_night_lists: Array) -> Array:
	if per_night_lists.is_empty():
		return []
	return per_night_lists[mini(night, per_night_lists.size()) - 1]


## 새 좀비가 몇 초 일찍 나오나 (감염도 2)
func special_zombie_earlier_seconds() -> float:
	return _modifier("special_zombie_earlier_seconds", 0.0)


## 헬기 버티기에 더하는 초 (감염도 10)
func helicopter_hold_bonus_seconds() -> float:
	return _modifier("helicopter_hold_seconds_add", 0.0)


func health_pack_chance_multiplier() -> float:
	return _modifier("health_pack_chance", 1.0)


## 감염도·오늘의 도전 배율 × 훈장 배율 + 훈장 더하기
func _modifier(key: String, default_value: float) -> float:
	var medal_multiply := float(Dictionary(medal_modifiers["multiply"]).get(key, 1.0))
	return float(_run_modifiers.get(key, default_value)) * medal_multiply + float(Dictionary(medal_modifiers["add"]).get(key, 0.0))
