## [파일] scripts/meta/run_goals.gd
## [하는 일] 판마다 작은 목표 3개: 판 시작 때 data/run_goals.json 에서 겹치지 않게 무작위로 뽑고, 판 끝에 판 결과 숫자로 이뤘는지 확인해 고철 보너스를 정한다.
## [쓰는 곳] SceneRouter 가 판을 시작할 때 pick() → SceneRouter.current_run_goals (판 중 HUD 는 판 쪽이 붙임), scripts/meta/run_settlement.gd 가 판 끝에 check(), 결과 화면이 보여 줌.
## [근거 문서] 14 §4 판마다 작은 목표 3개
class_name RunGoals
extends RefCounted


## 목표 묶음: [{"id", "text", "scrap", "conditions"}] — 같은 씨앗이면 같은 목표 (오늘의 도전은 날짜 씨앗)
static func pick(random: RandomNumberGenerator) -> Array[Dictionary]:
	var table := GameData.table("run_goals")
	var goals: Dictionary = table["goals"]
	var pool: Array = goals.keys()
	var picked: Array[Dictionary] = []
	for index: int in range(mini(int(table["goals_per_run"]), pool.size())):
		var goal_id := String(pool.pop_at(random.randi_range(0, pool.size() - 1)))
		var goal: Dictionary = (goals[goal_id] as Dictionary).duplicate(true)
		goal["id"] = goal_id
		picked.append(goal)
	return picked


## 판 끝: 목표마다 is_done 을 붙여 돌려준다
static func check(goals: Array, metrics: Dictionary) -> Array[Dictionary]:
	var checked: Array[Dictionary] = []
	for goal: Dictionary in goals:
		var result := goal.duplicate(true)
		result["is_done"] = RunMetrics.are_all_met(goal.get("conditions", []), metrics)
		checked.append(result)
	return checked


static func bonus_scrap(checked_goals: Array[Dictionary]) -> int:
	var sum := 0
	for goal: Dictionary in checked_goals:
		if bool(goal["is_done"]):
			sum += int(goal.get("scrap", 0))
	return sum
