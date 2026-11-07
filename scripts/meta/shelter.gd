## [파일] scripts/meta/shelter.gd
## [하는 일] 은신처 강화 10종 계산: 지금 단계·값·다음 가격, 고철로 강화하기, 판 시작 때 생존자 능력치에 얹을 바꾸기 묶음(더하기·곱하기), 능력치가 아닌 강화(다시 뽑기·빼 버리기·부활·시작 레벨·고철 +%)의 값.
## [쓰는 곳] scripts/ui/shelter_screen.gd (화면), scripts/meta/run_modifiers.gd (판에 붙이기), scripts/meta/scrap_reward.gd (고철 +%). data/shelter.json 을 읽고 단계는 SaveData 'shelter' 묶음에 둔다.
## [근거 문서] 14 §3 은신처 강화 10종, 03 §11
class_name Shelter
extends RefCounted


static func upgrade_ids() -> Array[String]:
	return GameData.entry_ids("shelter")


static func info(upgrade_id: String) -> Dictionary:
	return GameData.entry("shelter", upgrade_id)


static func level(upgrade_id: String) -> int:
	return int(SaveData.section("shelter").get(upgrade_id, 0))


static func max_level(upgrade_id: String) -> int:
	return (info(upgrade_id)["values"] as Array).size()


static func is_maxed(upgrade_id: String) -> bool:
	return level(upgrade_id) >= max_level(upgrade_id)


## 다음 단계 가격 (최고 단계면 0)
static func next_cost(upgrade_id: String) -> int:
	if is_maxed(upgrade_id):
		return 0
	return int((info(upgrade_id)["costs"] as Array)[level(upgrade_id)])


## 단계의 값 (단계 0 은 0 — 강화 안 함)
static func value_at(upgrade_id: String, at_level: int) -> float:
	if at_level <= 0:
		return 0.0
	var values: Array = info(upgrade_id)["values"]
	return float(values[mini(at_level, values.size()) - 1])


static func current_value(upgrade_id: String) -> float:
	return value_at(upgrade_id, level(upgrade_id))


## 고철을 내고 한 단계 올린다. 모자라거나 최고 단계면 false (저장까지 함)
static func buy(upgrade_id: String) -> bool:
	if is_maxed(upgrade_id) or not SaveData.spend_scrap(next_cost(upgrade_id)):
		return false
	SaveData.section("shelter")[upgrade_id] = level(upgrade_id) + 1
	SaveData.save()
	return true


## 화면에 보일 값 글: "+14", "+8%", "+1번" (data 의 display 방식대로)
static func value_text(upgrade_id: String, at_level: int) -> String:
	var upgrade := info(upgrade_id)
	var value := value_at(upgrade_id, at_level)
	match String(upgrade.get("display", "plus_number")):
		"plus_percent_from_multiplier":
			return "+%d%%" % roundi((value - 1.0) * 100.0) if at_level > 0 else "+0%"
		"plus_percent":
			return "+%d%%" % roundi(value * 100.0)
		"count":
			return "+%d%s" % [roundi(value), String(upgrade.get("count_word", ""))]
	return "+%d" % roundi(value)


## 판 시작 때 생존자 능력치에 얹을 바꾸기 묶음 (SurvivorStats.set_source 형식: [{add:{}}, {multiply:{}}])
static func stat_modifiers() -> Array:
	var additions: Dictionary = {}
	var multipliers: Dictionary = {}
	for upgrade_id: String in upgrade_ids():
		var upgrade := info(upgrade_id)
		if not upgrade.has("stat") or level(upgrade_id) <= 0:
			continue
		var stat_name := String(upgrade["stat"])
		if String(upgrade["mode"]) == "multiply":
			multipliers[stat_name] = float(multipliers.get(stat_name, 1.0)) * current_value(upgrade_id)
		else:
			additions[stat_name] = float(additions.get(stat_name, 0.0)) + current_value(upgrade_id)
	return [{"add": additions}, {"multiply": multipliers}]


## 능력치가 아닌 강화의 값 (다시 뽑기 +N·빼 버리기 +N·부활 N번·시작 레벨 +N·고철 +비율)
static func extra_rerolls() -> int:
	return roundi(current_value("reroll"))


static func extra_banishes() -> int:
	return roundi(current_value("banish"))


static func revives() -> int:
	return roundi(current_value("revive"))


static func start_level_bonus() -> int:
	return roundi(current_value("start_level"))


static func scrap_bonus_ratio() -> float:
	return current_value("scrap_bonus")


## 모든 강화 단계 합 (업적 '은신처 손봄')
static func total_levels() -> int:
	var sum := 0
	for upgrade_id: String in upgrade_ids():
		sum += level(upgrade_id)
	return sum


## 가장 싼 다음 강화 가격 (아까운 표시 "강화까지 고철 35") — 다 올렸으면 0
static func cheapest_next_cost() -> int:
	var cheapest := 0
	for upgrade_id: String in upgrade_ids():
		var cost := next_cost(upgrade_id)
		if cost > 0 and (cheapest == 0 or cost < cheapest):
			cheapest = cost
	return cheapest
