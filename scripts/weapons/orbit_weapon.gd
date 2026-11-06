## [파일] scripts/weapons/orbit_weapon.gd
## [하는 일] 몸 주위를 도는 무기(톱날 드론): 드론 여러 대가 생존자 둘레를 돌며 닿는 좀비를 같은 좀비당 hit_interval_seconds 마다 한 번씩 벤다. 드론 그림(돌아가는 2장)도 직접 그린다.
## [쓰는 곳] scripts/weapons/weapon_rack.gd 가 behavior 가 "orbit" 인 무기로 만들고, 그리기 때 draw_on() 을 부른다.
## [근거 문서] 03 §2 무기(톱날 드론), 04 §3 (몸 주위를 도는 작은 드론)
class_name OrbitWeapon
extends Weapon

const DRONE_TEXTURES: Array[Texture2D] = [preload("res://art/sprites/drone_a.png"), preload("res://art/sprites/drone_b.png")]
const DRONE_HIT_RADIUS := 5.0

var _spin_angle: float = 0.0
var _spin_time: float = 0.0


## 드론은 시간마다 쏘는 게 아니라 계속 돌며 닿으면 때린다 — 공통 틀의 다시 공격 시간을 쓰지 않는다.
func update(delta: float) -> void:
	var stats := numbers()
	_spin_angle += float(stats["spin_speed"]) * delta
	_spin_time += delta
	var interval := float(stats["hit_interval_seconds"]) / context.survivor.stats.value("attack_speed_multiplier")
	for drone_position: Vector2 in drone_positions():
		for zombie: Zombie in context.horde.in_radius(drone_position, DRONE_HIT_RADIUS):
			if zombie.try_take_hit_from(weapon_id, interval):
				var damage := context.roll_damage(float(stats["damage"]))
				context.horde.hit(zombie, damage["amount"], {"is_crit": damage["is_crit"], "knockback_from": context.survivor.position, "knockback": 2.0, "source": weapon_id})
				context.play_sound(String(info["sound"]))


func drone_positions() -> Array[Vector2]:
	var stats := numbers()
	var count := int(stats["drone_count"])
	var radius := float(stats["radius"]) * context.survivor.stats.value("area_multiplier")
	var positions: Array[Vector2] = []
	for index: int in range(count):
		positions.append(context.survivor.position + Vector2.from_angle(_spin_angle + TAU * index / count) * radius)
	return positions


func draw_on(canvas: CanvasItem) -> void:
	var texture := DRONE_TEXTURES[int(_spin_time * 14.0) % 2]
	for drone_position: Vector2 in drone_positions():
		canvas.draw_texture(texture, (drone_position - texture.get_size() * 0.5).round())
