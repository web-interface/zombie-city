## [파일] scripts/systems/night_cycle.gd
## [하는 일] 끝없는 밤의 '몇째 밤'과 그 밤의 세기를 들고 있다: 좀비 체력(밤 안 +30% 까지 × 밤 사이 직선)·필드 최소 좀비·닿는 피해·빠르기·보스 체력·정예 확률 배율, 밤 이름("둘째 밤"), 그 밤의 분위기(날씨·어둠 색 — data/night_themes.json). 다음 밤으로 넘기면 숫자만 하나 올린다.
## [쓰는 곳] RunContext.night_cycle 로 들고 다닌다. zombie_spawner·night_director·boss_director 가 배율을 묻고, night_flow.gd 가 advance() 를 부르고, HUD·기록이 night 를, weather.gd 가 theme() 을 읽는다.
## [근거 문서] 15 §3-2·§4 밤 사이 곡선, 14 §1-1 밤 이어가기·§3 감염도·오늘의 도전, data/run_rules.json nights, data/spawn_curve.json, data/infection.json
class_name NightCycle
extends RefCounted

var night: int = 1
var _rules: Dictionary = {}
var _in_night_health_growth: float = 0.0
## 감염도·오늘의 도전 배율 (RunModifiers.run_multipliers — 판 시작 때 한 번)
var _run_modifiers: Dictionary = {}


func _init() -> void:
	_rules = GameData.rules("nights")
	_in_night_health_growth = float(GameData.table("spawn_curve")["in_night_health_growth"])
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


## 일반 좀비 체력 배율: 한 밤 안에서는 최대 +30% 만, 밤 사이는 직선 (15 §3-2·§4 — 어려움은 단단함이 아니라 마릿수·박자로)
func zombie_health_multiplier(elapsed_seconds: float) -> float:
	var in_night := 1.0 + _in_night_health_growth * minf(elapsed_seconds / night_seconds(), 1.0)
	var opening: Dictionary = GameData.table("spawn_curve")["first_night_opening"]
	if night == 1 and elapsed_seconds < float(opening["until_second"]):
		in_night *= float(opening["health_multiplier"])   # 첫 밤 첫 30초는 무른 좀비로 '녹는 맛'부터 (16 §2)
	var between_nights := 1.0 + float(_rules["zombie_health_growth_per_night"]) * (night - 1)
	return in_night * between_nights * _modifier("zombie_health", 1.0)


## 필드 최소 좀비 배율: 밤마다 조금씩, 상한까지 (15 §4)
func minimum_multiplier() -> float:
	var growth := minf(1.0 + float(_rules["minimum_growth_per_night"]) * (night - 1), float(_rules["max_minimum_multiplier"]))
	return growth * _modifier("zombie_count", 1.0)


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
	return float(_rules["elite_chance_first_night"]) + float(_rules["elite_chance_growth_per_night"]) * (night - 1)


func heal_ratio_between_nights() -> float:
	return float(_rules["heal_ratio_between_nights"])


## 밤 차례대로 돌아가는 목록(보스·몰아치기 종류)에서 이번 밤 것 — 목록이 끝나면 처음부터 다시
func pick_rotating(per_night_list: Array) -> Variant:
	return per_night_list[(night - 1) % per_night_list.size()]


## 새 좀비가 몇 초 일찍 나오나 (감염도 2)
func special_zombie_earlier_seconds() -> float:
	return _modifier("special_zombie_earlier_seconds", 0.0)


## 헬기 버티기에 더하는 초 (감염도 10)
func helicopter_hold_bonus_seconds() -> float:
	return _modifier("helicopter_hold_seconds_add", 0.0)


func health_pack_chance_multiplier() -> float:
	return _modifier("health_pack_chance", 1.0)


func _modifier(key: String, default_value: float) -> float:
	return float(_run_modifiers.get(key, default_value))
