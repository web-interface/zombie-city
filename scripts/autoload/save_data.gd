## [파일] scripts/autoload/save_data.gd
## [하는 일] 저장 담당: 고철·은신처 단계·해금·업적·도감·기록·설정·오늘의 도전·누적 숫자를 user://save.json 한 파일에 넣고 꺼낸다. 판 끝·강화·설정을 바꿀 때·앱을 나갈 때 저장하고, 파일이 깨져 있으면 임시 파일 → 예비 파일 → 처음 값 순서로 되살려 게임이 멈추지 않게 한다. 시험 봇(--autoplay)은 저장 파일을 건드리지 않는다 (--save=경로 를 주면 그 시험용 파일만 쓴다).
## [쓰는 곳] 자동 로드 'SaveData'. scripts/meta/*.gd (은신처·감염도·업적·도감·판 정산), scripts/ui/ 의 타이틀·은신처·설정·결과 화면, SceneRouter 가 쓴다. 웹판에서는 user:// 가 브라우저 저장소(IndexedDB)로 남는다.
## [근거 문서] 14 §3 저장, 03 §11, 07 저장, 12 §6 (저장 손실 = 별점 깎이는 이유)
extends Node

## 고철·설정·은신처 단계처럼 화면에 보이는 값이 바뀌었다 (타이틀의 고철 숫자 등을 새로 그림)
signal changed

const SAVE_PATH := "user://save.json"
const BACKUP_SUFFIX := ".backup"
const TEMPORARY_SUFFIX := ".tmp"
const SAVE_VERSION := 1

## 저장 내용 전체. 화면·meta 스크립트는 아래 함수로 읽고 쓰고, 묶음째 다룰 때만 section() 을 쓴다.
var data: Dictionary = {}
var _path: String = SAVE_PATH
var _is_writing_allowed: bool = true
## 켤 때 본 파일이 깨져 있었나 — 깨진 파일을 예비 파일 자리로 옮겨 멀쩡한 예비 파일을 덮지 않게
var _is_main_file_broken: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_choose_path()
	data = _load_first_readable()
	# 자동 로드 순서상 SoundPlayer 가 아직 준비 전이라 한 박자 뒤에 소리 크기를 맞춘다 (SceneRouter 가 저장을 읽어야 해서 저장이 먼저)
	apply_sound_settings.call_deferred()


## 앱을 닫거나 다른 앱으로 갈 때도 저장 (폰은 언제 꺼질지 모름 — 문서 12 §6 저장 손실)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save()


## 지금 내용을 파일에 쓴다. 임시 파일에 다 쓴 뒤에 이름을 바꿔서, 쓰는 도중 꺼져도 예전 파일이 남게 한다.
func save() -> void:
	if not _is_writing_allowed:
		return
	var absolute := _absolute(_path)
	var temporary := absolute + TEMPORARY_SUFFIX
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_error("SaveData: 저장 파일을 쓸 수 없음 %s (%s)" % [temporary, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(absolute) and _is_main_file_broken:
		DirAccess.remove_absolute(absolute)
	elif FileAccess.file_exists(absolute):
		var backup := _backup_path(absolute)
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		DirAccess.rename_absolute(absolute, backup)
	DirAccess.rename_absolute(temporary, absolute)
	_is_main_file_broken = false


## 저장 묶음 하나 (records·codex·shelter …). 돌려준 사전을 고치면 저장 내용이 바로 바뀐다.
func section(section_name: String) -> Dictionary:
	if not data.has(section_name) or typeof(data[section_name]) != TYPE_DICTIONARY:
		data[section_name] = {}
	return data[section_name]


func scrap() -> int:
	return int(data.get("scrap", 0))


func add_scrap(amount: int) -> void:
	data["scrap"] = scrap() + maxi(amount, 0)
	changed.emit()


## 고철이 모자라면 아무것도 바꾸지 않고 false
func spend_scrap(amount: int) -> bool:
	if amount > scrap():
		return false
	data["scrap"] = scrap() - amount
	changed.emit()
	return true


## 누적 숫자 (total_kills 처럼 판을 넘어 쌓이는 것)
func total(total_name: String) -> float:
	return float(section("totals").get(total_name, 0))


func add_total(total_name: String, amount: float) -> void:
	section("totals")[total_name] = total(total_name) + amount


func setting(setting_name: String) -> Variant:
	var defaults: Dictionary = GameData.table("meta_rules")["default_settings"]
	return section("settings").get(setting_name, defaults.get(setting_name))


## 설정을 바꾸면 바로 저장하고 소리 크기에 반영한다
func set_setting(setting_name: String, value: Variant) -> void:
	section("settings")[setting_name] = value
	apply_sound_settings()
	save()
	changed.emit()


func is_vibration_on() -> bool:
	return bool(setting("is_vibration_on"))


## 화면 흔들림 켜짐/꺼짐 — 값만 저장, 흔들림을 실제로 끄는 곳은 판 쪽 카메라
func is_screen_shake_on() -> bool:
	return bool(setting("is_screen_shake_on"))


## 보이는 규칙 설정 (문서 15 §7-4·§8): 내 효과 투명도 0.25~1, 번쩍임 줄이기, 피해 숫자, 두 번 눌러 고르기
func my_effects_opacity() -> float:
	return clampf(float(setting("my_effects_opacity")), 0.25, 1.0)


func is_flash_reduced() -> bool:
	return bool(setting("is_flash_reduced"))


func is_damage_numbers_on() -> bool:
	return bool(setting("is_damage_numbers_on"))


func is_double_tap_pick_on() -> bool:
	return bool(setting("is_double_tap_pick_on"))


func flag(flag_name: String) -> bool:
	return bool(section("flags").get(flag_name, false))


func set_flag(flag_name: String, value: bool) -> void:
	section("flags")[flag_name] = value


## 저장된 소리 크기를 SoundPlayer 에 넣는다 (music_volume 은 SoundPlayer 쪽 setter 가 지금 나오는 음악에도 바로 반영)
func apply_sound_settings() -> void:
	SoundPlayer.effects_volume = clampf(float(setting("effects_volume")), 0.0, 1.0)
	SoundPlayer.music_volume = clampf(float(setting("music_volume")), 0.0, 1.0)


## 시험용: 저장 내용을 처음 값으로 (화면 캡처 시험이 깨끗한 상태에서 시작하게)
func reset_for_test() -> void:
	data = _default_data()


func _choose_path() -> void:
	var options := _read_test_options()
	if options.has("save"):
		_path = String(options["save"])
	elif options.has("autoplay"):
		_is_writing_allowed = false   # 봇 판이 사람 저장 파일의 고철·기록을 바꾸지 않게
		_path = ""


func _load_first_readable() -> Dictionary:
	if _path.is_empty():
		return _default_data()
	var absolute := _absolute(_path)
	for candidate: String in [absolute, absolute + TEMPORARY_SUFFIX, _backup_path(absolute)]:
		var loaded := _read_json(candidate)
		if not loaded.is_empty():
			return _merge_into(_default_data(), loaded)
		if candidate == absolute and FileAccess.file_exists(absolute):
			_is_main_file_broken = true
	return _default_data()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	# JSON.parse_string 은 실패하면 엔진 오류를 찍어서, 조용히 실패를 알려 주는 parse() 를 쓴다
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		push_warning("SaveData: %s 가 깨져 있어 다음 파일로 되살림" % path)
		return {}
	return parser.data


## 처음 값 틀에 읽은 값을 얹는다: 새 버전에서 생긴 칸은 처음 값, 타입이 다른 칸은 버린다 (깨진 값으로 멈추지 않게)
func _merge_into(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	for key: String in loaded.keys():
		var loaded_value: Variant = loaded[key]
		if not defaults.has(key):
			defaults[key] = loaded_value
			continue
		var default_value: Variant = defaults[key]
		if typeof(default_value) == TYPE_DICTIONARY and typeof(loaded_value) == TYPE_DICTIONARY:
			defaults[key] = _merge_into(default_value, loaded_value)
		elif _is_number(default_value) and _is_number(loaded_value):
			defaults[key] = _same_number_type(default_value, loaded_value)
		elif typeof(default_value) == typeof(loaded_value):
			defaults[key] = loaded_value
	return defaults


## JSON 은 숫자를 모두 소수로 읽어서, 처음 값이 정수인 칸(고철 등)은 정수로 되돌린다
func _same_number_type(default_value: Variant, loaded_value: Variant) -> Variant:
	if typeof(default_value) == TYPE_INT:
		return int(loaded_value)
	return float(loaded_value)


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"scrap": 0,
		"totals": {},
		"shelter": {},
		"unlocked_survivors": {},
		"infection_unlocked": 0,
		"achievements": {},
		"codex": {},
		"records": {},
		"settings": {},
		"daily": {},
		"flags": {},
	}


func _absolute(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.contains(":") or path.begins_with("/"):
		return path
	return ProjectSettings.globalize_path("res://" + path)   # 시험용 상대 경로는 프로젝트 폴더 기준 (RunRecorder --stats 와 같게)


func _backup_path(absolute: String) -> String:
	return absolute.get_basename() + BACKUP_SUFFIX + "." + absolute.get_extension()


## SceneRouter 보다 먼저 준비될 수도 있어 명령줄을 직접 읽는다
func _read_test_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var pair := argument.substr(2).split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else "true"
	return options
