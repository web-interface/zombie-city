## [파일] scripts/world/zombie_abilities.gd
## [하는 일] 새 좀비들의 특수 행동(data/zombies.json 의 ability): 침 뱉는 좀비는 거리를 두고 침을 뱉고, 비명 좀비는 주변 좀비를 잠깐 빠르게 하고, 부푼 좀비는 쓰러지면 빨간 예고 뒤 터지고, 진압복 좀비는 앞에서 오는 투사체를 방패로 막는다.
## [쓰는 곳] scripts/world/zombie_horde.gd 가 만들어 들고, 좀비를 움직일 때·맞을 때·쓰러질 때 부른다. 공격은 scripts/world/hazards.gd 로 보낸다.
## [근거 문서] 14 §1-2 새 좀비, 12 §6 공정함(큰 공격은 예고)
class_name ZombieAbilities
extends RefCounted

const SCREAM_RING_COLOR := Color("e9d8ff")
const SHIELD_SPARK_COLOR := Color("cfe3ff")

var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context


## 침 뱉는 좀비는 생존자에게 다가오지 않고 거리를 둔다 (무리가 움직이기 전에 묻는다)
func holds_distance(zombie: Zombie, distance_to_survivor: float) -> bool:
	var ability: Dictionary = zombie.info.get("ability", {})
	return ability.get("type", "") == "spit" and distance_to_survivor < float(ability["keep_distance"])


## 매 프레임: 다시 쓰기 시간이 차면 침·비명
func update(zombie: Zombie, delta: float) -> void:
	var ability: Dictionary = zombie.info["ability"]
	zombie.ability_cooldown -= delta
	if zombie.ability_cooldown > 0.0 or zombie.is_stunned():
		return
	match String(ability["type"]):
		"spit":
			_try_spit(zombie, ability)
		"scream":
			_scream(zombie, ability)


func on_death(zombie: Zombie) -> void:
	var ability: Dictionary = zombie.info.get("ability", {})
	if ability.get("type", "") != "explode_on_death":
		return
	_context.play_sound("bloater_swell")
	_context.hazards.warn(zombie.position, float(ability["radius"]), float(ability["delay_seconds"]), {
		"type": "explosion",
		"damage": float(ability["survivor_damage"]),
		"zombie_damage": float(ability["zombie_damage"]),
		"push": 8.0,
		"source": "%s 폭발" % zombie.info["name"],
	})


## 진압복 좀비: 앞(바라보는 쪽)에서 날아온 투사체 피해는 줄인다. 근접·장판·독은 그대로 (from 이 없으면 막지 않음)
func damage_multiplier(zombie: Zombie, options: Dictionary) -> float:
	var ability: Dictionary = zombie.info.get("ability", {})
	if ability.get("type", "") != "shield" or not options.has("knockback_from") or not _is_projectile(options):
		return 1.0
	var toward_attacker := (Vector2(options["knockback_from"]) - zombie.position).normalized()
	if zombie.facing.dot(toward_attacker) < float(ability["front_dot"]):
		return 1.0
	_context.effects.burst(zombie.position + zombie.facing * 4.0, SHIELD_SPARK_COLOR, 2, 30.0)
	_context.play_sound("shield_block")
	return float(ability["front_damage_multiplier"])


## 투사체 맞힘은 source 가 투사체 모양 이름(ProjectilePool.LOOKS)이다 — 휘두르기·드론·장판은 막지 않는다
func _is_projectile(options: Dictionary) -> bool:
	return ProjectilePool.LOOKS.has(String(options.get("source", "")))


func _try_spit(zombie: Zombie, ability: Dictionary) -> void:
	var survivor_position := _context.survivor.position
	if zombie.position.distance_to(survivor_position) > float(ability["range"]):
		zombie.ability_cooldown = 0.5   # 멀면 조금 뒤에 다시 본다
		return
	zombie.ability_cooldown = float(ability["every_seconds"])
	# 생존자가 가는 쪽을 조금 앞질러 겨냥 — 가만히 있으면 맞고, 움직이면 피할 수 있게
	var lead := _context.survivor.moving_direction * 12.0
	_context.hazards.spit(zombie.position, survivor_position + lead, float(ability["projectile_speed"]), {
		"radius": float(ability["puddle_radius"]),
		"seconds": float(ability["puddle_seconds"]),
		"damage_per_second": float(ability["puddle_damage_per_second"]),
		"source": "산성 웅덩이",
	})


func _scream(zombie: Zombie, ability: Dictionary) -> void:
	zombie.ability_cooldown = float(ability["every_seconds"])
	var radius := float(ability["radius"])
	for other: Zombie in _context.horde.in_radius(zombie.position, radius):
		other.boost_speed(float(ability["speed_multiplier"]), float(ability["seconds"]))
	_context.effects.ring(zombie.position, radius, SCREAM_RING_COLOR, 0.5)
	_context.play_sound("screamer_scream")
