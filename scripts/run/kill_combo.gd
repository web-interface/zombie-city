## [파일] scripts/run/kill_combo.gd
## [하는 일] 연속 처치 세기: 2.5초 안에 다음 처치가 이어지면 숫자가 커지고, 50·100·200… 에 닿으면 milestone_reached 로 알린다(소리·빛·조각 보너스는 run_rewards.gd 가). 맞은 피해가 쌓이면(살짝 스친 건 봐줌) 또는 처치가 끊기면 0 으로 — 잘 피할수록 커지는 실력 보상. 판에서 가장 길었던 연속도 기억한다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 뒤 처치·큰 피해·매 프레임에 부르고, HUD 위 표시줄이 count 를 읽는다. 결과의 max_combo.
## [근거 문서] 14 §4 중독 설계(연속 처치), data/run_rules.json combo
class_name KillCombo
extends RefCounted

signal milestone_reached(count: int, shard_bonus: int)

var count: int = 0
var best: int = 0
var _seconds_since_kill: float = 0.0
var _damage_taken: float = 0.0   # 끊기기까지 쌓인 피해 (시간이 지나면 조금씩 잊음)
var _rules: Dictionary = {}


## 판이 준비될 때 부른다 (장면을 읽는 순간엔 GameData 가 아직 표를 안 읽었을 수 있어서 _init 에서 읽지 않음)
func setup() -> void:
	_rules = GameData.rules("combo")


func note_kill() -> void:
	count += 1
	best = maxi(best, count)
	_seconds_since_kill = 0.0
	var milestones: Array = _rules["milestones"]
	var index := milestones.find(count)
	if index >= 0:
		milestone_reached.emit(count, int(_rules["milestone_shard_bonus"][index]))


func update(delta: float) -> void:
	_seconds_since_kill += delta
	_damage_taken = maxf(_damage_taken - float(_rules["damage_forgiveness_per_second"]) * delta, 0.0)
	if _seconds_since_kill > float(_rules["reset_after_seconds"]):
		count = 0


func note_damage(amount: float) -> void:
	_damage_taken += amount
	if _damage_taken >= float(_rules["break_after_damage"]):
		break_streak()


func break_streak() -> void:
	count = 0
	_damage_taken = 0.0


## 연속이 끊기기까지 남은 비율 (1 → 0) — 표시줄의 작은 막대
func time_left_ratio() -> float:
	return clampf(1.0 - _seconds_since_kill / float(_rules["reset_after_seconds"]), 0.0, 1.0)
