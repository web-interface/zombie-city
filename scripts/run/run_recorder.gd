## [파일] scripts/run/run_recorder.gd
## [하는 일] 한 판(여러 밤) 기록 담당: 결과 화면에 보여 줄 것(버틴 밤·마지막 밤 시간·처치·보스·정예·최대 연속·레벨·무엇에 당했나·만난 좀비)과 난이도 테스터가 쓸 재미 지표(레벨 업 간격, 아슬아슬하게 산 횟수, 분당 처치, 밤 후반 화면 좀비 수, 보스 처치 시간, 전직 전후 처치 속도, 탈출 때 맞았나, 지루한 구간, 밤마다 생존 시각)를 모은다. 시험 옵션 --stats=파일 이면 한 줄 JSON 으로 덧붙여 저장한다.
## [쓰는 곳] scenes/run.tscn 의 Systems/RunRecorder. run.gd 가 신호를 잇고 판이 끝나면 build_result() 를 부른다. 결과 화면·SaveData(은신처·업적·도감)·tools/balance_stats.py 가 결과를 읽는다.
## [근거 문서] 12 §4 판마다 기록·§5 재미 지표, 14 §1-1 밤 이어가기·§3 결과 사전 키
class_name RunRecorder
extends Node

const NEAR_DEATH_RATIO := 0.3
const RECOVERED_RATIO := 0.5
const BORING_GAP_SECONDS := 20.0
const LATE_NIGHT_SECONDS := 120.0   # '밤 후반 화면 좀비 수' 지표를 재기 시작하는 때 (밤마다 2:00 부터)

var level_up_times: Array[float] = []
var kills_by_minute: Array[int] = [0]
var max_zombies_late_night: int = 0
var boss_kill_seconds: Array[float] = []
var chosen_cards: Array[String] = []
## 진화한 무기의 진화 id 들 (진화한 차례대로) · 고른 히든 스킬 id (없으면 빈 글자)
var evolutions: Array[String] = []
var hidden_skill: String = ""
var near_death_saves: int = 0
var kills: int = 0
var boss_kills: int = 0
var elite_kills: int = 0
var nights_survived: int = 0
## 밤마다 헬기를 탄 때 (판 전체 초)
var night_clear_times: Array[float] = []
var promotion_second: float = -1.0
var took_damage_while_extracting: bool = false
## 판 동안 가장 낮았던 체력 비율 (위기가 실제로 왔는지 — 난이도 조정용)
var lowest_health_ratio: float = 1.0
var _zombie_kinds_met: Dictionary = {}
var _kill_times: Array[float] = []
var _event_times: Array[float] = [0.0]
var _is_in_danger: bool = false
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context


func note_kill(zombie: Zombie) -> void:
	kills += 1
	var minute := int(_context.run_seconds / 60.0)
	while kills_by_minute.size() <= minute:
		kills_by_minute.append(0)
	kills_by_minute[minute] += 1
	_kill_times.append(_context.run_seconds)
	_zombie_kinds_met[zombie.kind_id] = true
	if zombie.is_elite:
		elite_kills += 1


func note_level_up() -> void:
	level_up_times.append(_context.run_seconds)
	note_event()


func note_event() -> void:
	_event_times.append(_context.run_seconds)


func note_card(card: Dictionary) -> void:
	chosen_cards.append("%s:%s" % [card.get("kind", ""), card.get("id", "")])
	match String(card.get("kind", "")):
		"evolution":
			evolutions.append(String(GameData.entry("weapons", String(card["id"]))["evolution"]["id"]))
		"hidden_skill":
			hidden_skill = String(card["id"])


func note_boss_kill(seconds_to_kill: float) -> void:
	boss_kills += 1
	boss_kill_seconds.append(seconds_to_kill)
	note_event()


func note_promotion(stage: int) -> void:
	if stage == 1:
		promotion_second = _context.run_seconds
	note_event()


func note_survivor_damaged(is_extracting: bool) -> void:
	if is_extracting:
		took_damage_while_extracting = true


func note_night_survived() -> void:
	nights_survived += 1
	night_clear_times.append(snappedf(_context.run_seconds, 0.1))
	note_event()


## 매 프레임: 아슬아슬 판정·화면 좀비 수
func sample(alive_zombies: int) -> void:
	var ratio := _context.survivor.health_ratio()
	if not _context.survivor.is_dead:
		lowest_health_ratio = minf(lowest_health_ratio, ratio)
	if ratio < NEAR_DEATH_RATIO and not _context.survivor.is_dead:
		_is_in_danger = true
	elif _is_in_danger and ratio > RECOVERED_RATIO:
		_is_in_danger = false
		near_death_saves += 1
	if _context.elapsed_seconds >= LATE_NIGHT_SECONDS:
		max_zombies_late_night = maxi(max_zombies_late_night, alive_zombies)


## end_reason: "died" · "helicopter_left" · "gave_up" · "test_night_limit"(시험 봇이 정한 밤 수를 넘김)
## 결과 사전 키는 문서 14 §3 (결과 화면·SaveData 가 읽음) — 키를 바꾸면 그쪽도 고친다
func build_result(end_reason: String, level: int, branch_name: String, max_combo: int) -> Dictionary:
	var result := {
		"end_reason": end_reason,
		"survivor": _context.survivor.survivor_id,
		"branch": branch_name,
		"nights_survived": nights_survived,
		"last_night": _context.night_cycle.night,
		"seconds_in_last_night": snappedf(_context.elapsed_seconds, 0.1),
		"total_seconds": snappedf(_context.run_seconds, 0.1),
		"is_escaped": nights_survived >= 1,
		"survived_seconds": snappedf(_context.run_seconds, 0.1),
		"kills": kills,
		"boss_kills": boss_kills,
		"elite_kills": elite_kills,
		"max_combo": max_combo,
		"level": level,
		"death_cause": _context.survivor.last_damage_source if end_reason == "died" else "",
		"zombie_kinds_met": _zombie_kinds_met.keys(),
		"infection_level": int(_router_value("selected_infection_level", 0)),
		"daily_challenge": bool(_router_value("is_daily_challenge", false)),
	}
	result.merge(_balance_metrics())
	_save_for_balance_test(result)
	return result


## 은신처·기록 쪽이 SceneRouter 에 싣는 값(감염도·오늘의 도전) — 아직 없으면 기본값
func _router_value(property_name: String, default_value: Variant) -> Variant:
	var value: Variant = SceneRouter.get(property_name)
	return default_value if value == null else value


## 난이도 테스터용 재미 지표 (문서 12 §5)
func _balance_metrics() -> Dictionary:
	return {
		"night_clear_times": night_clear_times,
		"level_up_times": level_up_times,
		"near_death_saves": near_death_saves,
		"lowest_health_ratio": snappedf(lowest_health_ratio, 0.01),
		"kills_by_minute": kills_by_minute,
		"max_zombies_late_night": max_zombies_late_night,
		"boss_kill_seconds": boss_kill_seconds,
		"promotion_kill_speedup": _promotion_kill_speedup(),
		"took_damage_while_extracting": took_damage_while_extracting,
		"boring_gaps": _boring_gap_count(),
		"chosen_cards": chosen_cards,
		"weapons_final": _final_weapon_ids(),
		"evolutions": evolutions,
		"hidden_skill": hidden_skill,
		"near_miss_texts": _evolution_near_misses(),
		"bot": String(SceneRouter.test_options.get("autoplay", "")),
	}


## 아까운 표시용: 최고 단계까지 키웠는데 짝 장비가 없어서 진화를 못 한 무기 (결과 화면 맨 앞에 — 문서 14 §4)
func _evolution_near_misses() -> Array[String]:
	var texts: Array[String] = []
	var rack := _context.weapon_rack
	for weapon: Weapon in rack.weapons:
		if weapon.can_evolve() and not rack.has_gear(weapon.evolution_gear_id()):
			var gear_name := String(GameData.entry("gear", weapon.evolution_gear_id()).get("name", ""))
			texts.append("%s 진화까지 %s 하나 부족했어요" % [weapon.display_name(), gear_name])
	return texts


## 판 끝에 가진 무기 (진화했으면 진화 id — 어떤 빌드로 끝났나, 문서 14 §2)
func _final_weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	for weapon: Weapon in _context.weapon_rack.weapons:
		ids.append(weapon.final_id())
	return ids


## 전직 뒤 30초 처치 수 ÷ 전 30초 처치 수 (1.3 이상이면 전직이 체감됨)
func _promotion_kill_speedup() -> float:
	if promotion_second < 0.0:
		return 0.0
	var before := _kill_times.filter(func(time: float) -> bool: return time >= promotion_second - 30.0 and time < promotion_second).size()
	var after := _kill_times.filter(func(time: float) -> bool: return time >= promotion_second and time < promotion_second + 30.0).size()
	return snappedf(float(after) / maxf(1.0, float(before)), 0.01)


func _boring_gap_count() -> int:
	var times := _event_times.duplicate()
	times.append(_context.run_seconds)
	times.sort()
	var count := 0
	for index: int in range(1, times.size()):
		if float(times[index]) - float(times[index - 1]) > BORING_GAP_SECONDS:
			count += 1
	return count


func _save_for_balance_test(result: Dictionary) -> void:
	var stats_path := String(SceneRouter.test_options.get("stats", ""))
	if stats_path.is_empty():
		return
	var absolute := ProjectSettings.globalize_path("res://" + stats_path) if not stats_path.contains(":") else stats_path
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.READ_WRITE if FileAccess.file_exists(absolute) else FileAccess.WRITE)
	if file == null:
		push_error("RunRecorder: 기록 파일을 열 수 없음 %s" % absolute)
		return
	file.seek_end()
	file.store_line(JSON.stringify(result))
	file.close()
