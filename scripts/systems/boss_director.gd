## [파일] scripts/systems/boss_director.gd
## [하는 일] 보스 담당: 밤마다 다른 시간표(data/spawn_curve.json bosses_by_night — 0:45·1:35·2:15)에 보스를 부르고 재난문자 알림을 띄운다. 밤이 지날수록 보스 체력·피해가 커진다(night_cycle). 기술·분노는 boss_attacks.gd 에 맡기고 분노 알림을 전한다. 보스를 쓰러뜨리면 보상(카드 한 장 더)을 알린다. 살아 있는 보스 목록을 체력 줄·음악에 알려 준다.
## [쓰는 곳] scenes/run.tscn 의 Systems/BossDirector. run.gd 가 update() 를 부르고 신호를 HUD·레벨 업·기록에 잇는다. 밤이 바뀌면 reset_for_new_night().
## [근거 문서] 14 §1-3 보스, 02 §3·§6 보스(공격 전 예고), 03 §6 보스, 13 커뮤니티 조사(배우는 보스·공정한 경고)
class_name BossDirector
extends Node

signal boss_appeared(banner_text: String)
signal boss_defeated(seconds_to_kill: float, boss_name: String)
signal boss_enraged(banner_text: String)

var _context: RunContext
var _attacks := BossAttacks.new()
var _schedule: Array = []
var _next_index: int = 0
var _bosses: Array[Zombie] = []


func setup(context: RunContext, spawner: ZombieSpawner) -> void:
	_context = context
	_attacks.setup(context, spawner)
	_attacks.enraged.connect(func(banner_text: String) -> void: boss_enraged.emit(banner_text))
	_context.horde.zombie_died.connect(_on_zombie_died)
	reset_for_new_night()


func reset_for_new_night() -> void:
	_schedule = _context.night_cycle.pick_for_night(GameData.table("spawn_curve")["bosses_by_night"])
	_next_index = 0
	_bosses.clear()


func update(delta: float) -> void:
	if _next_index < _schedule.size() and _context.elapsed_seconds >= float(_schedule[_next_index]["at_second"]):
		_spawn_boss(_schedule[_next_index])
		_next_index += 1
	for boss: Zombie in _bosses:
		if not boss.is_dead:
			_attacks.update(boss, delta)


## 보스가 예고·돌진·내려찍기 중인가 (그동안 카드 창을 미룬다)
func is_boss_attacking() -> bool:
	for boss: Zombie in _bosses:
		if not boss.is_dead and _attacks.is_attacking(boss):
			return true
	return false


func alive_boss_count() -> int:
	return alive_bosses().size()


## 살아 있는 보스들 (나온 차례) — 화면 위 보스 체력 줄이 읽는다
func alive_bosses() -> Array[Zombie]:
	var alive: Array[Zombie] = []
	for boss: Zombie in _bosses:
		if not boss.is_dead:
			alive.append(boss)
	return alive


func is_any_boss_raging() -> bool:
	for boss: Zombie in _bosses:
		if not boss.is_dead and _attacks.is_raging(boss):
			return true
	return false


func _spawn_boss(plan: Dictionary) -> void:
	var nights := _context.night_cycle
	var spot := _context.survivor.position + Vector2.from_angle(randf() * TAU) * float(GameData.table("spawn_curve")["boss_spawn_distance"])
	var boss := _context.horde.spawn(String(plan["kind"]), spot, float(plan["health_multiplier"]) * nights.boss_health_multiplier())
	boss.contact_damage_per_second *= nights.contact_damage_multiplier()
	boss.boss_state = _attacks.init_state(boss)
	_bosses.append(boss)
	boss_appeared.emit(String(plan["banner"]))
	_context.play_sound("boss_roar")
	_context.shake("boss_charge")


func _on_zombie_died(zombie: Zombie) -> void:
	if not zombie.is_boss:
		return
	var seconds_to_kill := _context.elapsed_seconds - float(zombie.boss_state.get("spawned_at", 0.0))
	_context.effects.burst(zombie.position, Color("8ff59a"), 24, 70.0)
	_context.shake("boss_kill")
	boss_defeated.emit(seconds_to_kill, String(zombie.info["name"]))
