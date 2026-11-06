## [파일] scripts/run/run_rewards.gd
## [하는 일] 판 중 '받는 맛' 연출과 보상: 정예를 잡으면 금빛 폭죽·흔들림·구급함, 연속 처치가 50·100·200… 에 닿으면 금빛 고리·소리·알림과 조각 보너스. (보물 상자도 여기에 붙는다 — 묶음 2)
## [쓰는 곳] scripts/run/run.gd 가 만들어 좀비 쓰러짐(정예)·KillCombo.milestone_reached 에 잇는다.
## [근거 문서] 14 §1-2 정예·§4 중독 설계(쉴 새 없는 보상·연속 처치)
class_name RunRewards
extends RefCounted

var _context: RunContext
var _hud: Hud


func setup(context: RunContext, hud: Hud) -> void:
	_context = context
	_hud = hud


func on_elite_killed(zombie: Zombie) -> void:
	_context.health_packs.drop_at(zombie.position)
	_context.effects.burst(zombie.position, PixelUi.GOLD, 18, 70.0)
	_context.effects.ring(zombie.position, 20.0, PixelUi.GOLD, 0.4)
	_context.shake("explosion")
	_hud.show_banner("정예 처치!", "good")


func on_combo_milestone(count: int, shard_bonus: int) -> void:
	var survivor_position := _context.survivor.position
	_context.shards.drop(survivor_position, shard_bonus)
	_context.effects.ring(survivor_position, 30.0, PixelUi.GOLD, 0.5)
	SoundPlayer.play_exact("combo_milestone_%d" % _milestone_sound_step(count))   # 50·100·200 차례로 더 화려한 소리
	_hud.show_banner("연속 %d!" % count, "good")


## 연속 소리 단계: 50 → 1, 100 → 2, 200 이상 → 3 (audio/README.md 순서 있는 소리)
func _milestone_sound_step(count: int) -> int:
	if count >= 200:
		return 3
	return 2 if count >= 100 else 1
