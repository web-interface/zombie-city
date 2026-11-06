## [파일] scripts/systems/boss_moves_demolisher.gd
## [하는 일] 철거반장의 기술 3개: ① 해머 내려찍기 — 가까이 오면 멈춰 빨간 원이 차오른 뒤 쾅(분노하면 더 큰 여진 고리가 두 번 이어짐), ② 땅 가르기 — 생존자 쪽으로 빨간 예고 선 뒤 땅이 갈라짐(분노하면 세 줄), ③ 철근 던지기 — 멀리 있으면 철근을 부채꼴로(분노하면 더 많이). 숫자는 data/zombies.json demolisher.
## [쓰는 곳] scripts/systems/boss_attacks.gd 가 철거반장마다 update() 를 부른다.
## [근거 문서] 14 §1-3 보스, 02 §6 보스(공격 전 예고)
class_name BossMovesDemolisher
extends BossMoves

const SLAM_START_DISTANCE := 40.0      # 이만큼 가까워지면 해머를 든다


func update(boss: Zombie, delta: float) -> void:
	_count_down_hold(boss, delta)
	if _is_busy(boss):
		return
	var is_close := boss.position.distance_to(_context.survivor.position) < SLAM_START_DISTANCE + boss.radius
	if is_close and _is_ready(boss, "slam", delta):
		_slam(boss, boss.info["slam"])
	elif _is_ready(boss, "crack", delta):
		_crack(boss, boss.info["crack"])
	elif _is_ready(boss, "rebar", delta):
		_throw_rebar(boss, boss.info["rebar"])


func _slam(boss: Zombie, slam: Dictionary) -> void:
	var warning := float(slam["warning_seconds"])
	_hold_still(boss, warning)
	var effect := {"type": "slam", "damage": float(slam["hit_damage"]), "push": float(slam["push_distance"]), "source": "%s 해머" % boss.info["name"]}
	_context.hazards.warn(boss.position, float(slam["radius"]), warning, effect)
	if _is_raging(boss):   # 여진: 더 큰 고리가 조금씩 늦게 터짐 — 바깥으로 도망쳐야 함
		for index: int in range(int(slam["rage_aftershocks"])):
			var delay := warning + float(slam["aftershock_delay_seconds"]) * (index + 1)
			_context.hazards.warn(boss.position, float(slam["radius"]) * (1.6 + 0.6 * index), delay, effect)
	_context.play_sound("demolisher_warning")


func _crack(boss: Zombie, crack: Dictionary) -> void:
	var warning := float(crack["warning_seconds"])
	_hold_still(boss, warning)
	var count := int(crack["rage_lines"]) if _is_raging(boss) else 1
	for direction: Vector2 in _fan(_direction_to_survivor(boss), count, float(crack["spread_degrees"])):
		_context.hazards.warn_line(boss.position, boss.position + direction * float(crack["length"]), float(crack["width"]), warning, {
			"type": "line_damage", "damage": float(crack["damage"]), "source": "%s 땅 가르기" % boss.info["name"],
		})
	_context.play_sound("demolisher_warning", 0.1)


func _throw_rebar(boss: Zombie, rebar: Dictionary) -> void:
	if boss.position.distance_to(_context.survivor.position) < float(rebar["min_distance"]):
		return
	var count := int(rebar["rage_count"]) if _is_raging(boss) else int(rebar["count"])
	for direction: Vector2 in _fan(_direction_to_survivor(boss), count, float(rebar["spread_degrees"])):
		_context.hazards.shoot(boss.position, direction * float(rebar["speed"]), float(rebar["damage"]), "%s 철근" % boss.info["name"], "rebar")
	_context.play_sound("axe_swing", -0.3)
