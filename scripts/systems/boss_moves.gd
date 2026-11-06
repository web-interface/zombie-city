## [파일] scripts/systems/boss_moves.gd
## [하는 일] 보스 기술 파일들(boss_moves_butcher/demolisher/mother.gd)이 같이 쓰는 바탕: 기술마다 다시 쓰기 시간 세기(분노하면 짧아짐), 분노 여부, 생존자 쪽 방향, 부채꼴로 여러 방향 나누기.
## [쓰는 곳] 보스별 기술 파일이 extends 한다. scripts/systems/boss_attacks.gd 가 보스 종류에 맞는 기술 파일의 update() 를 부른다.
## [근거 문서] 14 §1-3 보스(기술 3개 + 분노), data/zombies.json 보스 칸
class_name BossMoves
extends RefCounted

var _context: RunContext
var _spawner: ZombieSpawner


func setup(context: RunContext, spawner: ZombieSpawner) -> void:
	_context = context
	_spawner = spawner


## 보스 종류별 파일이 채운다: 이번 프레임에 기술을 쓸지 정하고 쓴다
func update(_boss: Zombie, _delta: float) -> void:
	pass


## 기술 시간: boss_state["next_<기술>"] 을 줄이고, 다 되면 다시 채우고 true. 기절 중이면 못 씀.
func _is_ready(boss: Zombie, move_name: String, delta: float) -> bool:
	var state := boss.boss_state
	var key := "next_" + move_name
	state[key] = float(state.get(key, 0.0)) - delta
	if float(state[key]) > 0.0 or boss.is_stunned():
		return false
	var cooldown := float(boss.info[move_name]["every_seconds"])
	if _is_raging(boss):
		cooldown *= float(boss.info["rage"]["cooldown_multiplier"])
	state[key] = cooldown
	return true


func _is_raging(boss: Zombie) -> bool:
	return bool(boss.boss_state.get("is_raging", false))


## 예고·돌진·내려찍기 중 (이동을 멈추고, 다른 기술을 겹쳐 쓰지 않음)
func _is_busy(boss: Zombie) -> bool:
	return bool(boss.boss_state.get("is_warning", false)) or bool(boss.boss_state.get("is_charging", false))


## 예고하는 동안 보스가 멈춰 서 있게
func _hold_still(boss: Zombie, seconds: float) -> void:
	boss.boss_state["is_warning"] = true
	boss.boss_state["warning_left"] = seconds


## 멈춰 선 시간이 끝났나 (돌진처럼 따로 끝내는 기술은 쓰지 않음)
func _count_down_hold(boss: Zombie, delta: float) -> void:
	var state := boss.boss_state
	if bool(state.get("is_warning", false)) and not bool(state.get("is_charge_warning", false)):
		state["warning_left"] = float(state["warning_left"]) - delta
		if float(state["warning_left"]) <= 0.0:
			state["is_warning"] = false


func _direction_to_survivor(boss: Zombie) -> Vector2:
	return (_context.survivor.position - boss.position).normalized()


## 가운데 방향을 기준으로 count 개를 spread_degrees 안에 고르게
func _fan(center_direction: Vector2, count: int, spread_degrees: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if count <= 1:
		directions.append(center_direction)
		return directions
	var spread := deg_to_rad(spread_degrees)
	for index: int in range(count):
		directions.append(center_direction.rotated(-spread * 0.5 + spread * index / (count - 1)))
	return directions
