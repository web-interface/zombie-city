## [파일] scripts/meta/achievements.gd
## [하는 일] 업적 40개: 판 끝마다 한 판 숫자 + 누적 숫자로 조건을 확인해 새로 이룬 업적을 저장(이룬 날짜)하고 돌려준다. 거의 다 온 업적(아까운 표시)도 찾아 준다.
## [쓰는 곳] scripts/meta/run_settlement.gd (판 끝 확인·보상 고철), scripts/meta/near_miss.gd, scripts/ui/achievements_screen.gd (목록). data/achievements.json 을 읽고 저장은 SaveData 'achievements' 묶음.
## [근거 문서] 04 §8 업적, 14 §3 업적 40
class_name Achievements
extends RefCounted


static func ids() -> Array[String]:
	return GameData.entry_ids("achievements")


static func info(achievement_id: String) -> Dictionary:
	return GameData.entry("achievements", achievement_id)


static func is_done(achievement_id: String) -> bool:
	return SaveData.section("achievements").has(achievement_id)


static func done_count() -> int:
	var count := 0
	for achievement_id: String in ids():
		if is_done(achievement_id):
			count += 1
	return count


## 판 끝: 새로 이룬 업적 id 목록 (보상 고철은 판 정산이 더함)
static func note_run(metrics: Dictionary) -> Array[String]:
	var newly_done: Array[String] = []
	var today := Time.get_date_string_from_system()
	for achievement_id: String in ids():
		if is_done(achievement_id):
			continue
		if RunMetrics.are_all_met(info(achievement_id)["conditions"], metrics):
			SaveData.section("achievements")[achievement_id] = today
			newly_done.append(achievement_id)
	return newly_done


## 조건이 하나뿐이고 기준(min_ratio) 이상 다가간 업적 중 가장 가까운 것 — {"id", "condition"} (없으면 빈 사전)
static func closest_unfinished(metrics: Dictionary, min_ratio: float) -> Dictionary:
	var best := {}
	var best_ratio := min_ratio
	for achievement_id: String in ids():
		var achievement := info(achievement_id)
		var conditions: Array = achievement["conditions"]
		if is_done(achievement_id) or bool(achievement.get("is_secret", false)) or conditions.size() != 1:
			continue
		var condition: Dictionary = conditions[0]
		if not condition.has("at_least"):
			continue
		var ratio := float(metrics.get(String(condition["key"]), 0.0)) / maxf(float(condition["at_least"]), 1.0)
		if ratio >= best_ratio and ratio < 1.0:
			best_ratio = ratio
			best = {"id": achievement_id, "condition": condition}
	return best
