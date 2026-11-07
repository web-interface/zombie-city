## [파일] scripts/run/run_meta_hooks.gd
## [하는 일] 판 밖 성장(은신처·오늘의 도전·설정)을 판 안에 붙인다: 시작 레벨 보너스, 부활(쓰러지면 한 번 일어나 주변 좀비를 밀어냄), 오늘의 도전·이번 판 목표 알림, 진동(맞을 때·보스·레벨 업).
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 하고, 생존자가 쓰러지면 try_revive() 를 먼저 묻는다. 값은 scripts/meta/run_modifiers.gd·haptics.gd, SceneRouter 가 준다.
## [근거 문서] 14 §3 은신처·오늘의 도전·설정, §4 판 목표
class_name RunMetaHooks
extends RefCounted

const REVIVE_HEALTH_RATIO := 0.5
const REVIVE_GUARD_SECONDS := 2.0
const REVIVE_PUSH_RADIUS := 70.0
const REVIVE_STUN_SECONDS := 2.0

var _context: RunContext
var _hud: Hud
var _revives_left: int = 0


func setup(context: RunContext, hud: Hud, level_up: LevelUp, boss_director: BossDirector) -> void:
	_context = context
	_hud = hud
	_revives_left = RunModifiers.revives()
	for index: int in range(RunModifiers.start_level_bonus()):   # 은신처 '시작 레벨'
		level_up.add_experience(level_up.experience_needed() / maxf(context.survivor.stats.value("experience_multiplier"), 0.01))
	context.survivor.damaged.connect(func(_amount: float) -> void: Haptics.on_hit())
	boss_director.boss_appeared.connect(func(_text: String) -> void: Haptics.on_boss())
	level_up.level_changed.connect(func(_level: int) -> void: Haptics.on_level_up())
	_announce_start()


## 쓰러질 때: 부활이 남았으면 일어나서 true (판이 계속됨)
func try_revive() -> bool:
	if _revives_left <= 0:
		return false
	_revives_left -= 1
	var survivor := _context.survivor
	survivor.revive(REVIVE_HEALTH_RATIO, REVIVE_GUARD_SECONDS)
	for zombie: Zombie in _context.horde.in_radius(survivor.position, REVIVE_PUSH_RADIUS):
		zombie.push(zombie.position - survivor.position, 30.0)
		zombie.stun(REVIVE_STUN_SECONDS)
	_context.effects.ring(survivor.position, REVIVE_PUSH_RADIUS, PixelUi.GOOD, 0.6)
	_context.shake("boss_kill")
	_context.play_sound("miracle_chime")
	_hud.show_banner("다시 일어났어요! (부활 남음 %d)" % _revives_left, "good")
	return true


func _announce_start() -> void:
	if SceneRouter.is_daily_challenge and not SceneRouter.daily_rule.is_empty():
		_hud.show_banner("오늘의 도전: %s" % SceneRouter.daily_rule.get("name", ""), "alert")
	elif not SceneRouter.current_run_goals.is_empty():
		var goal_texts: Array[String] = []
		for goal: Dictionary in SceneRouter.current_run_goals:
			goal_texts.append(String(goal.get("text", "")))
		_hud.show_banner("이번 판 목표: %s" % " · ".join(goal_texts), "good")
