## [파일] scripts/autoload/scene_router.gd
## [하는 일] 화면(타이틀 → 생존자 고르기 → 한 판 → 결과, 타이틀 → 은신처·도감·업적·순위)을 넘기고, 화면 사이에 넘길 값(고른 생존자·감염도, 오늘의 도전 규칙, 이번 판 목표 3개, 판 결과와 정산)을 들고 다닌다. 판이 끝나면 정산(RunSettlement)을 부르고 저장한다. 명령줄 시험 옵션(자동 플레이·속도·캡처)도 여기서 읽는다.
## [쓰는 곳] 자동 로드 'SceneRouter'. scripts/ui/ 의 화면들, scripts/run/run.gd, scripts/meta/run_modifiers.gd, tools/autoplay.gd 가 쓴다.
## [근거 문서] 11 §3 화면 흐름, 12 §4 돌리는 법, 14 §3·§4
extends Node

const TITLE_SCENE := "res://scenes/title.tscn"
const SURVIVOR_SELECT_SCENE := "res://scenes/survivor_select.tscn"
const RUN_SCENE := "res://scenes/run.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"
const SHELTER_SCENE := "res://scenes/shelter.tscn"
const CODEX_SCENE := "res://scenes/codex.tscn"
const ACHIEVEMENTS_SCENE := "res://scenes/achievements.tscn"
const LEADERBOARD_SCENE := "res://scenes/leaderboard.tscn"

## 고르기 화면에서 고른 생존자 (data/survivors.json 의 이름)
var selected_survivor_id: String = "police"
## 고른 감염도 0~10 (판 쪽은 RunModifiers.run_multipliers() 로 배율을 읽음)
var selected_infection_level: int = 0
## 오늘의 도전 판인가, 그 규칙 (DailyChallenge.rule_for — run_multiply·survivor_modifier·cards_per_level_up …)
var is_daily_challenge: bool = false
var daily_rule: Dictionary = {}
## 이번 판 작은 목표 3개 [{"id", "text", "scrap", "conditions"}] — 판을 시작할 때 뽑음 (판 중 HUD 표시는 판 쪽)
var current_run_goals: Array[Dictionary] = []
## 방금 끝난 판의 기록 (결과 화면이 보여 줌)
var last_run_result: Dictionary = {}
## 방금 끝난 판의 정산 (고철·새 기록·업적·해금·아까운 표시 — RunSettlement.settle)
var last_settlement: Dictionary = {}
## 명령줄 '-- --autoplay=보통 --survivor=police --runs=20 --speed=8 ...' 에서 읽은 시험 옵션
var test_options: Dictionary = {}
## 이어하기·다시 하기로 열 판 상태 (RunSave 와 같은 모양 — NightCarry 가 판을 열 때 한 번 가져감)
var resume_state: Dictionary = {}
## 자동 플레이로 지금까지 끝낸 판 수
var finished_test_runs: int = 0
## 첫 판 안내("끌어서 움직여요")를 이미 봤나 — 저장에 남겨 다음에 켤 때도 다시 안 나오게
var has_seen_first_run_hints: bool:
	get:
		return SaveData.flag("seen_first_run_hints")
	set(value):
		SaveData.set_flag("seen_first_run_hints", value)


func _ready() -> void:
	test_options = _read_test_options()
	if test_options.has("speed"):
		Engine.time_scale = float(test_options["speed"])
	if test_options.has("survivor"):
		selected_survivor_id = String(test_options["survivor"])
	if test_options.has("infection"):
		selected_infection_level = int(test_options["infection"])
	else:
		selected_infection_level = mini(int(SaveData.setting("last_infection_level")), Infection.unlocked_level())
	if test_options.has("daily"):
		_load_daily_challenge()   # 시험 봇으로 오늘의 도전 규칙을 돌려 볼 때 (--daily)


func is_autoplay() -> bool:
	return test_options.has("autoplay")


func go_to_title() -> void:
	_change_scene(TITLE_SCENE)


func go_to_survivor_select() -> void:
	is_daily_challenge = false
	_change_scene(SURVIVOR_SELECT_SCENE)


func go_to_shelter() -> void:
	_change_scene(SHELTER_SCENE)


func go_to_codex() -> void:
	_change_scene(CODEX_SCENE)


func go_to_achievements() -> void:
	_change_scene(ACHIEVEMENTS_SCENE)


func go_to_leaderboard() -> void:
	_change_scene(LEADERBOARD_SCENE)


## 보통 판 시작 (생존자 고르기 → 출동). 고른 감염도는 다음에 켤 때도 그대로 고르게 저장.
func start_run(survivor_id: String) -> void:
	selected_survivor_id = survivor_id
	is_daily_challenge = false
	daily_rule = {}
	SaveData.set_setting("last_infection_level", selected_infection_level)
	var random := RandomNumberGenerator.new()
	random.randomize()
	current_run_goals = RunGoals.pick(random)
	_change_scene(RUN_SCENE)


## 오늘의 도전: 날짜로 정한 생존자·규칙, 감염도 0, 목표도 날짜 씨앗 (누구나 같은 조건)
func start_daily_challenge() -> void:
	_load_daily_challenge()
	_change_scene(RUN_SCENE)


## 타이틀 [이어하기]: 저장된 밤 처음부터 (문서 15 §2)
func continue_run() -> void:
	var state := RunSave.read()
	if not state.is_empty():
		resume_night(state)


## 저장된 밤(state)을 처음부터 연다 — 이어하기·'이 밤 다시 하기'
func resume_night(state: Dictionary) -> void:
	selected_survivor_id = String(state.get("survivor_id", selected_survivor_id))
	selected_infection_level = int(state.get("infection_level", 0))
	daily_rule = state.get("daily_rule", {})
	is_daily_challenge = not daily_rule.is_empty()
	current_run_goals.assign(state.get("run_goals", []))
	resume_state = state
	_change_scene(RUN_SCENE)


func take_resume_state() -> Dictionary:
	var state := resume_state
	resume_state = {}
	return state


## 결과 화면 [바로 다시]: 방금 판과 같은 조건으로 (오늘의 도전이었으면 오늘의 도전 다시)
func restart_same_run() -> void:
	if is_daily_challenge:
		start_daily_challenge()
	else:
		start_run(selected_survivor_id)


## 판이 끝나면 run.gd 가 부른다. 정산·저장 뒤 결과 화면으로. 자동 플레이 중이면 정해진 판 수만큼 바로 다음 판을 시작한다.
func finish_run(result: Dictionary) -> void:
	if not result.has("infection_level"):
		result["infection_level"] = selected_infection_level
	if not result.has("daily_challenge"):
		result["daily_challenge"] = is_daily_challenge
	last_run_result = result
	last_settlement = RunSettlement.settle(result, current_run_goals)
	get_tree().paused = false
	if is_autoplay():
		finished_test_runs += 1
		var wanted_runs := int(test_options.get("runs", 1))
		if finished_test_runs >= wanted_runs:
			_quit_quietly()
			return
		get_tree().change_scene_to_file(RUN_SCENE)
		return
	get_tree().change_scene_to_file(RESULT_SCENE)


func _load_daily_challenge() -> void:
	var today := DailyChallenge.today_key()
	selected_survivor_id = DailyChallenge.survivor_for(today)
	selected_infection_level = 0
	is_daily_challenge = true
	daily_rule = DailyChallenge.rule_for(today)
	current_run_goals = RunGoals.pick(DailyChallenge.random_for(today))


func _change_scene(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


## 소리를 모두 멈추고 한 프레임 뒤에 끈다 (재생 중인 소리 때문에 '자원이 남음' 경고가 뜨지 않게 — 검수 지적)
func _quit_quietly() -> void:
	SoundPlayer.stop_everything()
	await get_tree().process_frame
	get_tree().quit()


func _read_test_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var pair := argument.substr(2).split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else "true"
	return options
