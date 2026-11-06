## [파일] scripts/run/time_effects.gd
## [하는 일] 손맛용 시간 연출: 잠깐 멈춤(빠르기 0)과 느린 화면(빠르기 0.3)을 정해진 실제 시간 동안 건다. 여러 개가 겹치면 그중 가장 느린 것을 따르고, 하나가 끝나도 남은 것은 이어진다. 장면이 닫히면 원래 빠르기로 돌려놓는다.
## [쓰는 곳] scripts/run/run.gd 가 자식으로 만들어 큰 피해·보스 처치·쓰러짐·연속 처치 때 play() 를 부른다(await 가능).
## [근거 문서] 02 §12 손맛, 13 조사 반영(맞을 때 잠깐 멈춤), 마지막 검수(짧은 멈춤이 느린 화면을 끊어 먹던 것)
class_name TimeEffects
extends Node

var _base_time_scale: float = 1.0
var _active: Array[Dictionary] = []   # 지금 걸려 있는 멈춤·느린 화면들 {scale}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_time_scale = Engine.time_scale


## seconds 동안 speed_scale(0 = 멈춤). 실제 시간으로 잰다 (게임 시간은 멈춰 있으니까). 자동 플레이 시험에선 건너뜀.
func play(seconds: float, speed_scale: float) -> void:
	if SceneRouter.is_autoplay() or seconds <= 0.0:
		return
	var effect := {"scale": maxf(speed_scale, 0.01)}
	_active.append(effect)
	_apply_slowest()
	await get_tree().create_timer(seconds, true, false, true).timeout
	_active.erase(effect)
	_apply_slowest()


func clear() -> void:
	_active.clear()
	Engine.time_scale = _base_time_scale


func _apply_slowest() -> void:
	var slowest := 1.0
	for effect: Dictionary in _active:
		slowest = minf(slowest, float(effect["scale"]))
	Engine.time_scale = _base_time_scale * slowest


## 장면이 다른 길로 닫혀도 느린 화면이 다음 화면까지 남지 않게 (검수 지적 — 보험)
func _exit_tree() -> void:
	clear()
