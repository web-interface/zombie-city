## [파일] scripts/weapons/weapon_rack.gd
## [하는 일] 생존자의 무기 칸(최대 4개)과 장비 칸(최대 4개)을 관리: 새로 얻기, 단계 올리기, 매 프레임 무기 돌리기, 도는 드론 그리기. 장비 단계는 생존자 능력치(SurvivorStats)에 반영한다.
## [쓰는 곳] scenes/run.tscn 의 World/WeaponRack. 레벨 업(scripts/systems/level_up.gd)이 add_weapon()·upgrade_weapon()·add_or_upgrade_gear() 를, run.gd 가 update() 를 부른다. HUD 가 무기·장비 칸을 읽는다.
## [근거 문서] 02 §5 성장과 조합, 03 §2·§3, 11 §8
class_name WeaponRack
extends Node2D

## behavior (data/weapons.json) → 무기 스크립트
const BEHAVIOR_SCRIPTS := {
	"projectile": preload("res://scripts/weapons/projectile_weapon.gd"),
	"spread": preload("res://scripts/weapons/spread_weapon.gd"),
	"melee_arc": preload("res://scripts/weapons/melee_arc_weapon.gd"),
	"orbit": preload("res://scripts/weapons/orbit_weapon.gd"),
}

var weapons: Array[Weapon] = []
## 장비 이름 → 단계
var gear_levels: Dictionary = {}
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context
	z_index = 12


func weapon_of(weapon_id: String) -> Weapon:
	for weapon: Weapon in weapons:
		if weapon.weapon_id == weapon_id:
			return weapon
	return null


func add_weapon(weapon_id: String) -> void:
	var behavior: String = GameData.entry("weapons", weapon_id)["behavior"]
	var weapon_script: GDScript = BEHAVIOR_SCRIPTS[behavior]
	weapons.append(weapon_script.new(weapon_id, _context))


func upgrade_weapon(weapon_id: String) -> void:
	weapon_of(weapon_id).level_up()


func add_or_upgrade_gear(gear_id: String) -> void:
	gear_levels[gear_id] = int(gear_levels.get(gear_id, 0)) + 1
	var per_level: Dictionary = GameData.entry("gear", gear_id)["per_level"]
	var modifiers: Array = []
	for step: int in range(int(gear_levels[gear_id])):
		modifiers.append(per_level)
	_context.survivor.stats.set_source("gear:" + gear_id, modifiers)


func update(delta: float) -> void:
	for weapon: Weapon in weapons:
		weapon.update(delta)
	queue_redraw()


func _draw() -> void:
	for weapon: Weapon in weapons:
		weapon.draw_on(self)
