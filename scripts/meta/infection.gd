## [파일] scripts/meta/infection.gd
## [하는 일] 감염도 0~10: 단계까지 쌓인 배율 묶음(좀비 체력·속도·수·보스 체력·회복·다시 뽑기 …), 단계마다 더해지는 규칙 글, 고철 보너스, 열린 단계와 '이 단계로 둘째 밤을 넘기면 다음 단계 열림'.
## [쓰는 곳] scripts/meta/run_modifiers.gd (판에 붙이기 — 판 쪽은 RunModifiers.run_multipliers() 를 곱함), scripts/ui/infection_picker.gd (고르기 줄), scripts/meta/run_settlement.gd (판 끝에 다음 단계 열기), scrap_reward.gd. data/infection.json 을 읽는다.
## [근거 문서] 03 §10 감염도, 14 §3
class_name Infection
extends RefCounted


static func max_level() -> int:
	return int(GameData.table("infection")["max_level"])


## 지금까지 열린 가장 높은 단계 (처음엔 0)
static func unlocked_level() -> int:
	return clampi(int(SaveData.data.get("infection_unlocked", 0)), 0, max_level())


## 그 단계의 배율 묶음. 1~level 단계 규칙을 차례로 곱하고(multiply) 더한다(add).
## 키: zombie_health · zombie_speed · zombie_count · zombie_contact_damage · boss_health · heal · health_pack_chance · reroll_count (곱하기)
##     special_zombie_earlier_seconds · helicopter_hold_seconds_add (더하기)
static func multipliers(level: int) -> Dictionary:
	var table := GameData.table("infection")
	var result: Dictionary = (table["default_multipliers"] as Dictionary).duplicate()
	result.merge(table["default_additions"] as Dictionary)
	var levels: Array = table["levels"]
	for index: int in range(clampi(level, 0, levels.size())):
		var rule: Dictionary = levels[index]
		var multiplied: Dictionary = rule.get("multiply", {})
		for key: String in multiplied.keys():
			result[key] = float(result.get(key, 1.0)) * float(multiplied[key])
		var added: Dictionary = rule.get("add", {})
		for key: String in added.keys():
			result[key] = float(result.get(key, 0.0)) + float(added[key])
	return result


## 그 단계에서 새로 더해지는 규칙 한 줄 (0 이면 빈 글)
static func rule_text(level: int) -> String:
	var levels: Array = GameData.table("infection")["levels"]
	if level <= 0 or level > levels.size():
		return ""
	return String((levels[level - 1] as Dictionary)["text"])


## 1~level 단계 규칙 전부 (고르기 화면에서 길게 눌러 보기 대신 목록으로)
static func rule_lines(level: int) -> Array[String]:
	var lines: Array[String] = []
	for each_level: int in range(1, level + 1):
		lines.append("%d. %s" % [each_level, rule_text(each_level)])
	return lines


static func scrap_bonus_ratio(level: int) -> float:
	return float(GameData.table("infection")["scrap_bonus_per_level"]) * level


static func unlock_nights() -> int:
	return int(GameData.table("infection")["unlock_nights_survived"])


## 판 끝: 고른 단계로 둘째 밤을 넘겼고 그게 지금 열린 가장 높은 단계면 다음 단계를 연다. 새로 열린 단계(없으면 0)를 돌려준다.
static func note_run(level: int, nights_survived: int) -> int:
	if nights_survived < unlock_nights() or level < unlocked_level() or level >= max_level():
		return 0
	SaveData.data["infection_unlocked"] = level + 1
	return level + 1
