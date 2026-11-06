## [파일] scripts/meta/daily_challenge.gd
## [하는 일] 오늘의 도전: 날짜(YYYYMMDD)를 씨앗으로 생존자 하나·규칙 하나를 고른다 (모두에게 같은 조건 — 나중에 온라인 순위표). 하루 최고 기록(버틴 밤·처치·시간)과 오늘 한 판 수를 저장한다.
## [쓰는 곳] scripts/ui/daily_challenge_panel.gd (타이틀에서 여는 창), SceneRouter.start_daily_challenge() (규칙을 실어 판 시작), scripts/meta/run_settlement.gd (판 끝 기록). data/meta_rules.json 'daily_challenge', 저장은 SaveData 'daily' 묶음.
## [근거 문서] 04 §9 오늘의 도전, 14 §3·§4 매일 할 이유
class_name DailyChallenge
extends RefCounted


static func today_key() -> String:
	return Time.get_date_string_from_system()


## "2026-11-07" → 20261107 (같은 날이면 누구나 같은 씨앗)
static func seed_for(date_key: String) -> int:
	return int(date_key.replace("-", ""))


static func random_for(date_key: String) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = seed_for(date_key)
	return random


## 오늘의 생존자 — 표에 든 생존자 중에서 (잠긴 생존자가 걸리면 맛보기)
static func survivor_for(date_key: String) -> String:
	var survivor_ids := GameData.entry_ids("survivors")
	return survivor_ids[random_for(date_key).randi_range(0, survivor_ids.size() - 1)]


## 오늘의 규칙 {"id", "name", "text", run_multiply?, survivor_modifier?, cards_per_level_up?, scrap_bonus_ratio?}
static func rule_for(date_key: String) -> Dictionary:
	var rules: Dictionary = GameData.table("meta_rules")["daily_challenge"]["rules"]
	var rule_ids: Array = rules.keys()
	var random := random_for(date_key)
	random.randi()   # 생존자 고를 때 쓴 첫 수는 건너뜀 — 생존자와 규칙이 늘 같은 짝으로 묶이지 않게
	var rule_id := String(rule_ids[random.randi_range(0, rule_ids.size() - 1)])
	var rule: Dictionary = (rules[rule_id] as Dictionary).duplicate(true)
	rule["id"] = rule_id
	return rule


## 오늘 기록 {"best_nights", "best_seconds", "best_kills", "plays"} — 날이 바뀌면 빈 기록
static func today_record() -> Dictionary:
	var daily := SaveData.section("daily")
	if String(daily.get("date", "")) != today_key():
		return {}
	return daily


static func is_played_today() -> bool:
	return int(today_record().get("plays", 0)) > 0


## 판 끝: 오늘 판 수를 세고, 더 오래 버텼으면 오늘 최고로. 새 최고면 true
static func note_run(metrics: Dictionary) -> bool:
	var daily := SaveData.section("daily")
	if String(daily.get("date", "")) != today_key():
		daily.clear()
		daily["date"] = today_key()
	daily["plays"] = int(daily.get("plays", 0)) + 1
	var score := _score(int(metrics["nights_survived"]), float(metrics["seconds_in_last_night"]))
	var best_score := _score(int(daily.get("best_nights", -1)), float(daily.get("best_seconds", 0.0)))
	if score <= best_score:
		return false
	daily["best_nights"] = int(metrics["nights_survived"])
	daily["best_seconds"] = float(metrics["seconds_in_last_night"])
	daily["best_kills"] = int(metrics["kills"])
	return true


## 버틴 밤이 먼저, 같으면 마지막 밤에서 버틴 시간
static func _score(nights: int, seconds_in_last_night: float) -> float:
	return nights * 100000.0 + seconds_in_last_night
