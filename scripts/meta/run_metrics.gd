## [파일] scripts/meta/run_metrics.gd
## [하는 일] 판 결과 사전을 '숫자 이름 → 숫자' 한 줄 표로 펴고(키가 아직 없으면 기본값), 저장의 누적 숫자(total_kills·codex_percent …)를 더해 준다. 업적·판 목표·해금 조건({"key", "at_least"/"at_most"})을 이 표로 확인하고 남은 양을 잰다. 밤 번호 말(첫째·둘째 …)도 여기서.
## [쓰는 곳] scripts/meta/achievements.gd · run_goals.gd · unlocks.gd · near_miss.gd · run_settlement.gd, 결과 화면.
## [근거 문서] 14 §3·§4, 11 §3 (결과 사전 키는 판 쪽 run.gd 가 넣음)
class_name RunMetrics
extends RefCounted

## 밤 번호 말 (1 → 첫째). 열째 넘으면 '11번째'
const NIGHT_ORDINALS: Array[String] = ["첫째", "둘째", "셋째", "넷째", "다섯째", "여섯째", "일곱째", "여덟째", "아홉째", "열째"]


## 판 결과 → 숫자 표. 판 쪽이 아직 넣지 않은 키는 옛 결과 키(is_escaped·survived_seconds)로 짐작한다.
static func from_result(result: Dictionary) -> Dictionary:
	var survived_seconds := float(result.get("survived_seconds", 0.0))
	var old_style_nights := 1 if bool(result.get("is_escaped", false)) else 0
	var end_reason := String(result.get("end_reason", "died"))
	var nights_survived := int(result.get("nights_survived", old_style_nights))
	return {
		"nights_survived": nights_survived,
		"last_night": int(result.get("last_night", nights_survived + 1)),
		"seconds_in_last_night": float(result.get("seconds_in_last_night", survived_seconds)),
		"total_seconds": float(result.get("total_seconds", survived_seconds)),
		"kills": int(result.get("kills", 0)),
		"boss_kills": int(result.get("boss_kills", 0)),
		"elite_kills": int(result.get("elite_kills", 0)),
		"max_combo": int(result.get("max_combo", 0)),
		"level": int(result.get("level", 1)),
		"near_death_saves": int(result.get("near_death_saves", 0)),
		"lowest_health_ratio": float(result.get("lowest_health_ratio", 1.0)),
		"skipped_cards": _count_skipped_cards(result.get("chosen_cards", [])),
		"weapons_count": _array_size(result.get("weapons_final", [])),
		"evolutions_count": _array_size(result.get("evolutions", [])),
		"zombie_kinds_count": _array_size(result.get("zombie_kinds_met", [])),
		"has_hidden_skill": 0 if String(result.get("hidden_skill", "")).is_empty() else 1,
		"infection_level": int(result.get("infection_level", 0)),
		"is_daily_challenge": 1 if bool(result.get("daily_challenge", false)) else 0,
		"died": 1 if end_reason == "died" else 0,
		"gave_up": 1 if end_reason == "gave_up" else 0,
		"helicopter_left": 1 if end_reason == "helicopter_left" else 0,
		"medal_scrap_bonus_ratio": float(result.get("medal_scrap_bonus_ratio", 0.0)),   # 위험 훈장 '어둠 속으로' (문서 15 부록 A)
	}


## 저장에 쌓인 숫자: 누적 처치·판 수·도감 % 같은 것 (업적·해금의 total_ 조건용)
static func totals_from_save() -> Dictionary:
	var records := SaveData.section("records")
	var survivors_with_night := 0
	for survivor_id: String in records.keys():
		# 표에 없는 생존자(옛 저장에 남은 기록)는 세지 않음 — 간호사는 2026-11-07 밤 되살려서 다시 셈
		if GameData.table("survivors").has(survivor_id) and int((records[survivor_id] as Dictionary).get("best_night", 0)) >= 1:
			survivors_with_night += 1
	var best_night := 0
	for record: Dictionary in records.values():
		best_night = maxi(best_night, int(record.get("best_night", 0)))
	return {
		"total_kills": SaveData.total("kills"),
		"total_runs": SaveData.total("runs"),
		"total_nights": SaveData.total("nights"),
		"total_boss_kills": SaveData.total("boss_kills"),
		"total_elite_kills": SaveData.total("elite_kills"),
		"best_night_any": best_night,
		"survivors_with_night": survivors_with_night,
		"codex_percent": Codex.total_percent(),
		"evolutions_found": Codex.found_count("evolutions"),
		"hidden_skills_found": Codex.found_count("hidden_skills"),
		"shelter_levels": Shelter.total_levels(),
	}


## 조건 하나: {"key": "kills", "at_least": 1000} 또는 {"key": "skipped_cards", "at_most": 0}
static func is_condition_met(condition: Dictionary, metrics: Dictionary) -> bool:
	var value := float(metrics.get(String(condition["key"]), 0.0))
	if condition.has("at_least") and value < float(condition["at_least"]):
		return false
	if condition.has("at_most") and value > float(condition["at_most"]):
		return false
	return true


static func are_all_met(conditions: Array, metrics: Dictionary) -> bool:
	for condition: Dictionary in conditions:
		if not is_condition_met(condition, metrics):
			return false
	return true


## at_least 조건까지 남은 양 (이미 넘었거나 at_most 조건이면 0)
static func remaining(condition: Dictionary, metrics: Dictionary) -> float:
	if not condition.has("at_least"):
		return 0.0
	return maxf(0.0, float(condition["at_least"]) - float(metrics.get(String(condition["key"]), 0.0)))


## 남은 양을 말로: "처치 320", "1밤 더" (data/meta_rules.json metric_texts)
static func remaining_text(condition: Dictionary, metrics: Dictionary) -> String:
	var texts: Dictionary = GameData.table("meta_rules")["metric_texts"]
	var key := String(condition["key"])
	var amount := ceili(remaining(condition, metrics))
	if not texts.has(key):
		return str(amount)
	return String(texts[key]) % format_count(amount)


## 1밤 → "첫째 밤" (밤 번호는 1부터)
static func night_name(night_number: int) -> String:
	if night_number >= 1 and night_number <= NIGHT_ORDINALS.size():
		return NIGHT_ORDINALS[night_number - 1] + " 밤"
	return "%d번째 밤" % night_number


## 5000 → "5,000" (천 단위 쉼표 — 큰 숫자를 한눈에)
static func format_count(amount: int) -> String:
	var digits := str(absi(amount))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + grouped


## 판 쪽이 배열 대신 다른 것을 넣어도 멈추지 않게 (결과 사전은 다른 담당이 채움)
static func _array_size(value: Variant) -> int:
	return (value as Array).size() if typeof(value) == TYPE_ARRAY else 0


static func _count_skipped_cards(chosen_cards: Variant) -> int:
	var count := 0
	if typeof(chosen_cards) != TYPE_ARRAY:
		return 0
	for card: Variant in chosen_cards:
		if String(card).begins_with("skip"):
			count += 1
	return count
