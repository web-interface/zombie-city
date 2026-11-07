## [파일] scripts/meta/scrap_reward.gd
## [하는 일] 판 끝 고철 계산을 항목별로: 처치 100마리당 10 · 보스 25 · 밤 생존 60 × 밤 번호(둘째 밤까지면 60+120) → 감염도 +15%/단계 · 은신처·오늘의 도전 +% → 판 목표 · 업적 보상. 결과 화면이 줄마다 보여 준다.
## [쓰는 곳] scripts/meta/run_settlement.gd 가 부르고, 결과 화면(scripts/ui/result_details.gd)이 lines 를 그린다. data/meta_rules.json 'scrap', data/infection.json 을 읽는다.
## [근거 문서] 14 §3 고철, 03 §11 고철
class_name ScrapReward
extends RefCounted


## [{"label": "처치 812", "amount": 81}, …] — 0 인 줄은 뺀다 (보스 0 같은 빈 줄이 길게 늘어지지 않게)
static func lines(metrics: Dictionary, goal_bonus: int, achievement_bonus: int) -> Array[Dictionary]:
	var rules: Dictionary = GameData.table("meta_rules")["scrap"]
	var kills := int(metrics["kills"])
	var boss_kills := int(metrics["boss_kills"])
	var nights := int(metrics["nights_survived"])
	var result: Array[Dictionary] = []
	_add_line(result, "처치 %s" % RunMetrics.format_count(kills), floori(kills * float(rules["scrap_per_kill"])))
	_add_line(result, "보스 %d" % boss_kills, boss_kills * int(rules["scrap_per_boss"]))
	# 밤 생존: 첫째 밤 60, 둘째 밤 120 … 을 모두 더함 (밤이 길어질수록 크게 — 다음 밤으로 갈 이유)
	_add_line(result, "버틴 밤 %d" % nights, roundi(float(rules["scrap_per_night_number"]) * nights * (nights + 1) * 0.5))
	var base := sum(result)
	var infection_level := int(metrics["infection_level"])
	var infection_ratio := Infection.scrap_bonus_ratio(infection_level)
	_add_line(result, "감염도 %d (+%d%%)" % [infection_level, roundi(infection_ratio * 100.0)], roundi(base * infection_ratio))
	var bonus_ratio := RunModifiers.scrap_bonus_ratio()
	_add_line(result, "은신처·도전 (+%d%%)" % roundi(bonus_ratio * 100.0), roundi(base * bonus_ratio))
	_add_line(result, "판 목표", goal_bonus)
	_add_line(result, "업적", achievement_bonus)
	return result


static func sum(reward_lines: Array[Dictionary]) -> int:
	var total := 0
	for line: Dictionary in reward_lines:
		total += int(line["amount"])
	return total


static func _add_line(reward_lines: Array[Dictionary], label: String, amount: int) -> void:
	if amount > 0:
		reward_lines.append({"label": label, "amount": amount})
