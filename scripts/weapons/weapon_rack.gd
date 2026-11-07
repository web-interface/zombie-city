## [파일] scripts/weapons/weapon_rack.gd
## [하는 일] 생존자의 무기 칸(최대 4개)과 장비 칸(최대 4개)을 관리: 새로 얻기(시작 레벨), 단계 올리기, 진화, 밤마다 비우기(들고 가는 무기 1개만 — 진화는 풀림), 매 프레임 무기 돌리기, 무기가 그릴 것(드론·던진 물건·안개) 그리기. 장비 단계는 생존자 능력치(SurvivorStats)에 반영한다. 무기 연출(WeaponVisuals)·무기 장판(WeaponZones)을 자식으로 들고 있다.
## [쓰는 곳] scenes/run.tscn 의 World/WeaponRack. 레벨 업(scripts/systems/level_up.gd)이 add_weapon()·upgrade_weapon()·add_or_upgrade_gear()·evolve_weapon() 을, run.gd 가 update() 를 부른다. HUD·멈춤 창·기록이 무기·장비 칸을 읽는다.
## [근거 문서] 02 §5 성장과 조합, 03 §2·§3·§4, 14 §2-2·§2-4, 11 §9
class_name WeaponRack
extends Node2D

## behavior (data/weapons.json) → 무기 스크립트
const BEHAVIOR_SCRIPTS := {
	"projectile": preload("res://scripts/weapons/projectile_weapon.gd"),
	"spread": preload("res://scripts/weapons/spread_weapon.gd"),
	"melee_arc": preload("res://scripts/weapons/melee_arc_weapon.gd"),
	"orbit": preload("res://scripts/weapons/orbit_weapon.gd"),
	"chain": preload("res://scripts/weapons/chain_weapon.gd"),
	"lob_area": preload("res://scripts/weapons/lob_area_weapon.gd"),
	"pulse": preload("res://scripts/weapons/pulse_weapon.gd"),
	"line": preload("res://scripts/weapons/line_weapon.gd"),
}

const GLOW_LAYER := 1   # 세상(0) 위, HUD(10) 아래

var weapons: Array[Weapon] = []
## 장비 이름 → 단계
var gear_levels: Dictionary = {}
## 무기 연출(번개·물줄기·폭발 …)과 무기 장판(불·연기 구름)
var visuals: WeaponVisuals
var zones: WeaponZones
var _context: RunContext


## 무기 연출·장판은 밤 어둠(CanvasModulate)을 받지 않는 따로 층에 그린다 — 어둠에 묻히면 번개·물줄기가
## 칙칙한 보라색이 돼서 '눈에 확 띄는 무기'(문서 14 §2-7)가 안 됐다. 카메라는 그대로 따라간다.
func setup(context: RunContext) -> void:
	_context = context
	z_index = 12
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = GLOW_LAYER
	glow_layer.follow_viewport_enabled = true
	add_child(glow_layer)
	zones = WeaponZones.new()
	glow_layer.add_child(zones)
	visuals = WeaponVisuals.new()
	glow_layer.add_child(visuals)
	visuals.setup(context)
	zones.setup(context, visuals)


func weapon_of(weapon_id: String) -> Weapon:
	for weapon: Weapon in weapons:
		if weapon.weapon_id == weapon_id:
			return weapon
	return null


## start_level: 새로 얻는 무기는 그 밤 최대 레벨의 절반에서 시작 (문서 15 §5-2 — WeaponGrowth)
func add_weapon(weapon_id: String, start_level: int = 1) -> void:
	var behavior: String = GameData.entry("weapons", weapon_id)["behavior"]
	var weapon_script: GDScript = BEHAVIOR_SCRIPTS[behavior]
	var weapon: Weapon = weapon_script.new(weapon_id, _context)
	weapon.level = start_level
	weapons.append(weapon)


## 다음 밤: 무기·장비를 비우고 들고 가는 무기 하나만 그 레벨로 새로 만든다 (진화는 풀림 — 그 밤에 다시 진화하는 맛)
func reset_for_new_night(kept_weapon_id: String, kept_level: int) -> void:
	weapons.clear()
	for gear_id: String in gear_levels.keys():
		_context.survivor.stats.set_source("gear:" + gear_id, [])
	gear_levels.clear()
	zones.clear()
	if not kept_weapon_id.is_empty():
		add_weapon(kept_weapon_id, kept_level)


func upgrade_weapon(weapon_id: String) -> void:
	weapon_of(weapon_id).level_up()


func add_or_upgrade_gear(gear_id: String) -> void:
	gear_levels[gear_id] = int(gear_levels.get(gear_id, 0)) + 1
	var per_level: Dictionary = GameData.entry("gear", gear_id)["per_level"]
	var modifiers: Array = []
	for step: int in range(int(gear_levels[gear_id])):
		modifiers.append(per_level)
	_context.survivor.stats.set_source("gear:" + gear_id, modifiers)


func has_gear(gear_id: String) -> bool:
	return int(gear_levels.get(gear_id, 0)) > 0


## 최고 단계 + 짝 장비가 있는 무기 (진화 카드 후보 — 문서 14 §2-4)
func is_evolution_ready(weapon: Weapon) -> bool:
	return weapon.can_evolve() and has_gear(weapon.evolution_gear_id())


## 진화했으면 true (최고 단계가 아니거나 이미 진화했으면 아무 일도 없음)
func evolve_weapon(weapon_id: String) -> bool:
	var weapon := weapon_of(weapon_id)
	if weapon == null or not weapon.can_evolve():
		return false
	weapon.evolve()
	return true


func update(delta: float) -> void:
	for weapon: Weapon in weapons:
		weapon.update(delta)
	zones.update(delta)
	queue_redraw()


func _draw() -> void:
	for weapon: Weapon in weapons:
		weapon.draw_on(self)
