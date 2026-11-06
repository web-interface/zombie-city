## [파일] scripts/weapons/projectile_weapon.gd
## [하는 일] 투사체를 쏘는 무기(권총·네일건·주사기 총): 사거리 안 가장 가까운 좀비를 겨눠 여러 발이면 살짝 퍼지게 쏜다. 관통·독·밀기는 숫자 표대로. '배달 라이더' 전직의 +1발도 여기서 더한다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "projectile" 인 무기로 만든다. scripts/weapons/projectile_pool.gd 에 쏜다.
## [근거 문서] 03 §2 무기, 03 §1-2 전직(배달 라이더)
class_name ProjectileWeapon
extends Weapon


func attack() -> bool:
	var target := context.horde.nearest(context.survivor.position, effective_range())
	if target == null:
		return false
	var aim := (target.position - context.survivor.position).normalized()
	fire_volley(aim)
	return true


## aim 방향을 가운데로 발 수만큼 퍼뜨려 쏜다.
func fire_volley(aim: Vector2) -> void:
	var stats := numbers()
	var count := int(stats.get("projectile_count", 1)) + int(context.survivor.stats.value("extra_projectiles"))
	var spread := deg_to_rad(float(stats.get("spread_degrees", 0.0)))
	var start_angle := aim.angle() - spread * 0.5 * float(count - 1) / maxf(1.0, float(count - 1))
	var step := spread / maxf(1.0, float(count - 1)) if count > 1 else 0.0
	var speed := float(stats["projectile_speed"])
	var life := effective_range() / speed
	for index: int in range(count):
		var direction := Vector2.from_angle(start_angle + step * index)
		var damage := context.roll_damage(float(stats["damage"]))
		context.projectiles.launch(weapon_id, context.survivor.position + Vector2(0, -4), direction * speed, {
			"damage": damage["amount"],
			"is_crit": damage["is_crit"],
			"pierce": int(stats.get("pierce", 0)),
			"life_seconds": life,
			"knockback": float(stats.get("knockback", 1.5)),
			"poison_damage_per_second": float(stats.get("poison_damage_per_second", 0.0)),
			"poison_seconds": float(stats.get("poison_seconds", 0.0)),
		})
	context.effects.muzzle_flash(context.survivor.position + Vector2(0, -4), aim)
	context.play_sound(String(info["sound"]))
