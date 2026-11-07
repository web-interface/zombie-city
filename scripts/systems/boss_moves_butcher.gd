## [파일] scripts/systems/boss_moves_butcher.gd
## [하는 일] 도살자의 기술 3개: ① 돌진 — 빨간 예고선 뒤 그 방향으로 달려들어 크게 침(분노하면 두 번 이어서), ② 식칼 던지기 — 멀리 있으면 빙글빙글 도는 식칼(분노하면 세 갈래), ③ 부하 부르기 — 울부짖으면 달리는 좀비들이 몰려옴. 숫자는 data/zombies.json butcher.
## [쓰는 곳] scripts/systems/boss_attacks.gd 가 도살자마다 update() 를 부른다.
## [근거 문서] 14 §1-3 보스, 02 §6 보스(공격 전 예고)
class_name BossMovesButcher
extends BossMoves

const WARNING_COLOR := Color("ff3b3b")
const WARNING_LINE_LENGTH := 160.0
const REPEAT_WARNING_SECONDS := 0.6   # 분노 연속 돌진의 두 번째 예고 (짧지만 보임)


func update(boss: Zombie, delta: float) -> void:
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
	if _is_ready(boss, "charge", delta):
		state["charges_left"] = int(charge["rage_repeat"]) - 1 if _is_raging(boss) else 0
		_start_charge_warning(boss, float(charge["warning_seconds"]))
	elif _is_ready(boss, "cleaver", delta):
		_throw_cleavers(boss, boss.info["cleaver"])
	elif _is_ready(boss, "summon", delta):
		_summon(boss, boss.info["summon"])


func _start_charge_warning(boss: Zombie, seconds: float) -> void:
	var state := boss.boss_state
	var direction := _direction_to_survivor(boss)
	state["is_warning"] = true
	state["warning_left"] = seconds
	state["direction"] = direction
	boss.facing = direction
	_context.effects.line(boss.position, boss.position + direction * WARNING_LINE_LENGTH, WARNING_COLOR, 3.0, seconds, true)
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
		survivor.take_damage(float(charge["hit_damage"]), "%s 돌진" % boss.info["name"], boss.position)
		survivor.position += direction * float(charge["push_distance"])
		_context.shake("survivor_big_hit")
	if float(state["charge_left"]) > 0.0:
		return
	state["is_charging"] = false
	if int(state.get("charges_left", 0)) > 0:   # 분노: 숨 돌릴 틈 없이 한 번 더
		state["charges_left"] = int(state["charges_left"]) - 1
		_start_charge_warning(boss, REPEAT_WARNING_SECONDS)


func _throw_cleavers(boss: Zombie, cleaver: Dictionary) -> void:
	if boss.position.distance_to(_context.survivor.position) < float(cleaver["min_distance"]):
		return   # 가까우면 돌진·물기로 충분
	var count := int(cleaver["rage_count"]) if _is_raging(boss) else int(cleaver["count"])
	for direction: Vector2 in _fan(_direction_to_survivor(boss), count, float(cleaver["spread_degrees"])):
		_context.hazards.shoot(boss.position, direction * float(cleaver["speed"]), float(cleaver["damage"]), "%s 식칼" % boss.info["name"], "cleaver")
	_context.play_sound("axe_swing", -0.2)


func _summon(boss: Zombie, summon: Dictionary) -> void:
	var count := int(summon["count"])
	for index: int in range(count):
		var spot := boss.position + Vector2.from_angle(TAU * index / count) * 24.0
		_spawner.spawn_zombie(String(summon["kind"]), _context.props.push_out(spot, 4.0), false)
	_context.effects.ring(boss.position, float(summon["radius"]) * 0.5, WARNING_COLOR, 0.4)
	_context.play_sound("boss_roar", 0.15)
