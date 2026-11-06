## [파일] scripts/weapons/projectile_weapon.gd
## [하는 일] 투사체를 쏘는 무기(권총·네일건·주사기 총·상자 던지기): 사거리 안 가장 가까운 좀비를 겨눠 여러 발이면 살짝 퍼지게 쏜다. 관통·독·밀기·튕기기·맞힌 자리 폭발·맞히면 회복은 숫자 표대로(진화 숫자 포함). '배달 라이더' 전직의 +1발도 여기서 더한다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "projectile" 인 무기로 만든다. scripts/weapons/projectile_pool.gd 에 쏜다.
## [근거 문서] 03 §2 무기, 03 §1-2 전직(배달 라이더), 14 §2-2·§2-4
class_name ProjectileWeapon
extends Weapon

const MUZZLE_HEIGHT := Vector2(0, -4)   # 손 높이에서 나가게


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
	var count := int(stats["projectile_count"]) + int(context.survivor.stats.value("extra_projectiles"))
	var spread := deg_to_rad(float(stats["spread_degrees"]))
	var start_angle := aim.angle() - spread * 0.5 * float(count - 1) / maxf(1.0, float(count - 1))
	var step := spread / maxf(1.0, float(count - 1)) if count > 1 else 0.0
	var speed := float(stats["projectile_speed"])
	var life := effective_range() / speed
	for index: int in range(count):
		var direction := Vector2.from_angle(start_angle + step * index)
		context.projectiles.launch(look, context.survivor.position + MUZZLE_HEIGHT, direction * speed, _shot_options(stats, life))
	context.effects.muzzle_flash(context.survivor.position + MUZZLE_HEIGHT, aim)
	play_attack_sound()


## 한 발에 실을 숫자들 (발마다 치명타를 따로 굴린다)
func _shot_options(stats: Dictionary, life: float) -> Dictionary:
	var damage := roll_damage(float(stats["damage"]))
	return {
		"damage": damage["amount"],
		"is_crit": damage["is_crit"],
		"source": weapon_id,
		"is_evolved": is_evolved,
		"pierce": int(stats["pierce"]),
		"life_seconds": life,
		"knockback": float(stats.get("knockback", 1.5)),
		"poison_damage_per_second": float(stats.get("poison_damage_per_second", 0.0)),
		"poison_seconds": float(stats.get("poison_seconds", 0.0)),
		"bounces": int(stats.get("bounces", 0)),
		"bounce_range": float(stats.get("bounce_range", 0.0)),
		"explode_radius": float(stats.get("explode_radius", 0.0)),
		"explode_damage": float(stats.get("explode_damage", 0.0)),
		"heal_on_hit_ratio": float(stats.get("heal_on_hit_ratio", 0.0)),
		"shake_trauma": float(info.get("shake_trauma", 0.0)),
	}
