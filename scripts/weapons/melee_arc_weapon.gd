## [파일] scripts/weapons/melee_arc_weapon.gd
## [하는 일] 근접 휘두르기 무기(소방 도끼): 가장 가까운 좀비 쪽 반원(5단계는 그 반대쪽까지) 안의 좀비를 한꺼번에 때리고 밀어낸다. 근처에 좀비가 없으면 휘두르지 않는다. 근접 범위 능력치(철거반 전직)를 반영한다.
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
	var aim := _nearest_direction(nearby)
	var directions: Array[Vector2] = [aim]
	if bool(stats.get("both_sides", false)):
		directions.append(-aim)
	for direction: Vector2 in directions:
		_swing(direction, radius, nearby, stats)
	context.play_sound(String(info["sound"]))
	return true


## 가장 가까운 좀비 쪽. 예전엔 걷는 방향으로 휘둘러서, 물러서며 싸우면 등 뒤로 헛스윙만 했다
## (밸런스 2·3차: 소방관이 도망치는 동안 한 마리도 못 잡고 판 내내 '끼임'). 자동 공격 장르에 맞게 알아서 겨눈다.
func _nearest_direction(nearby: Array[Zombie]) -> Vector2:
	var survivor_position := context.survivor.position
	var nearest := nearby[0]
	for zombie: Zombie in nearby:
		if zombie.position.distance_squared_to(survivor_position) < nearest.position.distance_squared_to(survivor_position):
			nearest = zombie
	var offset := nearest.position - survivor_position
	return offset.normalized() if offset.length() > 0.01 else context.survivor.facing


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
			"knockback": float(stats["knockback"]),
			"source": weapon_id,
		})
