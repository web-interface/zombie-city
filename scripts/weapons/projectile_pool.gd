## [파일] scripts/weapons/projectile_pool.gd
## [하는 일] 날아가는 투사체(총알·못·주사기·산탄·상자·공·화살·칼) 전부를 한곳에서 움직이고, 좀비와 부딪히면 피해·독·밀기를 주고, 어둠을 받지 않는 빛 층에 한 번에 그린다. 상자는 맞힌 뒤 다음 좀비로 튕기고(bounce), 진화 무기는 맞힌 자리가 터지거나(폭발) 맞힐 때마다 조금 회복한다. 진화 탄은 금색·한 점 더 크게. 내 공격은 살짝 투명하게 그려 좀비·경고 표시를 가리지 않게 한다.
## [쓰는 곳] scenes/run.tscn 의 World/Projectiles. 무기(projectile_weapon·spread_weapon)가 launch() 를 부르고 run.gd 가 update() 를 부른다. 폭발 그림은 WeaponRack.visuals 에 맡긴다.
## [근거 문서] 03 §2 무기, 14 §2-2(상자 던지기 튕김)·§2-4(진화)·§2-7, 13 커뮤니티 조사(후반 화면 가독성), 11 §4·§5
class_name ProjectilePool
extends Node2D

const HIT_RADIUS := 2.0
const OWN_ATTACK_ALPHA := 0.85   # 내 공격 효과는 덜 튀게 (커뮤니티: 후반에 아무것도 안 보임)
const BOUNCE_EXTRA_LIFE := 0.1   # 튕긴 뒤 다음 좀비까지 갈 시간 여유
## 투사체 모양 (look 이름 → 색과 크기(점))
const LOOKS := {
	"bullet": {"color": Color("ffe066"), "size": Vector2(2, 2)},
	"nail": {"color": Color("d8dde6"), "size": Vector2(3, 1)},
	"syringe": {"color": Color("8ff59a"), "size": Vector2(3, 2)},
	"pellet": {"color": Color("fff2b0"), "size": Vector2(1, 1)},
	"box": {"color": Color("c8aa78"), "size": Vector2(3, 3)},
	"ball": {"color": Color("f4f1e6"), "size": Vector2(2, 2)},
}
## 나는 방향으로 누운 긴 투사체 (화살·칼): 색과 길이(점) — 네모로 그리면 비스듬히 날 때 어색해서 선으로
const LINE_LOOKS := {
	"bolt": {"color": Color("cdb27a"), "tip": Color("e3e8f0"), "length": 5.0},
	"knife": {"color": Color("d8dde6"), "tip": Color("ffffff"), "length": 3.0},
}
const SLUG_SIZE := Vector2(4, 3)   # 슬러그 대포(산탄총 진화)의 큰 한 발
const BOX_TAPE_COLOR := Color("e8d9a8")

var _projectiles: Array[Dictionary] = []
var _context: RunContext
var _glow_canvas: Node2D


## 투사체는 밤 어둠을 받지 않는 빛 층에 그린다 (예광탄처럼 — 어둠에 묻혀 상자·금빛 탄환이 안 보였다)
func setup(context: RunContext) -> void:
	_context = context
	z_index = 10
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = WeaponRack.GLOW_LAYER
	glow_layer.follow_viewport_enabled = true
	add_child(glow_layer)
	_glow_canvas = Node2D.new()
	glow_layer.add_child(_glow_canvas)
	_glow_canvas.draw.connect(_draw_projectiles)


## options: damage · is_crit · pierce · life_seconds · knockback · poison_damage_per_second · poison_seconds · source(무기 이름)
## · is_evolved · bounces · bounce_range · explode_radius · explode_damage · heal_on_hit_ratio · shake_trauma
func launch(look_name: String, from_position: Vector2, velocity: Vector2, options: Dictionary) -> void:
	var projectile := options.duplicate()
	projectile["look"] = look_name
	projectile["position"] = from_position
	projectile["velocity"] = velocity
	projectile["hit_zombies"] = []
	_projectiles.append(projectile)


## 다음 밤으로 넘어갈 때 날아가던 것을 비운다
func clear() -> void:
	_projectiles.clear()
	queue_redraw()


func update(delta: float) -> void:
	var write_index := 0
	for projectile: Dictionary in _projectiles:
		projectile["position"] = Vector2(projectile["position"]) + Vector2(projectile["velocity"]) * delta
		projectile["life_seconds"] = float(projectile["life_seconds"]) - delta
		_check_hits(projectile)
		if float(projectile["life_seconds"]) > 0.0 and int(projectile["pierce"]) >= 0:
			_projectiles[write_index] = projectile   # 새 배열을 만들지 않고 그 자리에서 남길 것만 당긴다
			write_index += 1
	_projectiles.resize(write_index)
	_glow_canvas.queue_redraw()


func _check_hits(projectile: Dictionary) -> void:
	var hit_zombies: Array = projectile["hit_zombies"]
	for zombie: Zombie in _context.horde.in_radius(projectile["position"], HIT_RADIUS):
		if hit_zombies.has(zombie) or int(projectile["pierce"]) < 0:
			continue
		hit_zombies.append(zombie)
		_hit_zombie(projectile, zombie)
		if int(projectile.get("bounces", 0)) > 0 and _bounce_to_next(projectile, zombie.position):
			continue   # 튕기면 관통 수를 쓰지 않는다
		projectile["pierce"] = int(projectile["pierce"]) - 1


func _hit_zombie(projectile: Dictionary, zombie: Zombie) -> void:
	_context.horde.hit(zombie, float(projectile["damage"]), {
		"is_crit": projectile.get("is_crit", false),
		"knockback_from": Vector2(projectile["position"]) - Vector2(projectile["velocity"]).normalized() * 4.0,
		"knockback": float(projectile.get("knockback", 1.5)),
		"source": projectile.get("source", projectile["look"]),
	})
	if float(projectile.get("poison_damage_per_second", 0.0)) > 0.0:
		var poison_power := float(projectile["poison_damage_per_second"]) * _context.survivor.stats.value("poison_damage_multiplier")
		zombie.apply_poison(poison_power, float(projectile["poison_seconds"]))
	if float(projectile.get("explode_radius", 0.0)) > 0.0:
		_explode(projectile, zombie.position)
	if float(projectile.get("heal_on_hit_ratio", 0.0)) > 0.0:
		_context.survivor.heal(float(projectile["heal_on_hit_ratio"]))   # 백신 연발: 맞힐 때마다 조금 회복


## 맞힌 자리가 펑 (슬러그 대포·택배 폭탄)
func _explode(projectile: Dictionary, center: Vector2) -> void:
	var radius := float(projectile["explode_radius"]) * _context.survivor.stats.value("area_multiplier")
	var damage := float(projectile["explode_damage"]) * _context.survivor.stats.value("damage_multiplier")
	for zombie: Zombie in _context.horde.in_radius(center, radius):
		_context.horde.hit(zombie, damage, {"knockback_from": center, "knockback": float(projectile.get("knockback", 1.5)), "source": "explosion"})
	_context.weapon_rack.visuals.explosion(center, radius, bool(projectile.get("is_evolved", false)))
	_context.camera.add_trauma(float(projectile.get("shake_trauma", 0.0)))
	_context.play_sound("explosion")


## 가장 가까운, 아직 안 맞힌 좀비 쪽으로 방향을 바꾼다. 없으면 false (그대로 날아가 관통 수를 씀).
func _bounce_to_next(projectile: Dictionary, from_position: Vector2) -> bool:
	var hit_zombies: Array = projectile["hit_zombies"]
	var best: Zombie = null
	var best_distance := float(projectile["bounce_range"])
	for zombie: Zombie in _context.horde.in_radius(from_position, best_distance):
		var distance := zombie.position.distance_to(from_position)
		if distance < best_distance and not hit_zombies.has(zombie):
			best = zombie
			best_distance = distance
	if best == null:
		return false
	var speed := Vector2(projectile["velocity"]).length()
	projectile["velocity"] = (best.position - from_position).normalized() * speed
	projectile["bounces"] = int(projectile["bounces"]) - 1
	projectile["life_seconds"] = maxf(float(projectile["life_seconds"]), best_distance / maxf(speed, 1.0) + BOUNCE_EXTRA_LIFE)
	_context.play_sound("box_toss_thud", 0.15)
	return true


func _draw_projectiles() -> void:
	for projectile: Dictionary in _projectiles:
		var look: Dictionary = LOOKS.get(projectile["look"], LOOKS["bullet"])
		var is_evolved := bool(projectile.get("is_evolved", false))
		var size: Vector2 = look["size"]
		var color: Color = look["color"]
		if is_evolved:   # 진화 탄 = 금색·한 점 더 크게 (문서 14 §2-7)
			color = Weapon.EVOLVED_COLOR
			size = SLUG_SIZE if projectile["look"] == "pellet" else size + Vector2.ONE
		var draw_position := Vector2(projectile["position"]).round()
		var direction := Vector2(projectile["velocity"]).normalized()
		if LINE_LOOKS.has(projectile["look"]):
			_draw_line_projectile(projectile, draw_position, direction, is_evolved)
			continue
		_glow_canvas.draw_rect(Rect2((draw_position - direction * 3.0).round(), Vector2.ONE), Color(color, 0.35))
		if is_evolved:
			_glow_canvas.draw_rect(Rect2((draw_position - direction * 5.0).round(), Vector2.ONE), Color(color, 0.2))
		_glow_canvas.draw_rect(Rect2((draw_position - size * 0.5).round(), size), Color(color, OWN_ATTACK_ALPHA))
		if projectile["look"] == "box":   # 상자 가운데 테이프 한 줄
			_glow_canvas.draw_rect(Rect2((draw_position - Vector2(0.5, size.y * 0.5)).round(), Vector2(1, size.y)), BOX_TAPE_COLOR)


## 화살·칼: 나는 방향으로 누운 선 + 밝은 끝 (진화하면 금색·한 점 길게)
func _draw_line_projectile(projectile: Dictionary, draw_position: Vector2, direction: Vector2, is_evolved: bool) -> void:
	var look: Dictionary = LINE_LOOKS[projectile["look"]]
	var length := float(look["length"]) + (1.0 if is_evolved else 0.0)
	var color: Color = Weapon.EVOLVED_COLOR if is_evolved else look["color"]
	var tail := (draw_position - direction * length).round()
	_glow_canvas.draw_line(tail, draw_position, Color(color, OWN_ATTACK_ALPHA), 1.0)
	_glow_canvas.draw_rect(Rect2(draw_position, Vector2.ONE), look["tip"])
