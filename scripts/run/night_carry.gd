## [파일] scripts/run/night_carry.gd
## [하는 일] 30밤 판의 밤 사이 성장: 다음 밤으로 넘어갈 때 레벨 1·무기/장비 비움(들고 가는 무기 1개만, 진화는 풀림)·훈장 더하기, 밤 준비 창에 줄 무기·훈장 목록, 밤 시작마다 판 상태 자동 저장, 이어하기·다시 하기(판마다 2번)로 그 밤 처음부터 다시 열기, --start-night=N 시험 상태 만들기. 전직·각성·히든 스킬은 판 끝까지 남는다.
## [쓰는 곳] scripts/run/run.gd 가 만들어 setup() 하고 판이 끝날 때 offer_retry()·on_run_over() 를 부른다. scripts/run/night_flow.gd 가 밤 준비 창 목록(weapon_options·medal_offer)과 begin_night() 를 부른다.
## [근거 문서] 15 §2 한 판 구조(30밤·이어하기·다시 하기)·§5-2 30밤 동안, data/run_rules.json night_carry, data/medals.json
class_name NightCarry
extends RefCounted

var medals := Medals.new()
var retries_left: int = 0
var _context: RunContext
var _level_up: LevelUp
var _promotion: Promotion
var _skill_runner: SkillRunner
var _recorder: RunRecorder
var _hud: Hud
var _night_flow: NightFlow
var _end_run: Callable
var _night_start_state: Dictionary = {}   # 이 밤이 시작될 때 상태 (다시 하기가 여기로 돌아감)
var _failed_reason: String = ""           # 다시 하기 창에서 [그만하기]를 누를 때 끝낼 이유


## parts = {"level_up", "promotion", "skill_runner", "recorder", "hud", "night_flow", "end_run": run.gd 의 _end_run(이유)}
func setup(context: RunContext, parts: Dictionary) -> void:
	_context = context
	_level_up = parts["level_up"]
	_promotion = parts["promotion"]
	_skill_runner = parts["skill_runner"]
	_recorder = parts["recorder"]
	_hud = parts["hud"]
	_night_flow = parts["night_flow"]
	_end_run = parts["end_run"]
	retries_left = int(GameData.rules("night_carry")["retries_per_run"])
	_hud.retry_decided.connect(_on_retry_decided)
	var state := SceneRouter.take_resume_state()
	var start_night := int(SceneRouter.test_options.get("start-night", 1))
	if state.is_empty() and start_night > 1:
		state = _expected_state(start_night)
	if state.is_empty():
		_save_night_start.call_deferred()
	else:
		_restore(state)


## 밤 준비 창 ①: 들고 갈 수 있는 무기 [{"id", "name", "icon", "level", "is_evolved"}]
func weapon_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for weapon: Weapon in _context.weapon_rack.weapons:
		options.append({"id": weapon.weapon_id, "name": String(weapon.info["name"]), "icon": String(weapon.info["icon"]),
			"level": weapon.level, "is_evolved": weapon.is_evolved})
	return options


## 밤 준비 창 ②: 훈장 3장
func medal_offer() -> Array[Dictionary]:
	return medals.offer(_context.survivor.survivor_id)


## 다음 밤이 시작될 때 (NightFlow.start_next_night): choice = {"weapon_id", "weapon_level", "medal_id"} — 비어 있으면 첫 무기를 그대로
func begin_night(choice: Dictionary) -> void:
	var rack := _context.weapon_rack
	var kept_id := String(choice.get("weapon_id", rack.weapons[0].weapon_id if not rack.weapons.is_empty() else ""))
	var kept_weapon := rack.weapon_of(kept_id)
	var kept_level := int(choice.get("weapon_level", kept_weapon.level if kept_weapon != null else 1))
	_level_up.reset_for_new_night()
	rack.reset_for_new_night(kept_id, kept_level)
	medals.add(String(choice.get("medal_id", "")))
	medals.apply(_context)
	_save_night_start.call_deferred()   # 밤 사이 회복까지 끝난 뒤에 저장
	if SceneRouter.is_autoplay():   # 시험 기록: 밤마다 새로 키우기·들고 가기·훈장이 맞는지 (문서 12 §4)
		print("[밤 시작] %d밤 레벨 %d · 무기 %s · 훈장 %s · 전직 %s · 다시 하기 %d" % [_context.night_cycle.night, _level_up.level,
			rack.weapons.map(func(weapon: Weapon) -> String: return "%s %d단계%s" % [weapon.weapon_id, weapon.level, " 진화" if weapon.is_evolved else ""]),
			medals.owned, _promotion.chosen_branch_id, retries_left])


## 판을 끝내려 할 때 run.gd 가 먼저 묻는다: 쓰러짐·헬기 놓침이고 다시 하기가 남았으면 창을 띄우고 true (판은 멈춘 채 기다림)
func offer_retry(end_reason: String) -> bool:
	if end_reason not in ["died", "helicopter_left"] or retries_left <= 0 or not _failed_reason.is_empty():
		return false
	_failed_reason = end_reason
	_context.survivor.get_tree().paused = true
	_hud.open_retry(retries_left, end_reason)
	return true


## 판이 끝났다: 이어하기 저장을 지우고, 결과에 붙일 것을 돌려준다
func on_run_over() -> Dictionary:
	RunSave.clear()
	return {
		"medals": medals.names(),
		"medal_scrap_bonus_ratio": _context.survivor.stats.value("run_scrap_bonus_ratio"),
		"night_retries_left": retries_left,
	}


func _on_retry_decided(is_retry: bool) -> void:
	if not is_retry:
		_context.survivor.get_tree().paused = false
		_end_run.call(_failed_reason)
		return
	var state := _night_start_state.duplicate(true)
	state["retries_left"] = retries_left - 1
	RunSave.write(state)   # 다시 하기를 고른 순간 써 둔다 (껐다 켜서 횟수를 되돌리지 못하게)
	SceneRouter.resume_night(state)


func _save_night_start() -> void:
	_night_start_state = _snapshot()
	RunSave.write(_night_start_state)


## 지금(밤 시작) 판 상태 — 저장 파일에 그대로 들어간다
func _snapshot() -> Dictionary:
	var rack := _context.weapon_rack
	var first_weapon: Weapon = rack.weapons[0] if not rack.weapons.is_empty() else null
	return {
		"survivor_id": _context.survivor.survivor_id, "night": _context.night_cycle.night,
		"weapon_id": first_weapon.weapon_id if first_weapon != null else "", "weapon_level": first_weapon.level if first_weapon != null else 1,
		"medals": medals.owned.duplicate(), "branch_id": _promotion.chosen_branch_id, "promotion_stage": _promotion.stage,
		"hidden_skill_id": _skill_runner.hidden_skill_id, "hidden_card_used_up": _level_up.deck.is_hidden_card_used_up,
		"retries_left": retries_left, "infection_level": SceneRouter.selected_infection_level,
		"daily_rule": SceneRouter.daily_rule if SceneRouter.is_daily_challenge else {}, "run_goals": SceneRouter.current_run_goals,
		"kills": _recorder.kills, "boss_kills": _recorder.boss_kills, "elite_kills": _recorder.elite_kills,
		"nights_survived": _recorder.nights_survived, "run_seconds": _context.run_seconds,
		"health_ratio": _context.survivor.health_ratio(),
	}


## 저장된 밤 처음으로 판을 맞춘다 (생존자·감염도·목표는 SceneRouter 가 장면을 열기 전에 맞춤)
func _restore(state: Dictionary) -> void:
	retries_left = int(state.get("retries_left", retries_left))
	for medal_id: String in Dictionary(state.get("medals", {})).keys():
		medals.owned[medal_id] = int(state["medals"][medal_id])
	_promotion.restore(String(state.get("branch_id", "")), int(state.get("promotion_stage", 0)))
	var hidden_skill_id := String(state.get("hidden_skill_id", ""))
	if not hidden_skill_id.is_empty():
		_skill_runner.set_hidden_skill(hidden_skill_id)
		_recorder.hidden_skill = hidden_skill_id
	_level_up.deck.is_hidden_card_used_up = bool(state.get("hidden_card_used_up", false)) or not hidden_skill_id.is_empty()
	_recorder.kills = int(state.get("kills", 0))
	_recorder.boss_kills = int(state.get("boss_kills", 0))
	_recorder.elite_kills = int(state.get("elite_kills", 0))
	_recorder.nights_survived = int(state.get("nights_survived", 0))
	_context.run_seconds = float(state.get("run_seconds", 0.0))
	var weapon_choice := {"weapon_id": String(state.get("weapon_id", "")), "weapon_level": int(state.get("weapon_level", 1))}
	var night := int(state.get("night", 1))
	if night > 1:
		_context.night_cycle.night = night - 1
		_night_flow.start_next_night(weapon_choice)   # 그 밤의 날씨·음악·좀비 시간표까지 보통 밤 넘김과 똑같이
	else:
		begin_night(weapon_choice)
	var survivor := _context.survivor
	survivor.health = survivor.stats.value("max_health") * clampf(float(state.get("health_ratio", 1.0)), 0.05, 1.0)


## --start-night=N 시험: 그 밤에 와 있을 법한 상태 (들고 간 무기 = 시작 무기, 레벨 = 그 전 밤 최대, 훈장 N−1장 무작위, 전직 1차)
func _expected_state(night: int) -> Dictionary:
	var state := _snapshot()
	state["night"] = night
	state["weapon_level"] = WeaponGrowth.night_max_level(night - 1)
	var test_medals := Medals.new()
	test_medals.add_random(night - 1, _context.survivor.survivor_id)
	state["medals"] = test_medals.owned
	var branches: Array = GameData.entry("survivors", _context.survivor.survivor_id)["branches"]
	var branch_option := String(SceneRouter.test_options.get("branch", "random"))
	state["branch_id"] = branch_option if branches.has(branch_option) else String(branches.pick_random())
	state["promotion_stage"] = 1
	state["nights_survived"] = night - 1
	return state
