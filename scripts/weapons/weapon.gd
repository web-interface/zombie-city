## [파일] scripts/weapons/weapon.gd
## [하는 일] 무기 공통 틀: 단계(1~5), 지금 단계 숫자 꺼내기, 다시 공격까지 남은 시간(공격 속도 능력치 반영), "공격할 때가 됐나". 무기마다 이 틀을 이어받아 attack()(언제 어떻게 때리나)만 따로 쓴다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 만들고 매 프레임 update() 를 부른다. 이어받는 곳: projectile_weapon.gd · spread_weapon.gd · melee_arc_weapon.gd · orbit_weapon.gd
## [근거 문서] 03 §2 무기, 11 §8 무기 구조
class_name Weapon
extends RefCounted

var weapon_id: String
var info: Dictionary
var level: int = 1
var context: RunContext
var _cooldown_left: float = 0.0


func _init(new_weapon_id: String, run_context: RunContext) -> void:
	weapon_id = new_weapon_id
	info = GameData.entry("weapons", weapon_id)
	context = run_context


## 지금 단계의 숫자 묶음 (data/weapons.json levels)
func numbers() -> Dictionary:
	var levels: Array = info["levels"]
	return levels[level - 1]


func max_level() -> int:
	var levels: Array = info["levels"]
	return levels.size()


func is_max_level() -> bool:
	return level >= max_level()


func level_up() -> void:
	level = mini(level + 1, max_level())


func update(delta: float) -> void:
	_cooldown_left -= delta * context.survivor.stats.value("attack_speed_multiplier")
	if _cooldown_left > 0.0:
		return
	if attack():
		_cooldown_left = float(numbers().get("interval_seconds", 1.0))


## 이어받는 무기가 쓴다. 실제로 공격했으면 true (목표가 없으면 false → 다음 프레임에 다시 시도)
func attack() -> bool:
	return false


## 무기가 따로 그릴 것이 있으면 (예: 도는 드론) 이어받아 쓴다.
func draw_on(canvas: CanvasItem) -> void:
	pass


## 사거리 능력치(저격수 전직 등)를 반영한 거리
func effective_range() -> float:
	return float(numbers().get("range", 100.0)) * context.survivor.stats.value("range_multiplier")
