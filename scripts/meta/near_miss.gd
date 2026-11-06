## [파일] scripts/meta/near_miss.gd
## [하는 일] 결과 화면의 '아까운 표시' 글을 고른다: 최고 기록까지 남은 밤, 잠긴 생존자 해금까지 남은 양, 다음 감염도 열기 조건, 거의 다 온 업적, 은신처 강화까지 남은 고철. 바로 [다시] 를 누르고 싶게 (한 판만 더).
## [쓰는 곳] scripts/meta/run_settlement.gd 가 판 끝에 부르고, 결과 화면이 보여 준다. 판 쪽이 결과 사전에 'near_miss_texts'(예: "진화까지 장비 하나 부족했어요")를 넣으면 맨 앞에 붙인다.
## [근거 문서] 14 §4 아까운 표시
class_name NearMiss
extends RefCounted


## context: {"result", "metrics"(판+누적), "previous_record", "new_unlocks", "new_infection_level"}
static func lines(context: Dictionary) -> Array[String]:
	var rules: Dictionary = GameData.table("meta_rules")["near_miss"]
	var metrics: Dictionary = context["metrics"]
	var found: Array[String] = []
	var result: Dictionary = context["result"]
	var run_side_texts: Variant = result.get("near_miss_texts", [])
	if typeof(run_side_texts) == TYPE_ARRAY:
		for text: Variant in run_side_texts:
			found.append(String(text))
	_add(found, _record_text(metrics, context["previous_record"]))
	for text: String in _unlock_texts(metrics, context["new_unlocks"]):
		_add(found, text)
	if int(context["new_infection_level"]) == 0:
		_add(found, _infection_text(metrics))
	_add(found, _achievement_text(metrics, float(rules["achievement_progress_ratio"])))
	_add(found, _shelter_text(float(rules["shelter_scrap_ratio"])))
	found.resize(mini(found.size(), int(rules["max_lines"])))
	return found


static func _add(found: Array[String], text: String) -> void:
	if not text.is_empty():
		found.append(text)


static func _record_text(metrics: Dictionary, previous_record: Dictionary) -> String:
	var best := int(previous_record.get("best_night", 0))
	var nights := int(metrics["nights_survived"])
	if best > nights:
		return "최고 기록까지 %d밤!" % (best - nights)
	if best == nights and best > 0:
		return "최고 기록과 같아요. 한 밤만 더!"
	return ""


static func _unlock_texts(metrics: Dictionary, new_unlocks: Array) -> Array[String]:
	var texts: Array[String] = []
	# '한 판에 셋째 밤' 같은 한 판 조건은 이번 판이 아니라 지금까지의 최고 밤으로 남은 양을 센다 (더 가까워 보여야 다시 함)
	var best_metrics := metrics.duplicate()
	best_metrics["nights_survived"] = maxi(int(metrics["nights_survived"]), int(metrics.get("best_night_any", 0)))
	for survivor_id: String in Unlocks.locked_ids():
		if new_unlocks.has(survivor_id):
			continue
		var condition := Unlocks.condition(survivor_id)
		texts.append("%s 해금까지 %s" % [Unlocks.display_name(survivor_id), RunMetrics.remaining_text(condition, best_metrics)])
	return texts


## 고른 감염도가 열린 가장 높은 단계인데 둘째 밤을 못 넘겼을 때만 (오늘의 도전은 감염도와 상관없음)
static func _infection_text(metrics: Dictionary) -> String:
	var level := int(metrics["infection_level"])
	if int(metrics["is_daily_challenge"]) == 1 or level < Infection.unlocked_level() or level >= Infection.max_level():
		return ""
	if int(metrics["nights_survived"]) >= Infection.unlock_nights():
		return ""
	return "감염도 %d 열기까지 %s 넘기기" % [level + 1, RunMetrics.night_name(Infection.unlock_nights())]


static func _achievement_text(metrics: Dictionary, min_ratio: float) -> String:
	var closest := Achievements.closest_unfinished(metrics, min_ratio)
	if closest.is_empty():
		return ""
	var achievement := Achievements.info(String(closest["id"]))
	return "업적 '%s'까지 %s" % [achievement["name"], RunMetrics.remaining_text(closest["condition"], metrics)]


static func _shelter_text(min_ratio: float) -> String:
	var cheapest := Shelter.cheapest_next_cost()
	var scrap := SaveData.scrap()
	if cheapest <= 0:
		return ""
	if scrap >= cheapest:
		return "은신처에서 강화할 수 있어요!"
	if scrap >= cheapest * min_ratio:
		return "은신처 강화까지 고철 %d" % (cheapest - scrap)
	return ""
