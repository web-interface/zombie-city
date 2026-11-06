## [파일] scripts/weapons/line_weapon.gd
## [하는 일] 일직선 꿰뚫기 무기: 가장 가까운 좀비 쪽으로 사거리 끝까지 한 줄(beam_count 면 부채꼴로 여러 줄)을 뻗어 줄 위 좀비를 모두 맞힌다 — 소방 호스(look "water", 굵은 파란 물줄기·밀기, 진화 = 3갈래·날려 버림), 테이프 건(look "tape", 묶어 느리게, 진화 = 꽁꽁 멈춤).
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "line" 인 무기로 만든다. 줄 그림은 WeaponVisuals.beam().
## [근거 문서] 14 §2-2 소방 호스·테이프 건, §2-4 고압 방수포·포장 완료, §2-7 (물줄기 = 굵은 파란 선 + 물방울)
class_name LineWeapon
extends Weapon

const MUZZLE_HEIGHT := Vector2(0, -4)


func attack() -> bool:
	var stats := numbers()
	var start := context.survivor.position + MUZZLE_HEIGHT
	var target := context.horde.nearest(context.survivor.position, effective_range())
	if target == null:
		return false
	var aim := (target.position - start).normalized()
	var count := int(stats["beam_count"])
	var spread := deg_to_rad(float(stats["spread_degrees"]))
	for index: int in range(count):
		var offset := 0.0 if count <= 1 else spread * (float(index) / (count - 1) - 0.5)
		_fire_beam(start, aim.rotated(offset), stats)
	play_attack_sound()
	return true


## 줄 위(굵기 width 안)의 좀비를 모두 맞힌다. 칸 나누기로 줄 가운데 둘레만 훑는다.
func _fire_beam(start: Vector2, direction: Vector2, stats: Dictionary) -> void:
	var length := effective_range()
	var finish := start + direction * length
	var width := area_radius(float(stats["width"]))
	var slow_ratio := float(stats["slow_ratio"])
	for zombie: Zombie in context.horde.in_radius(start + direction * length * 0.5, length * 0.5 + width):
		var closest := Geometry2D.get_closest_point_to_segment(zombie.position, start, finish)
		if closest.distance_to(zombie.position) > width + zombie.radius:
			continue
		strike(zombie, float(stats["damage"]), zombie.position - direction, float(stats["knockback"]))
		if slow_ratio < 1.0:
			zombie.slow(slow_ratio, float(stats["slow_seconds"]))
		stun_zombie(zombie, float(stats["stun_seconds"]))
	visuals().beam(start, finish, width, look, is_evolved)
