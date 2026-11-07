## [파일] scripts/weapons/melee_arc_weapon.gd
## [하는 일] 근접 휘두르기 무기(소방 도끼·구조용 절단기·야구 배트): 가장 가까운 좀비 쪽 반원(both_sides 면 그 반대쪽까지 = 몸 둘레 전체) 안의 좀비를 한꺼번에 때리고 밀어낸다. 근처에 좀비가 없으면 휘두르지 않는다. 절단기(look "saw")는 빨간 호 대신 불꽃이 튀고, 불도끼(진화)는 휘두른 자리에 불 장판을 남긴다. 배트(look "bat")는 크게 날려 버리고, 홈런왕 배트(진화)는 맞은 좀비를 기절시키며 금빛 충격파. 근접 범위 능력치(철거반 전직·덕트 테이프)를 반영한다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "melee_arc" 인 무기로 만든다.
## [근거 문서] 03 §2 무기(소방 도끼), 04 §3 (빨간 호를 그리며 휘두름), 14 §2-2 절단기·§2-4 불도끼·굴착 톱·§3-1 야구 배트
class_name MeleeArcWeapon
extends Weapon

const SWING_COLOR := Color("ff6b4a")
const SAW_ARC_COLOR := Color("ffd25a")
const BAT_ARC_COLOR := Color("f4f1e6")
const HALF_ARC_DOT := 0.0   # 바라보는 방향과의 내적이 이 값보다 크면 반원 안 (0 = 앞쪽 180도)
const SPARKS_PER_SWING := 4
const FIRE_ZONE_REACH := 0.6   # 불 장판은 휘두른 반경의 이 비율만큼 앞에 깔린다


func attack() -> bool:
	var stats := numbers()
	var survivor := context.survivor
	var radius := area_radius(float(stats["radius"]))
	var nearby := context.horde.in_radius(survivor.position, radius)
	if nearby.is_empty():
		return false
	var aim := _nearest_direction(nearby)
	_swing(aim, radius, nearby, stats)
	if bool(stats.get("both_sides", false)):
		_swing(-aim, radius, nearby, stats)
	play_attack_sound()
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
	_show_swing(survivor_position, direction, radius)
	for zombie: Zombie in nearby:
		var to_zombie := (zombie.position - survivor_position).normalized()
		if to_zombie.dot(direction) < HALF_ARC_DOT:
			continue
		strike(zombie, float(stats["damage"]), survivor_position, float(stats["knockback"]))
		stun_zombie(zombie, float(stats.get("stun_seconds", 0.0)))
	if float(stats.get("fire_zone_radius", 0.0)) > 0.0:
		var fire_center := survivor_position + direction * radius * FIRE_ZONE_REACH
		zones().add_zone("fire", fire_center, area_radius(float(stats["fire_zone_radius"])), float(stats["fire_zone_seconds"]), float(stats["fire_damage_per_second"]), 1.0, 0.0, is_evolved)


## 도끼는 빨간 호(진화하면 금색), 절단기는 노란 호 + 앞쪽으로 튀는 불꽃, 배트는 하얀 호 두 겹(진화하면 금빛 충격파)
func _show_swing(center: Vector2, direction: Vector2, radius: float) -> void:
	if look == "bat":
		context.effects.swing_arc(center, direction, radius, EVOLVED_COLOR if is_evolved else BAT_ARC_COLOR)
		context.effects.swing_arc(center, direction, radius * 0.7, BAT_ARC_COLOR)
		if is_evolved:
			visuals().shockwave(center + direction * radius * 0.6, radius * 0.8, true)
		return
	if look == "saw":
		context.effects.swing_arc(center, direction, radius, EVOLVED_COLOR if is_evolved else SAW_ARC_COLOR)
		visuals().sparks(center + direction * radius * 0.8, direction, SPARKS_PER_SWING)
		return
	context.effects.swing_arc(center, direction, radius, EVOLVED_COLOR if is_evolved else SWING_COLOR)
	if is_evolved:
		context.effects.swing_arc(center, direction, radius + 2.0, SWING_COLOR)
