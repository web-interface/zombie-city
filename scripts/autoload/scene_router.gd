## [파일] scripts/autoload/scene_router.gd
## [하는 일] 화면(타이틀 → 생존자 고르기 → 한 판 → 결과)을 넘기고, 화면 사이에 넘길 값(고른 생존자, 판 결과)을 들고 다닌다. 명령줄 시험 옵션(자동 플레이·속도·캡처)도 여기서 읽는다.
## [쓰는 곳] 자동 로드 'SceneRouter'. scripts/ui/title_screen.gd · survivor_select.gd · result_screen.gd, scripts/run/run.gd, tools/autoplay.gd 가 쓴다.
## [근거 문서] 11 §3 화면 흐름, 12 §4 돌리는 법
extends Node

const TITLE_SCENE := "res://scenes/title.tscn"
const SURVIVOR_SELECT_SCENE := "res://scenes/survivor_select.tscn"
const RUN_SCENE := "res://scenes/run.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

## 고르기 화면에서 고른 생존자 (data/survivors.json 의 이름)
var selected_survivor_id: String = "police"
## 방금 끝난 판의 기록 (결과 화면이 보여 줌)
var last_run_result: Dictionary = {}
## 명령줄 '-- --autoplay=보통 --survivor=police --runs=20 --speed=8 ...' 에서 읽은 시험 옵션
var test_options: Dictionary = {}
## 자동 플레이로 지금까지 끝낸 판 수
var finished_test_runs: int = 0


func _ready() -> void:
	test_options = _read_test_options()
	if test_options.has("speed"):
		Engine.time_scale = float(test_options["speed"])
	if test_options.has("survivor"):
		selected_survivor_id = String(test_options["survivor"])


func is_autoplay() -> bool:
	return test_options.has("autoplay")


func go_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func go_to_survivor_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SURVIVOR_SELECT_SCENE)


func start_run(survivor_id: String) -> void:
	selected_survivor_id = survivor_id
	get_tree().paused = false
	get_tree().change_scene_to_file(RUN_SCENE)


## 판이 끝나면 run.gd 가 부른다. 자동 플레이 중이면 정해진 판 수만큼 바로 다음 판을 시작한다.
func finish_run(result: Dictionary) -> void:
	last_run_result = result
	get_tree().paused = false
	if is_autoplay():
		finished_test_runs += 1
		var wanted_runs := int(test_options.get("runs", 1))
		if finished_test_runs >= wanted_runs:
			get_tree().quit()
			return
		get_tree().change_scene_to_file(RUN_SCENE)
		return
	get_tree().change_scene_to_file(RESULT_SCENE)


func _read_test_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var pair := argument.substr(2).split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else "true"
	return options
