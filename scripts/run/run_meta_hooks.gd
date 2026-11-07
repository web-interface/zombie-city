## [파일] scripts/run/run_meta_hooks.gd
## [하는 일] 판 밖 성장(은신처·오늘의 도전·설정)을 판 안에 붙인다: 시작 레벨 보너스, 부활(쓰러지면 한 번 일어나 주변 좀비를 밀어냄), 오늘의 도전·이번 판 목표 알림, 진동(맞을 때·보스·레벨 업).
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 하고, 생존자가 쓰러지면 try_revive() 를 먼저 묻는다. 값은 scripts/meta/run_modifiers.gd·haptics.gd, SceneRouter 가 준다.
## [근거 문서] 14 §3 은신처·오늘의 도전·설정, §4 판 목표
class_name RunMetaHooks
extends RefCounted

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
	var rules: Dictionary = GameData.table("meta_rules")["revive"]
	survivor.revive(float(rules["health_ratio"]), float(rules["guard_seconds"]))
	for zombie: Zombie in _context.horde.in_radius(survivor.position, float(rules["push_radius"])):
		zombie.push(zombie.position - survivor.position, float(rules["push_distance"]))
		zombie.stun(float(rules["stun_seconds"]))
	_context.effects.ring(survivor.position, float(rules["push_radius"]), PixelUi.GOOD, 0.6)
	_context.shake("boss_kill")
	_context.play_sound("miracle_chime")
	_hud.show_banner("다시 일어났어요! (부활 남음 %d)" % _revives_left, "good")
	return true


func _announce_start() -> void:
	if SceneRouter.is_daily_challenge and not SceneRouter.daily_rule.is_empty():
		_hud.show_banner("오늘의 도전: %s" % SceneRouter.daily_rule.get("name", ""), "alert")
	elif not SceneRouter.current_run_goals.is_empty():
		for goal: Dictionary in SceneRouter.current_run_goals:   # 목표마다 띠 하나 (한 띠에 다 넣으면 잘림 — 검수 지적)
			_hud.show_banner("목표: %s" % goal.get("text", ""), "good")
