## [파일] scripts/weapons/projectile_pool.gd
## [하는 일] 날아가는 투사체(총알·못·주사기·산탄) 전부를 한곳에서 움직이고, 좀비와 부딪히면 피해·독·밀기를 주고, 한 번에 그린다. 내 공격은 살짝 투명하게 그려 좀비·경고 표시를 가리지 않게 한다.
## [쓰는 곳] scenes/run.tscn 의 World/Projectiles. 무기(projectile_weapon·spread_weapon)가 launch() 를 부르고 run.gd 가 update() 를 부른다.
## [근거 문서] 03 §2 무기, 13 커뮤니티 조사(후반 화면 가독성), 11 §4·§5
class_name ProjectilePool
extends Node2D

const HIT_RADIUS := 2.0
const OWN_ATTACK_ALPHA := 0.85   # 내 공격 효과는 덜 튀게 (커뮤니티: 후반에 아무것도 안 보임)
## 투사체 모양: 색과 크기(점)
const LOOKS := {
	"pistol": {"color": Color("ffe066"), "size": Vector2(2, 2)},
	"nail_gun": {"color": Color("d8dde6"), "size": Vector2(3, 1)},
	"syringe_gun": {"color": Color("8ff59a"), "size": Vector2(3, 2)},
	"shotgun": {"color": Color("ffb347"), "size": Vector2(1, 1)},
}

var _projectiles: Array[Dictionary] = []
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context
	z_index = 10


## options: damage · is_crit · pierce · life_seconds · knockback · poison_damage_per_second · poison_seconds
func launch(look_name: String, from_position: Vector2, velocity: Vector2, options: Dictionary) -> void:
	var projectile := options.duplicate()
	projectile["look"] = look_name
	projectile["position"] = from_position
	projectile["velocity"] = velocity
	projectile["hit_zombies"] = []
	_projectiles.append(projectile)


func update(delta: float) -> void:
	for projectile: Dictionary in _projectiles:
		projectile["position"] = Vector2(projectile["position"]) + Vector2(projectile["velocity"]) * delta
		projectile["life_seconds"] = float(projectile["life_seconds"]) - delta
		_check_hits(projectile)
	_projectiles.assign(_projectiles.filter(func(projectile: Dictionary) -> bool:
		return float(projectile["life_seconds"]) > 0.0 and int(projectile["pierce"]) >= 0))
	queue_redraw()


func _check_hits(projectile: Dictionary) -> void:
	var hit_zombies: Array = projectile["hit_zombies"]
	for zombie: Zombie in _context.horde.in_radius(projectile["position"], HIT_RADIUS):
		if hit_zombies.has(zombie) or int(projectile["pierce"]) < 0:
			continue
		hit_zombies.append(zombie)
		projectile["pierce"] = int(projectile["pierce"]) - 1
		_context.horde.hit(zombie, float(projectile["damage"]), {
			"is_crit": projectile.get("is_crit", false),
			"knockback_from": Vector2(projectile["position"]) - Vector2(projectile["velocity"]).normalized() * 4.0,
			"knockback": float(projectile.get("knockback", 1.5)),
			"source": projectile["look"],
		})
		if float(projectile.get("poison_damage_per_second", 0.0)) > 0.0:
			var poison_power := float(projectile["poison_damage_per_second"]) * _context.survivor.stats.value("poison_damage_multiplier")
			zombie.apply_poison(poison_power, float(projectile["poison_seconds"]))


func _draw() -> void:
	for projectile: Dictionary in _projectiles:
		var look: Dictionary = LOOKS.get(projectile["look"], LOOKS["pistol"])
		var size: Vector2 = look["size"]
		var draw_position := Vector2(projectile["position"]).round()
		var color: Color = look["color"]
		var trail := draw_position - Vector2(projectile["velocity"]).normalized() * 3.0
		draw_rect(Rect2(trail.round(), Vector2.ONE), Color(color, 0.35))
		draw_rect(Rect2(draw_position - size * 0.5, size), Color(color, OWN_ATTACK_ALPHA))
