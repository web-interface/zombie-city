## [파일] scripts/systems/boss_director.gd
## [하는 일] 보스 담당: 시간표(data/spawn_curve.json bosses — 지금 1:30·3:00·4:00)에 보스를 부르고 알림을 띄운다. 도살자 행동 — 걸어오다가 6초마다 멈춰 1초 동안 빨간 예고선을 깜빡인 뒤 그 방향으로 돌진, 부딪히면 큰 피해. 보스를 쓰러뜨리면 보상(카드 한 장 더)을 알린다.
## [쓰는 곳] scenes/run.tscn 의 Systems/BossDirector. run.gd 가 update() 를 부르고 신호를 HUD·레벨 업·기록에 잇는다.
## [근거 문서] 02 §3·§6 보스(공격 전 예고), 03 §6 보스, 13 커뮤니티 조사(배우는 보스·공정한 경고)
class_name BossDirector
extends Node

signal boss_appeared(banner_text: String)
signal boss_defeated(seconds_to_kill: float)

const WARNING_COLOR := Color("ff3b3b")
const WARNING_LINE_LENGTH := 160.0

var _context: RunContext
var _schedule: Array = []
var _next_index: int = 0
var _bosses: Array[Zombie] = []


func setup(context: RunContext) -> void:
	_context = context
	_schedule = GameData.table("spawn_curve")["bosses"]
	_context.horde.zombie_died.connect(_on_zombie_died)


func update(delta: float) -> void:
	if _next_index < _schedule.size() and _context.elapsed_seconds >= float(_schedule[_next_index]["at_second"]):
		_spawn_boss(_schedule[_next_index])
		_next_index += 1
	for boss: Zombie in _bosses:
		if not boss.is_dead:
			_update_charge(boss, delta)


## 보스가 예고·돌진 중인가 (그동안 카드 창을 미룬다)
func is_boss_attacking() -> bool:
	for boss: Zombie in _bosses:
		if not boss.is_dead and (bool(boss.boss_state.get("is_warning", false)) or bool(boss.boss_state.get("is_charging", false))):
			return true
	return false


func alive_boss_count() -> int:
	return _bosses.filter(func(boss: Zombie) -> bool: return not boss.is_dead).size()


func _spawn_boss(plan: Dictionary) -> void:
	var survivor := _context.survivor
	var spot := survivor.position + Vector2.from_angle(randf() * TAU) * float(GameData.table("spawn_curve")["boss_spawn_distance"])
	var boss := _context.horde.spawn(String(plan["kind"]), spot, float(plan["health_multiplier"]))
	# 나타나자마자 돌진하지 않게 (처음 보는 사람도 볼 시간)
	boss.boss_state = {"next_charge_in": float(boss.info["charge"]["first_delay_seconds"]), "spawned_at": _context.elapsed_seconds}
	_bosses.append(boss)
	boss_appeared.emit(String(plan["banner"]))
	_context.play_sound("boss_roar")
	_context.shake("boss_charge")


## 걷기 → (예고) 멈춰서 빨간 선 깜빡임 → (돌진) 그 방향으로 빠르게 → 걷기
func _update_charge(boss: Zombie, delta: float) -> void:
	var charge: Dictionary = boss.info["charge"]
	var state := boss.boss_state
	if bool(state.get("is_charging", false)):
		_continue_charge(boss, charge, delta)
		return
	if bool(state.get("is_warning", false)):
		state["warning_left"] = float(state["warning_left"]) - delta
		if float(state["warning_left"]) <= 0.0:
			state["is_warning"] = false
			state["is_charging"] = true
			state["charge_left"] = float(charge["duration_seconds"])
			state["has_hit"] = false
			_context.shake("boss_charge")
		return
	state["next_charge_in"] = float(state["next_charge_in"]) - delta
	if float(state["next_charge_in"]) <= 0.0 and not boss.is_stunned():
		_start_warning(boss, charge)


func _start_warning(boss: Zombie, charge: Dictionary) -> void:
	var state := boss.boss_state
	var direction := (_context.survivor.position - boss.position).normalized()
	state["is_warning"] = true
	state["warning_left"] = float(charge["warning_seconds"])
	state["direction"] = direction
	state["next_charge_in"] = float(charge["every_seconds"])
	boss.facing = direction
	_context.effects.line(boss.position, boss.position + direction * WARNING_LINE_LENGTH, WARNING_COLOR, 3.0, float(charge["warning_seconds"]), true)
	_context.play_sound("boss_warning")


func _continue_charge(boss: Zombie, charge: Dictionary, delta: float) -> void:
	var state := boss.boss_state
	var direction: Vector2 = state["direction"]
	boss.position += direction * float(charge["speed"]) * delta
	boss.position = _context.props.push_out(boss.position, boss.radius)
	state["charge_left"] = float(state["charge_left"]) - delta
	var survivor := _context.survivor
	if not bool(state["has_hit"]) and boss.position.distance_to(survivor.position) < boss.radius + float(charge["hit_margin"]):
		state["has_hit"] = true
		survivor.take_damage(float(charge["hit_damage"]), "%s 돌진" % boss.info["name"])
		survivor.position += direction * float(charge["push_distance"])
		_context.shake("survivor_big_hit")
	if float(state["charge_left"]) <= 0.0:
		state["is_charging"] = false


func _on_zombie_died(zombie: Zombie) -> void:
	if not zombie.is_boss:
		return
	var seconds_to_kill := _context.elapsed_seconds - float(zombie.boss_state.get("spawned_at", 0.0))
	_context.effects.burst(zombie.position, Color("8ff59a"), 24, 70.0)
	_context.shake("boss_kill")
	boss_defeated.emit(seconds_to_kill)
