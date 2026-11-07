## [파일] scripts/meta/run_save.gd
## [하는 일] 30밤 판 이어하기 저장: 밤이 시작될 때마다 판 상태(밤 번호·생존자·들고 간 무기와 레벨·훈장·전직·히든 스킬·남은 다시 하기·감염도·누적 처치/시간)를 user://run_save.json 한 파일에 쓰고, 타이틀 [이어하기]·다시 하기가 읽는다. 판이 끝나면 지운다.
## [쓰는 곳] scripts/run/night_carry.gd 가 write()·clear(), SceneRouter.continue_run() 이 read(), 타이틀 화면이 exists() 를 부른다. 시험 봇(--autoplay)은 --run-save=경로 를 줄 때만 그 파일을 쓴다 (사람 저장을 건드리지 않게).
## [근거 문서] 15 §2 이어하기·다시 하기
class_name RunSave
extends RefCounted

const DEFAULT_PATH := "user://run_save.json"


## 쓸 파일 경로 ("" = 쓰지 않음 — 시험 봇 기본)
static func path() -> String:
	if SceneRouter.test_options.has("run-save"):
		return String(SceneRouter.test_options["run-save"])
	return "" if SceneRouter.is_autoplay() else DEFAULT_PATH


static func exists() -> bool:
	return not path().is_empty() and FileAccess.file_exists(path())


static func write(state: Dictionary) -> void:
	if path().is_empty():
		return
	var file := FileAccess.open(path(), FileAccess.WRITE)
	if file == null:
		push_error("RunSave: '%s' 에 쓸 수 없음 (%s)" % [path(), error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(state))


## 저장된 판 상태. 없거나 깨져 있으면 {} (이어하기 버튼이 안 보이게)
static func read() -> Dictionary:
	if not exists():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path()))
	if not parsed is Dictionary or not Dictionary(parsed).has("night"):
		return {}
	return parsed


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path()))
