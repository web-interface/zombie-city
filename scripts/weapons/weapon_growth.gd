## [파일] scripts/weapons/weapon_growth.gd
## [하는 일] 30밤 동안 무기가 5단계를 넘어 자라는 계산: 그 밤 최대 레벨(5 + 2 × (밤 − 1)), 새로 얻는 무기의 시작 레벨(1밤 1, 2밤부터 그 밤 최대의 절반·최소 5), 6레벨부터의 숫자(5단계 숫자에 피해 +8%씩 더하기).
## [쓰는 곳] scripts/weapons/weapon.gd 가 numbers()·max_level() 에서, scripts/systems/level_up.gd·card_deck.gd 가 새 무기를 얻을 때, scripts/run/night_carry.gd 가 --start-night 시험 상태를 만들 때 부른다.
## [근거 문서] 16 §6 무기 성장 규칙(확정안), 15 §5-2, data/run_rules.json build.weapon_growth
class_name WeaponGrowth
extends RefCounted


static func rules() -> Dictionary:
	return GameData.rules("build")["weapon_growth"]


## 그 밤 무기 최대 레벨 (1밤 5 · 2밤 7 … 30밤 63)
static func night_max_level(night: int) -> int:
	var growth := rules()
	return int(growth["night_max_level_base"]) + int(growth["night_max_level_per_night"]) * maxi(night - 1, 0)


## 새로 얻는 무기의 시작 레벨: 1밤 1, 2밤부터 그 밤 최대의 절반(최소 5 — 5단계 모양을 갖춘 채) — 늦은 밤에도 새 무기가 쓸모 있게
static func new_weapon_start_level(night: int) -> int:
	if night <= 1:
		return 1
	var growth := rules()
	var half := floori(night_max_level(night) * float(growth["new_weapon_start_ratio"]))
	return maxi(int(growth["new_weapon_min_level_from_night_2"]), half)


## 5단계(또는 진화) 숫자 + 넘은 레벨(extra_levels)마다 피해 +8%. 원래 표는 바꾸지 않고 새 묶음을 돌려준다.
static func over_level_numbers(base_numbers: Dictionary, extra_levels: int) -> Dictionary:
	var growth := rules()
	var result := base_numbers.duplicate()
	var damage_ratio := 1.0 + float(growth["damage_bonus_per_level"]) * extra_levels
	for key: String in growth["damage_keys"]:
		if result.has(key):
			result[key] = float(result[key]) * damage_ratio
	return result
