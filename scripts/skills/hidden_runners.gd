## [파일] scripts/skills/hidden_runners.gd
## [하는 일] 화면을 직접 뛰어다니는 히든 스킬 효과: 만루 홈런(거대한 야구공이 몸에서 사방으로 화면을 가로지르며 닿는 좀비를 날려 버림)과 사냥개 무리(개 여러 마리가 정해진 초 동안 가까운 좀비를 쫓아가 문다 — 조련사 전직은 작게). 움직이고, 맞히고, 빛 층에 그린다.
## [쓰는 곳] scripts/skills/hidden_skill_effects.gd 가 들고 start()·update() 를 부른다. 그리기는 WeaponVisuals 의 glow_drawers 에 스스로 붙어 draw_glow_on() 으로.
## [근거 문서] 14 §3-1 히든 hidden_grand_slam·hidden_pack_hunt, 사냥개 조련사 전직, data/skills.json grand_slam·pack_hunt
class_name HiddenRunners
extends RefCounted

const BALL_COLOR := Color("fbfaf4")
const STITCH_COLOR := Color("e04848")
const BALL_TRAIL_COLOR := Color("ffd166")
const DOG_SEARCH_RADIUS := 160.0      # 개가 쫓을 좀비를 찾는 거리 (화면 안쪽)
const DOG_LEASH_RADIUS := 40.0        # 쫓을 게 없으면 주인 곁 이 거리 안을 돈다
const BARK_EVERY_BITES := 5
const DOG_RELEASE_OFFSET := 6.0       # 풀려날 때 주인 둘레 거리
const DOG_BITE_KNOCKBACK := 4.0
const BALL_SPIN_PER_POINT := 0.08     # 공이 굴러가며 실밥이 도는 빠르기
const BAT_CRACK_PITCH := -0.35        # 배트 소리를 낮게 — "딱!" 대신 "쾅!"
const BALL_TRAIL_SECONDS := 0.35

var _balls: Array[Dictionary] = []
var _dogs: Array[Dictionary] = []
var _bites: int = 0
var _is_drawing_registered: bool = false
var _context: RunContext


func _init(context: RunContext) -> void:
	_context = context


func start(effect: Dictionary) -> void:
	if not _is_drawing_registered:   # 무기 칸(빛 층)이 다 만들어진 뒤라 처음 쓸 때 붙는다
		_context.weapon_rack.visuals.glow_drawers.append(self)
		_is_drawing_registered = true
	match String(effect["type"]):
		"grand_slam":
			_throw_balls(effect)
		"pack_hunt":
			_release_dogs(effect)


func update(delta: float) -> void:
	_update_balls(delta)
	_update_dogs(delta)


## ── 만루 홈런: 가장 가까운 좀비 쪽을 시작으로 사방에 고르게 ──
func _throw_balls(effect: Dictionary) -> void:
	var survivor_position := _context.survivor.position
	var nearest := _context.horde.nearest(survivor_position, DOG_SEARCH_RADIUS)
	var start_angle := (nearest.position - survivor_position).angle() if nearest != null else randf() * TAU
	var count := int(effect["balls"])
	for index: int in range(count):
		var direction := Vector2.from_angle(start_angle + TAU * index / count)
		_balls.append({"position": survivor_position, "velocity": direction * float(effect["speed"]), "distance_left": float(effect["distance"]),
			"radius": float(effect["radius"]), "damage": float(effect["damage"]), "knockback": float(effect["knockback"]), "hit": []})
	_context.camera.add_trauma(float(effect["shake_trauma"]))
	_context.play_sound("axe_swing", BAT_CRACK_PITCH)
	_context.play_sound("explosion")


func _update_balls(delta: float) -> void:
	var write_index := 0
	for ball: Dictionary in _balls:
		var step := Vector2(ball["velocity"]) * delta
		ball["position"] = Vector2(ball["position"]) + step
		ball["distance_left"] = float(ball["distance_left"]) - step.length()
		_hit_with_ball(ball)
		_context.weapon_rack.visuals.add_particle(Vector2(ball["position"]) - step.normalized() * float(ball["radius"]), -step * 2.0, BALL_TRAIL_SECONDS, BALL_TRAIL_COLOR, 0.0)
		if float(ball["distance_left"]) > 0.0:
			_balls[write_index] = ball
			write_index += 1
	_balls.resize(write_index)


func _hit_with_ball(ball: Dictionary) -> void:
	var hit_zombies: Array = ball["hit"]
	var center: Vector2 = ball["position"]
	for zombie: Zombie in _context.horde.in_radius(center, float(ball["radius"])):
		if hit_zombies.has(zombie):
			continue
		hit_zombies.append(zombie)
		var rolled := _context.roll_damage(float(ball["damage"]))
		_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "knockback_from": center, "knockback": float(ball["knockback"]), "source": "skill"})


## ── 사냥개 무리: 주인 둘레에서 풀려나 가장 가까운 좀비를 쫓아 문다 ──
func _release_dogs(effect: Dictionary) -> void:
	var survivor_position := _context.survivor.position
	var count := int(effect["dogs"])
	for index: int in range(count):
		var direction := Vector2.from_angle(TAU * index / count)
		_dogs.append({"position": survivor_position + direction * DOG_RELEASE_OFFSET, "velocity": direction, "time_left": float(effect["seconds"]),
			"speed": float(effect["speed"]), "bite_radius": float(effect["bite_radius"]), "damage": float(effect["damage"]),
			"interval": float(effect["bite_interval_seconds"]), "step": randf()})
	_context.play_sound("hound_bark")


func _update_dogs(delta: float) -> void:
	var write_index := 0
	for dog: Dictionary in _dogs:
		dog["time_left"] = float(dog["time_left"]) - delta
		dog["step"] = float(dog["step"]) + delta
		_move_dog(dog, delta)
		_bite(dog)
		if float(dog["time_left"]) > 0.0:
			_dogs[write_index] = dog
			write_index += 1
	_dogs.resize(write_index)


func _move_dog(dog: Dictionary, delta: float) -> void:
	var dog_position: Vector2 = dog["position"]
	var target := _context.horde.nearest(dog_position, DOG_SEARCH_RADIUS)
	var goal := target.position if target != null else _context.survivor.position + Vector2.from_angle(float(dog["step"])) * DOG_LEASH_RADIUS
	var offset := goal - dog_position
	if offset.length() > 1.0:
		dog["velocity"] = offset.normalized()
	dog["position"] = dog_position + Vector2(dog["velocity"]) * float(dog["speed"]) * delta


## 같은 좀비는 interval 초마다 한 번 (개마다 따로 세면 여섯 마리가 한 마리를 순식간에 지워 버려서 무리 전체가 같은 이름표를 씀)
func _bite(dog: Dictionary) -> void:
	for zombie: Zombie in _context.horde.in_radius(dog["position"], float(dog["bite_radius"])):
		if zombie.try_take_hit_from("pack_hunt", float(dog["interval"])):
			var rolled := _context.roll_damage(float(dog["damage"]))
			_context.horde.hit(zombie, rolled["amount"], {"is_crit": rolled["is_crit"], "knockback_from": dog["position"], "knockback": DOG_BITE_KNOCKBACK, "source": "skill"})
			_bites += 1
			if _bites % BARK_EVERY_BITES == 0:
				_context.play_sound("hound_bark", randf_range(-0.1, 0.15))


## 빛 층에 그린다: 하얀 공 + 빨간 실밥 + 금빛 테두리, 달리는 개
func draw_glow_on(canvas: CanvasItem) -> void:
	for ball: Dictionary in _balls:
		var center := Vector2(ball["position"]).round()
		var radius := float(ball["radius"])
		var spin := float(ball["distance_left"]) * BALL_SPIN_PER_POINT
		canvas.draw_circle(center, radius, BALL_COLOR)
		canvas.draw_arc(center + Vector2(-radius * 0.9, 0.0).rotated(spin), radius * 0.75, spin - 0.9, spin + 0.9, 8, STITCH_COLOR, 1.0)
		canvas.draw_arc(center + Vector2(radius * 0.9, 0.0).rotated(spin), radius * 0.75, spin + PI - 0.9, spin + PI + 0.9, 8, STITCH_COLOR, 1.0)
		canvas.draw_arc(center, radius + 1.0, 0.0, TAU, 24, Color(WeaponVisuals.GOLD, 0.8), 1.0)
	for dog: Dictionary in _dogs:
		OrbitWeapon.draw_dog(canvas, dog["position"], dog["velocity"], float(dog["step"]), Color.WHITE)


## 다음 밤으로 넘어갈 때 달리던 공·개를 거둔다
func clear() -> void:
	_balls.clear()
	_dogs.clear()
