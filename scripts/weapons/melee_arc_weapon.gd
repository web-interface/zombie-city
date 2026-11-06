## [파일] scripts/weapons/melee_arc_weapon.gd
## [하는 일] 근접 휘두르기 무기(소방 도끼): 바라보는 방향 반원(5단계는 앞뒤 모두) 안의 좀비를 한꺼번에 때리고 밀어낸다. 근처에 좀비가 없으면 휘두르지 않는다. 근접 범위 능력치(철거반 전직)를 반영한다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "melee_arc" 인 무기로 만든다.
## [근거 문서] 03 §2 무기(소방 도끼), 04 §3 (빨간 호를 그리며 휘두름)
class_name MeleeArcWeapon
extends Weapon

const SWING_COLOR := Color("ff6b4a")
const HALF_ARC_DOT := 0.0   # 바라보는 방향과의 내적이 이 값보다 크면 반원 안 (0 = 앞쪽 180도)


func attack() -> bool:
	var stats := numbers()
	var survivor := context.survivor
	var radius := float(stats["radius"]) * survivor.stats.value("area_multiplier")
	var nearby := context.horde.in_radius(survivor.position, radius)
	if nearby.is_empty():
		return false
	var directions: Array[Vector2] = [survivor.facing]
	if bool(stats.get("both_sides", false)):
		directions.append(-survivor.facing)
	for direction: Vector2 in directions:
		_swing(direction, radius, nearby, stats)
	context.play_sound(String(info["sound"]))
	return true


func _swing(direction: Vector2, radius: float, nearby: Array[Zombie], stats: Dictionary) -> void:
	var survivor_position := context.survivor.position
	context.effects.swing_arc(survivor_position, direction, radius, SWING_COLOR)
	for zombie: Zombie in nearby:
		var to_zombie := (zombie.position - survivor_position).normalized()
		if to_zombie.dot(direction) < HALF_ARC_DOT:
			continue
		var damage := context.roll_damage(float(stats["damage"]))
		context.horde.hit(zombie, damage["amount"], {
			"is_crit": damage["is_crit"],
			"knockback_from": survivor_position,
			"knockback": float(stats.get("knockback", 6.0)),
			"source": weapon_id,
		})
