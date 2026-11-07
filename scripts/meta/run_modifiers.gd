## [파일] scripts/meta/run_modifiers.gd
## [하는 일] 이번 판에 붙는 바꾸기를 한곳에서 모아 준다: 은신처 강화(능력치·다시 뽑기·빼 버리기·부활·시작 레벨·고철 +%), 고른 감염도의 배율, 오늘의 도전 규칙. 판 쪽은 이 함수들만 부르면 된다.
## [쓰는 곳] scripts/world/survivor.gd (판 시작 능력치: survivor_stat_modifiers), 판 쪽(run.gd·level_up.gd·좀비 세기 계산 — 총책임관이 붙임), scripts/meta/scrap_reward.gd. SceneRouter 의 고른 감염도·오늘의 도전 값을 읽는다.
## [근거 문서] 14 §3 은신처·감염도·오늘의 도전, 03 §10·§11
class_name RunModifiers
extends RefCounted


## 좀비 세기 등 판 배율: 감염도 배율 × 오늘의 도전 규칙 (키는 Infection.multipliers 와 같음, 'heal' 만 빠짐)
## 곱하기 키: zombie_health · zombie_speed · zombie_count · zombie_contact_damage · boss_health · health_pack_chance · reroll_count
## 더하기 키: special_zombie_earlier_seconds · helicopter_hold_seconds_add
## 회복 배율(heal)은 생존자 능력치 heal_multiplier 에 이미 얹어서(survivor_stat_modifiers) 판 쪽이 따로 곱하지 않게 뺀다
static func run_multipliers() -> Dictionary:
	var result := _infection_and_daily()
	result.erase("heal")
	return result


## 생존자 능력치에 얹을 바꾸기 묶음 (SurvivorStats.set_source 형식) — 은신처 + 오늘의 도전 + 감염도 회복 배율
static func survivor_stat_modifiers() -> Array:
	var modifiers := Shelter.stat_modifiers()
	var daily_modifier: Dictionary = _daily_rule().get("survivor_modifier", {})
	if not daily_modifier.is_empty():
		modifiers.append(daily_modifier)
	var heal := float(_infection_and_daily().get("heal", 1.0))
	if not is_equal_approx(heal, 1.0):
		modifiers.append({"multiply": {"heal_multiplier": heal}})   # 감염도 7 '회복 효과 절반'
	return modifiers


## 판마다 다시 뽑기 수: (기본 + 은신처) × 감염도·도전 배율(0 이면 없음)
static func rerolls(base_count: int) -> int:
	return roundi((base_count + Shelter.extra_rerolls()) * float(run_multipliers()["reroll_count"]))


## 판마다 빼 버리기 수: 기본 + 은신처
static func banishes(base_count: int) -> int:
	return base_count + Shelter.extra_banishes()


## 쓰러져도 다시 일어나는 횟수 (은신처 '예비 구급 가방')
static func revives() -> int:
	return Shelter.revives()


## 판 시작 레벨에 더할 수 (은신처 '출동 전 몸풀기' — 레벨 1 + 이 값으로 시작)
static func start_level_bonus() -> int:
	return Shelter.start_level_bonus()


## 레벨 업 카드 수 (오늘의 도전 '카드 두 장'이면 2)
static func cards_per_level_up(base_count: int) -> int:
	return int(_daily_rule().get("cards_per_level_up", base_count))


## 받는 고철 보너스 비율 (은신처 + 오늘의 도전) — 감염도 보너스는 따로 (ScrapReward)
static func scrap_bonus_ratio() -> float:
	return Shelter.scrap_bonus_ratio() + float(_daily_rule().get("scrap_bonus_ratio", 0.0))


static func _infection_and_daily() -> Dictionary:
	var result := Infection.multipliers(SceneRouter.selected_infection_level)
	var daily_multiply: Dictionary = _daily_rule().get("run_multiply", {})
	for key: String in daily_multiply.keys():
		result[key] = float(result.get(key, 1.0)) * float(daily_multiply[key])
	return result


static func _daily_rule() -> Dictionary:
	return SceneRouter.daily_rule if SceneRouter.is_daily_challenge else {}
