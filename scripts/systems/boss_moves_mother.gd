## [파일] scripts/systems/boss_moves_mother.gd
## [하는 일] 거대 감염체의 기술 3개 + 분노: ① 새끼 낳기 — 몸 둘레에 기어다니는 좀비(분노하면 두 배), ② 산성 비 — 생존자 근처 빨간 원들이 차오른 뒤 웅덩이(분노하면 더 많이), ③ 토하기 — 생존자 쪽 빨간 예고 선 뒤 웅덩이가 줄지어 생김. 분노하면 지나간 자리에 산성이 남는다. 숫자는 data/zombies.json mother.
## [쓰는 곳] scripts/systems/boss_attacks.gd 가 거대 감염체마다 update() 를 부른다.
## [근거 문서] 14 §1-3 보스, 02 §6 보스(공격 전 예고)
class_name BossMovesMother
extends BossMoves

const BROOD_COLOR := Color("b388ff")


func update(boss: Zombie, delta: float) -> void:
	_count_down_hold(boss, delta)
	if _is_raging(boss) and _is_ready(boss, "trail", delta):
		var trail: Dictionary = boss.info["trail"]
		_context.hazards.add_puddle(boss.position, float(trail["radius"]), float(trail["seconds"]), float(trail["damage_per_second"]), "%s 산성 자국" % boss.info["name"])
	if _is_busy(boss):
		return
	if _is_ready(boss, "brood", delta):
		_brood(boss, boss.info["brood"])
	elif _is_ready(boss, "acid_rain", delta):
		_acid_rain(boss, boss.info["acid_rain"])
	elif _is_ready(boss, "vomit", delta):
		_vomit(boss, boss.info["vomit"])


func _brood(boss: Zombie, brood: Dictionary) -> void:
	var count := int(brood["spawn_count"]) * (int(boss.info["rage"]["brood_multiplier"]) if _is_raging(boss) else 1)
	for index: int in range(count):
		var spot := boss.position + Vector2.from_angle(TAU * index / count) * float(brood["spawn_radius"])
		_spawner.spawn_zombie(String(brood["spawn_kind"]), _context.props.push_out(spot, 4.0), false)
	_context.effects.burst(boss.position, BROOD_COLOR, 10, 50.0)
	_context.play_sound("mother_birth")


func _acid_rain(boss: Zombie, rain: Dictionary) -> void:
	var count := int(rain["rage_count"]) if _is_raging(boss) else int(rain["count"])
	var survivor_position := _context.survivor.position
	for index: int in range(count):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, float(rain["offset_max"]))
		_context.hazards.warn(survivor_position + offset, float(rain["radius"]), float(rain["warning_seconds"]), {
			"type": "acid", "source": "산성 비",
			"puddle": {"seconds": float(rain["puddle_seconds"]), "damage_per_second": float(rain["puddle_damage_per_second"])},
		})
	_context.play_sound("mother_screech")


func _vomit(boss: Zombie, vomit: Dictionary) -> void:
	var warning := float(vomit["warning_seconds"])
	_hold_still(boss, warning)
	var target := boss.position + _direction_to_survivor(boss) * float(vomit["length"])
	_context.hazards.warn_line(boss.position, target, float(vomit["width"]), warning, {
		"type": "line_puddles", "count": int(vomit["puddle_count"]), "source": "%s 토사물" % boss.info["name"],
		"puddle": {"radius": float(vomit["puddle_radius"]), "seconds": float(vomit["puddle_seconds"]), "damage_per_second": float(vomit["puddle_damage_per_second"])},
	})
	_context.play_sound("mother_screech", -0.15)
