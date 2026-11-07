## [파일] scripts/systems/medals.gd
## [하는 일] 훈장: 밤 생존 뒤 고를 3장(안전 2 + 위험 1, 생존자 전용은 안전 쪽에 조금 더 자주, 같은 훈장은 3번까지)을 뽑고, 가진 훈장을 판에 적용한다 — 능력치는 생존자 능력치 이름표 "medals", 위험 훈장의 '좀비 +30%'·'정예 2배'·'헬기 버티기 +3초'는 밤 배율(NightCycle.medal_modifiers)로.
## [쓰는 곳] scripts/run/night_carry.gd 가 들고 있다 (밤 준비 창에 줄 3장 · 고른 훈장 더하기 · 밤 시작 때 적용 · 저장/이어하기).
## [근거 문서] 15 §2·§5-2·부록 A 훈장, data/medals.json
class_name Medals
extends RefCounted

## 가진 훈장 id → 몇 장
var owned: Dictionary = {}
var _medals: Dictionary = {}
var _offer_rules: Dictionary = {}


func _init() -> void:
	var table := GameData.table("medals")
	_medals = table["medals"]
	_offer_rules = table["offer"]


## 고를 훈장 카드 [{"id", "name", "icon", "description", "kind", "is_survivor_only", "stacks"}] — 안전 2 + 위험 1 (위험이 없으면 안전으로 채움)
func offer(survivor_id: String) -> Array[Dictionary]:
	var picked: Array[Dictionary] = []
	var total := int(_offer_rules["safe_count"]) + int(_offer_rules["risky_count"])
	_pick_weighted(_candidates("safe", survivor_id), int(_offer_rules["safe_count"]), picked)
	_pick_weighted(_candidates("risky", survivor_id), int(_offer_rules["risky_count"]), picked)
	_pick_weighted(_candidates("safe", survivor_id), total - picked.size(), picked)
	return picked


func add(medal_id: String) -> void:
	if _medals.has(medal_id):
		owned[medal_id] = int(owned.get(medal_id, 0)) + 1


## --start-night 시험: 그 밤까지 받았을 훈장 count 장을 무작위로
func add_random(count: int, survivor_id: String) -> void:
	for index: int in range(count):
		var options := offer(survivor_id)
		if not options.is_empty():
			add(String(options.pick_random()["id"]))


## 가진 훈장을 판에 적용 (밤 시작·이어하기 때마다 처음부터 다시 계산 — 같은 훈장 n장 = n번 반복)
func apply(context: RunContext) -> void:
	var stat_modifiers: Array = []
	var night_modifiers := {"multiply": {}, "add": {}}
	for medal_id: String in owned.keys():
		var medal: Dictionary = _medals.get(medal_id, {})
		for stack: int in range(int(owned[medal_id])):
			if medal.has("stats"):
				stat_modifiers.append(medal["stats"])
			_merge_night(night_modifiers, medal.get("night", {}))
	context.survivor.stats.set_source("medals", stat_modifiers)
	context.night_cycle.medal_modifiers = night_modifiers


## 결과·기록용: 가진 훈장 이름 목록 ("단련된 팔 ×2")
func names() -> Array[String]:
	var result: Array[String] = []
	for medal_id: String in owned.keys():
		var count := int(owned[medal_id])
		result.append(String(_medals[medal_id]["name"]) + (" ×%d" % count if count > 1 else ""))
	return result


func _candidates(kind: String, survivor_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for medal_id: String in _medals.keys():
		var medal: Dictionary = _medals[medal_id]
		var only_for := String(medal.get("survivor", ""))
		if String(medal["kind"]) != kind or (not only_for.is_empty() and only_for != survivor_id):
			continue
		if int(owned.get(medal_id, 0)) >= int(_offer_rules["max_stacks"]):
			continue
		result.append({"id": medal_id, "name": medal["name"], "icon": medal["icon"], "description": medal["description"], "kind": kind,
			"is_survivor_only": not only_for.is_empty(), "stacks": int(owned.get(medal_id, 0)),
			"weight": float(_offer_rules["survivor_weight"]) if not only_for.is_empty() else 1.0})
	return result


## 무게(생존자 전용은 더 무겁게)대로 count 장을 겹치지 않게 뽑아 picked 에 더한다
func _pick_weighted(candidates: Array[Dictionary], count: int, picked: Array[Dictionary]) -> void:
	var picked_ids: Array = picked.map(func(card: Dictionary) -> String: return String(card["id"]))
	var remaining: Array[Dictionary] = candidates.filter(func(card: Dictionary) -> bool: return not picked_ids.has(card["id"]))
	for index: int in range(count):
		if remaining.is_empty():
			return
		var total_weight: float = remaining.reduce(func(total: float, card: Dictionary) -> float: return total + float(card["weight"]), 0.0)
		var roll := randf() * total_weight
		var chosen := remaining.back() as Dictionary
		for card: Dictionary in remaining:
			roll -= float(card["weight"])
			if roll <= 0.0:
				chosen = card
				break
		picked.append(chosen)
		remaining.erase(chosen)


func _merge_night(into: Dictionary, night: Dictionary) -> void:
	for key: String in Dictionary(night.get("multiply", {})).keys():
		into["multiply"][key] = float(into["multiply"].get(key, 1.0)) * float(night["multiply"][key])
	for key: String in Dictionary(night.get("add", {})).keys():
		into["add"][key] = float(into["add"].get(key, 0.0)) + float(night["add"][key])
