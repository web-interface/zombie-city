## [파일] scripts/run/night_flow.gd
## [하는 일] 밤과 밤 사이: 헬기를 타면 남은 조각을 경험치로 바꾸고 멈춘 채 '밤 생존' 창을 띄우고(마지막 밤을 넘기면 도시 탈출로 판 끝), [다음 밤] 뒤 밤 준비 창(들고 갈 무기·훈장)을 고르면 레벨 1·칸 비우기(NightCarry) 뒤 길거리를 비우고(좀비·구급함·투사체·장판·위험물·잠깐 빛) 시간을 0:00 으로, 체력 회복 + 카드 한 장 더를 준 뒤 그 밤의 분위기(날씨·어둠 색·음악)로 다음 밤을 연다. 시험 봇에 --max-nights 가 있으면 그 밤 수에서 판을 끝내게 알린다.
## [쓰는 곳] scripts/run/run.gd 가 자식으로 만들고 setup() 에 판의 부분들을 넘긴다. Extraction.extracted → on_night_survived(), Hud.next_night_requested → start_next_night().
## [근거 문서] 14 §1-1 밤 이어가기·§4 중독 설계(멈출 틈 없이 '다음 밤?'), 15 §2 한 판 구조(30밤)
class_name NightFlow
extends Node

var _context: RunContext
var _hud: Hud
var _recorder: RunRecorder
var _level_up: LevelUp
var _combo: KillCombo
var _rewards: RunRewards
var _skill_runner: SkillRunner
var _night_systems: Array = []   # reset_for_new_night() 를 가진 규칙 담당들 (나오기·이벤트·보스·탈출)
var _carry: NightCarry


## parts = {"hud", "recorder", "level_up", "combo", "rewards", "skill_runner", "carry", "night_systems": [ZombieSpawner, HordeEvents, BossDirector, Extraction]}
func setup(context: RunContext, parts: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_context = context
	_hud = parts["hud"]
	_recorder = parts["recorder"]
	_level_up = parts["level_up"]
	_combo = parts["combo"]
	_rewards = parts["rewards"]
	_skill_runner = parts["skill_runner"]
	_night_systems = parts["night_systems"]
	_carry = parts["carry"]
	_hud.night_prep_requested.connect(func() -> void: _hud.open_night_prep(_carry.weapon_options(), _carry.medal_offer()))


## 헬기를 탔다. 판을 끝내야 하면 끝낼 이유("escaped" 마지막 밤 생존 · "test_night_limit" 시험 밤 수), 아니면 "".
func on_night_survived() -> String:
	_recorder.note_night_survived()
	_context.shards.cash_in_all()
	_context.play_sound("night_clear")
	if _context.night_cycle.night >= int(GameData.rules("night_carry")["final_night"]):
		_hud.show_banner("새벽시를 탈출했어요!", "good")
		return "escaped"
	var night_limit := int(SceneRouter.test_options.get("max-nights", 0))
	if night_limit > 0 and _recorder.nights_survived >= night_limit:
		return "test_night_limit"
	var nights := _context.night_cycle
	get_tree().paused = true
	_hud.open_night_clear({
		"night_name": nights.night_name(), "next_night_name": nights.night_name(nights.night + 1),
		"kills": _recorder.kills, "level": _level_up.level, "best_combo": _combo.best,
		"heal_percent": roundi(nights.heal_ratio_between_nights() * 100.0),
	})
	return ""


## choice = 밤 준비 창에서 고른 것 {"weapon_id", "weapon_level", "medal_id"} (NightCarry.begin_night)
func start_next_night(choice: Dictionary = {}) -> void:
	_context.night_cycle.advance()
	for system: Object in _night_systems:
		system.call("reset_for_new_night")
	_context.horde.clear_all()
	_context.health_packs.clear()
	_rewards.add_pending_chests(_context.pickups.take_chests())   # 바닥 상자는 사라지지 않고 쌓아 둠
	_context.pickups.clear()
	_skill_runner.clear_lingering_effects()
	_context.projectiles.clear()
	_context.weapon_rack.zones.clear()   # 무기가 깔아 둔 연기·불 장판
	for weapon: Weapon in _context.weapon_rack.weapons:
		if weapon is LobAreaWeapon:
			(weapon as LobAreaWeapon).clear_flights()   # 날아가던 화염병·최루탄
	_context.area_effects.clear()
	_context.hazards.clear()
	_context.lighting.clear_temporary_lights()
	_context.elapsed_seconds = 0.0
	_carry.begin_night(choice)   # 레벨 1·무기/장비 비움(들고 가는 무기 1개)·훈장 (문서 15 §2)
	_context.survivor.heal(_context.night_cycle.heal_ratio_between_nights())
	_level_up.grant_bonus_choice()
	var theme := _context.night_cycle.theme()
	_context.weather.apply_theme(theme)
	_hud.show_banner("%s — %s. 좀비가 더 세졌어요" % [_context.night_cycle.night_name(), theme["name"]], "alert")
	SoundPlayer.start_run_music(_context.night_cycle.night)   # 밤마다 다른 곡
	_context.play_sound("night_start")
