## [파일] scripts/meta/run_settlement.gd
## [하는 일] 판 끝 정산: 판 결과로 누적 숫자·생존자 기록·도감·해금·감염도·오늘의 도전 기록·업적·판 목표를 차례로 고치고, 고철을 계산해 넣고, 저장한 뒤, 결과 화면에 보여 줄 묶음(고철 줄·새 기록·새 업적·해금·아까운 표시·목표 결과)을 돌려준다.
## [쓰는 곳] SceneRouter.finish_run() 이 부른다 → SceneRouter.last_settlement → 결과 화면(scripts/ui/result_screen.gd·result_details.gd).
## [근거 문서] 14 §3·§4, 03 §11
class_name RunSettlement
extends RefCounted


## 돌려주는 묶음 키: metrics · scrap_lines · scrap_total · new_records · new_achievements(id 목록) · new_unlocks(생존자 id 목록)
##   new_infection_level(0 이면 없음) · new_codex(이름 목록) · goals(목표 + is_done) · near_miss(글 목록) · is_daily_best · previous_record
static func settle(result: Dictionary, run_goals: Array) -> Dictionary:
	var metrics := RunMetrics.from_result(result)
	var survivor_id := String(result.get("survivor", SceneRouter.selected_survivor_id))
	var previous_record := Records.of(survivor_id).duplicate()
	_add_totals(metrics)
	var new_records := Records.note_run(survivor_id, metrics)
	var new_codex := Codex.note_run(result)
	var is_daily := int(metrics["is_daily_challenge"]) == 1
	var new_infection_level := 0 if is_daily else Infection.note_run(int(metrics["infection_level"]), int(metrics["nights_survived"]))
	var is_daily_best := DailyChallenge.note_run(metrics) if is_daily else false
	# 누적 숫자·도감·기록을 고친 뒤에 확인해야 '누적 1만'·'도감 반' 같은 업적이 이번 판에 바로 열린다
	var all_metrics := metrics.merged(RunMetrics.totals_from_save())
	var new_unlocks := Unlocks.note_run(all_metrics)
	var new_achievements := Achievements.note_run(all_metrics)
	var goals := RunGoals.check(run_goals, metrics)
	var scrap_lines := ScrapReward.lines(metrics, RunGoals.bonus_scrap(goals), _achievement_scrap(new_achievements))
	var scrap_total := ScrapReward.sum(scrap_lines)
	SaveData.add_scrap(scrap_total)
	SaveData.add_total("scrap_earned", scrap_total)
	var near_miss := NearMiss.lines({
		"result": result, "metrics": all_metrics, "previous_record": previous_record,
		"new_unlocks": new_unlocks, "new_infection_level": new_infection_level,
	})
	SaveData.save()
	return {
		"metrics": metrics, "scrap_lines": scrap_lines, "scrap_total": scrap_total,
		"new_records": new_records, "new_achievements": new_achievements, "new_unlocks": new_unlocks,
		"new_infection_level": new_infection_level, "new_codex": new_codex, "goals": goals,
		"near_miss": near_miss, "is_daily_best": is_daily_best, "previous_record": previous_record,
	}


static func _add_totals(metrics: Dictionary) -> void:
	SaveData.add_total("runs", 1)
	SaveData.add_total("kills", int(metrics["kills"]))
	SaveData.add_total("nights", int(metrics["nights_survived"]))
	SaveData.add_total("boss_kills", int(metrics["boss_kills"]))
	SaveData.add_total("elite_kills", int(metrics["elite_kills"]))
	if int(metrics["is_daily_challenge"]) == 1:
		SaveData.add_total("daily_plays", 1)


static func _achievement_scrap(achievement_ids: Array[String]) -> int:
	var sum := 0
	for achievement_id: String in achievement_ids:
		sum += int(Achievements.info(achievement_id).get("scrap", 0))
	return sum
