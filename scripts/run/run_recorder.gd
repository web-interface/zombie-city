## [파일] scripts/run/run_recorder.gd
## [하는 일] 한 판 기록 담당: 결과 화면에 보여 줄 것(버틴 시간·처치·레벨·전직·무엇에 당했나)과 난이도 테스터가 쓸 재미 지표(레벨 업 간격, 아슬아슬하게 산 횟수, 분당 처치, 화면 좀비 수, 보스 처치 시간, 전직 전후 처치 속도, 탈출 때 맞았나, 지루한 구간)를 모은다. 시험 옵션 --stats=파일 이면 한 줄 JSON 으로 덧붙여 저장한다.
## [쓰는 곳] scenes/run.tscn 의 Systems/RunRecorder. run.gd 가 신호를 잇고 판이 끝나면 build_result() 를 부른다. tools/balance_stats.py 가 저장한 파일을 읽는다.
## [근거 문서] 12 §4 판마다 기록·§5 재미 지표
class_name RunRecorder
extends Node

const NEAR_DEATH_RATIO := 0.3
const RECOVERED_RATIO := 0.5
const BORING_GAP_SECONDS := 20.0

var level_up_times: Array[float] = []
var kills_by_minute: Array[int] = [0, 0, 0, 0, 0, 0]
var max_zombies_after_four_minutes: int = 0
var boss_kill_seconds: Array[float] = []
var chosen_cards: Array[String] = []
var near_death_saves: int = 0
var kills: int = 0
var promotion_second: float = -1.0
var took_damage_while_extracting: bool = false
## 판 동안 가장 낮았던 체력 비율 (위기가 실제로 왔는지 — 난이도 조정용)
var lowest_health_ratio: float = 1.0
var _kill_times: Array[float] = []
var _event_times: Array[float] = [0.0]
var _is_in_danger: bool = false
var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context


func note_kill() -> void:
	kills += 1
	var minute := mini(int(_context.elapsed_seconds / 60.0), kills_by_minute.size() - 1)
	kills_by_minute[minute] += 1
	_kill_times.append(_context.elapsed_seconds)


func note_level_up() -> void:
	level_up_times.append(_context.elapsed_seconds)
	note_event()


func note_event() -> void:
	_event_times.append(_context.elapsed_seconds)


func note_card(card: Dictionary) -> void:
	chosen_cards.append("%s:%s" % [card.get("kind", ""), card.get("id", "")])


func note_boss_kill(seconds_to_kill: float) -> void:
	boss_kill_seconds.append(seconds_to_kill)
	note_event()


func note_promotion(stage: int) -> void:
	if stage == 1:
		promotion_second = _context.elapsed_seconds
	note_event()


func note_survivor_damaged(is_extracting: bool) -> void:
	if is_extracting:
		took_damage_while_extracting = true


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
	if _context.elapsed_seconds >= 240.0:
		max_zombies_after_four_minutes = maxi(max_zombies_after_four_minutes, alive_zombies)


## end_reason: "escaped" · "died" · "helicopter_left" · "gave_up" (결과 화면 문구가 이유마다 다름)
func build_result(end_reason: String, level: int, branch_name: String) -> Dictionary:
	var is_escaped := end_reason == "escaped"
	var result := {
		"end_reason": end_reason,
		"survivor": _context.survivor.survivor_id,
		"branch": branch_name,
		"is_escaped": is_escaped,
		"survived_seconds": snappedf(_context.elapsed_seconds, 0.1),
		"kills": kills,
		"level": level,
		"death_cause": _context.survivor.last_damage_source if end_reason == "died" else "",
		"level_up_times": level_up_times,
		"near_death_saves": near_death_saves,
		"lowest_health_ratio": snappedf(lowest_health_ratio, 0.01),
		"kills_by_minute": kills_by_minute,
		"max_zombies_after_four_minutes": max_zombies_after_four_minutes,
		"boss_kill_seconds": boss_kill_seconds,
		"promotion_kill_speedup": _promotion_kill_speedup(),
		"took_damage_while_extracting": took_damage_while_extracting,
		"boring_gaps": _boring_gap_count(),
		"chosen_cards": chosen_cards,
		"bot": String(SceneRouter.test_options.get("autoplay", "")),
	}
	_save_for_balance_test(result)
	return result


## 전직 뒤 30초 처치 수 ÷ 전 30초 처치 수 (1.3 이상이면 전직이 체감됨)
func _promotion_kill_speedup() -> float:
	if promotion_second < 0.0:
		return 0.0
	var before := _kill_times.filter(func(time: float) -> bool: return time >= promotion_second - 30.0 and time < promotion_second).size()
	var after := _kill_times.filter(func(time: float) -> bool: return time >= promotion_second and time < promotion_second + 30.0).size()
	return snappedf(float(after) / maxf(1.0, float(before)), 0.01)


func _boring_gap_count() -> int:
	var times := _event_times.duplicate()
	times.append(_context.elapsed_seconds)
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
