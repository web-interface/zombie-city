## [파일] scripts/run/night_flow.gd
## [하는 일] 밤과 밤 사이: 헬기를 타면 남은 조각을 경험치로 바꾸고 멈춘 채 '밤 생존' 창을 띄우고, [다음 밤]을 누르면 길거리를 비우고(좀비·구급함·투사체·장판·위험물·잠깐 빛) 시간을 0:00 으로, 체력 회복 + 카드 한 장 더를 준 뒤 다음 밤을 연다. 시험 봇에 --max-nights 가 있으면 그 밤 수에서 판을 끝내게 알린다.
## [쓰는 곳] scripts/run/run.gd 가 자식으로 만들고 setup() 에 판의 부분들을 넘긴다. Extraction.extracted → on_night_survived(), Hud.next_night_requested → start_next_night().
## [근거 문서] 14 §1-1 밤 이어가기·§4 중독 설계(멈출 틈 없이 '다음 밤?')
class_name NightFlow
extends Node

var _context: RunContext
var _hud: Hud
var _recorder: RunRecorder
var _level_up: LevelUp
var _combo: KillCombo
var _night_systems: Array = []   # reset_for_new_night() 를 가진 규칙 담당들 (나오기·이벤트·보스·탈출)


## parts = {"hud", "recorder", "level_up", "combo", "night_systems": [ZombieSpawner, HordeEvents, BossDirector, Extraction]}
func setup(context: RunContext, parts: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_context = context
	_hud = parts["hud"]
	_recorder = parts["recorder"]
	_level_up = parts["level_up"]
	_combo = parts["combo"]
	_night_systems = parts["night_systems"]


## 헬기를 탔다. 판을 끝내야 하면(시험 밤 수 채움) true.
func on_night_survived() -> bool:
	_recorder.note_night_survived()
	_context.shards.cash_in_all()
	_context.play_sound("night_clear")
	var night_limit := int(SceneRouter.test_options.get("max-nights", 0))
	if night_limit > 0 and _recorder.nights_survived >= night_limit:
		return true
	var nights := _context.night_cycle
	get_tree().paused = true
	_hud.open_night_clear({
		"night_name": nights.night_name(), "next_night_name": nights.night_name(nights.night + 1),
		"kills": _recorder.kills, "level": _level_up.level, "best_combo": _combo.best,
		"heal_percent": roundi(nights.heal_ratio_between_nights() * 100.0),
	})
	return false


func start_next_night() -> void:
	_context.night_cycle.advance()
	for system: Object in _night_systems:
		system.call("reset_for_new_night")
	_context.horde.clear_all()
	_context.health_packs.clear()
	_context.projectiles.clear()
	_context.area_effects.clear()
	_context.hazards.clear()
	_context.lighting.clear_temporary_lights()
	_context.elapsed_seconds = 0.0
	_context.survivor.heal(_context.night_cycle.heal_ratio_between_nights())
	_level_up.grant_bonus_choice()
	_hud.show_banner("%s — 좀비가 더 세졌어요" % _context.night_cycle.night_name(), "alert")
	SoundPlayer.start_run_music(_context.night_cycle.night)   # 밤마다 다른 곡
	_context.play_sound("night_start")
