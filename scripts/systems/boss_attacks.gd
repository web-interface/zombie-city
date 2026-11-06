## [파일] scripts/systems/boss_attacks.gd
## [하는 일] 보스 기술 나눠 주기: 보스가 나타나면 기술마다 처음 기다릴 시간을 정하고(나타나자마자 공격하지 않게), 매 프레임 보스 종류에 맞는 기술 파일(boss_moves_*.gd)을 돌리고, 체력이 절반 밑으로 떨어지면 '분노'(빨라지고 기술이 세짐, 재난문자 알림)로 바꾼다.
## [쓰는 곳] scripts/systems/boss_director.gd 가 보스마다 init_state()·update() 를 부르고 enraged 를 알림으로 잇는다.
## [근거 문서] 14 §1-3 보스(기술 3개 + 분노), 02 §6 보스(공격 전 예고), 13 조사(배우는 보스·공정한 경고)
class_name BossAttacks
extends RefCounted

signal enraged(banner_text: String)

const MOVE_NAMES: Array[String] = ["charge", "cleaver", "summon", "slam", "crack", "rebar", "brood", "acid_rain", "vomit", "trail"]

var _context: RunContext
var _moves_by_kind: Dictionary = {}   # 보스 종류 → 기술 파일


func setup(context: RunContext, spawner: ZombieSpawner) -> void:
	_context = context
	_moves_by_kind = {"butcher": BossMovesButcher.new(), "demolisher": BossMovesDemolisher.new(), "mother": BossMovesMother.new()}
	for moves: BossMoves in _moves_by_kind.values():
		moves.setup(context, spawner)


## 보스가 나타날 때: 기술마다 처음 기다리는 시간 (처음 보는 사람도 볼 시간)
func init_state(boss: Zombie) -> Dictionary:
	var state := {"spawned_at": _context.elapsed_seconds, "is_raging": false}
	for move_name: String in MOVE_NAMES:
		if boss.info.has(move_name):
			state["next_" + move_name] = float(boss.info[move_name].get("first_delay_seconds", 0.0))
	return state


## 예고·돌진·내려찍기 중인가 (그동안 카드 창을 미루고, 무리는 이 보스를 움직이지 않는다)
func is_attacking(boss: Zombie) -> bool:
	var state := boss.boss_state
	return bool(state.get("is_warning", false)) or bool(state.get("is_charging", false))


func is_raging(boss: Zombie) -> bool:
	return bool(boss.boss_state.get("is_raging", false))


func update(boss: Zombie, delta: float) -> void:
	_check_rage(boss)
	var moves: BossMoves = _moves_by_kind.get(boss.kind_id, null)
	if moves != null:
		moves.update(boss, delta)


func _check_rage(boss: Zombie) -> void:
	if is_raging(boss) or not boss.info.has("rage"):
		return
	var rage: Dictionary = boss.info["rage"]
	if boss.health > boss.max_health * float(rage["health_ratio"]):
		return
	boss.boss_state["is_raging"] = true
	boss.move_speed *= float(rage["speed_multiplier"])
	_context.effects.ring(boss.position, 40.0, Color("ff3b3b"), 0.6)
	_context.effects.burst(boss.position, Color("ff5a2a"), 20, 80.0)
	_context.shake("boss_kill")
	_context.play_sound("boss_roar", -0.2)
	enraged.emit(String(rage["banner"]))
