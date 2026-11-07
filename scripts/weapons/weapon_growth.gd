## [파일] scripts/weapons/weapon_growth.gd
## [하는 일] 30밤 동안 무기가 5단계를 넘어 자라는 계산: 그 밤 최대 레벨(5 + 2 × (밤 − 1)), 새로 얻는 무기의 시작 레벨(그 밤 최대의 절반), 6레벨부터의 숫자(5단계 숫자에 피해 +8%씩 더하기, 5레벨마다 범위 +5% → 관통 +1 → 발 수 +1 차례, 발 수는 무기마다 +3까지).
## [쓰는 곳] scripts/weapons/weapon.gd 가 numbers()·max_level() 에서, scripts/systems/level_up.gd 가 새 무기를 얻을 때, scripts/run/night_carry.gd 가 --start-night 시험 상태를 만들 때 부른다.
## [근거 문서] 15 §5-2 무기 레벨 5 넘게, data/run_rules.json build.weapon_growth
class_name WeaponGrowth
extends RefCounted


static func rules() -> Dictionary:
	return GameData.rules("build")["weapon_growth"]


## 그 밤 무기 최대 레벨 (1밤 5 · 2밤 7 … 30밤 63)
static func night_max_level(night: int) -> int:
	var growth := rules()
	return int(growth["night_max_level_base"]) + int(growth["night_max_level_per_night"]) * maxi(night - 1, 0)


## 새로 얻는 무기의 시작 레벨: 그 밤 최대 레벨의 절반(내림, 최소 1) — 늦은 밤에도 새 무기가 쓸모 있게
static func new_weapon_start_level(night: int) -> int:
	return maxi(1, floori(night_max_level(night) * float(rules()["new_weapon_start_ratio"])))


## 5단계(또는 진화) 숫자 + 넘은 레벨(extra_levels) 보너스. 원래 표는 바꾸지 않고 새 묶음을 돌려준다.
static func over_level_numbers(base_numbers: Dictionary, extra_levels: int) -> Dictionary:
	var growth := rules()
	var result := base_numbers.duplicate()
	var damage_ratio := 1.0 + float(growth["damage_bonus_per_level"]) * extra_levels
	for key: String in growth["damage_keys"]:
		if result.has(key):
			result[key] = float(result[key]) * damage_ratio
	var bonus_counts := _bonus_counts(growth, extra_levels)
	var area_ratio := 1.0 + float(growth["area_bonus_ratio"]) * int(bonus_counts["area"])
	for key: String in growth["area_keys"]:
		if result.has(key):
			result[key] = float(result[key]) * area_ratio
	if result.has("pierce"):
		result["pierce"] = int(result["pierce"]) + int(growth["pierce_bonus"]) * int(bonus_counts["pierce"])
	var extra_count := mini(int(growth["count_bonus"]) * int(bonus_counts["count"]), int(growth["count_bonus_cap"]))
	for key: String in growth["count_keys"]:
		if result.has(key):
			result[key] = int(result[key]) + extra_count
	return result


## 5레벨마다 받은 보너스가 종류별로 몇 번인지 {"area": n, "pierce": n, "count": n} (차례대로 돌아가며)
static func _bonus_counts(growth: Dictionary, extra_levels: int) -> Dictionary:
	var order: Array = growth["bonus_order"]
	var counts := {"area": 0, "pierce": 0, "count": 0}
	var bonus_total := floori(extra_levels / float(growth["bonus_every_levels"]))
	for index: int in range(bonus_total):
		var kind := String(order[index % order.size()])
		counts[kind] = int(counts[kind]) + 1
	return counts
