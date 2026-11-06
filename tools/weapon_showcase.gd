## [파일] tools/weapon_showcase.gd
## [하는 일] 무기 연출 미리보기(시험 스크립트, 창이 뜸): 한 판 장면을 열어 생존자 전용 무기 4개(또는 --weapons 로 고른 것)를 최고 단계로 주고 좀비를 둘레에 계속 깔아, 정해진 순간마다 화면을 PNG(3배 크기)로 찍는다. 이어서 모두 진화시켜 금색 연출을 찍고, 금색 히든 카드·진화 카드 창(빼 버리기 누른 모양 포함)과 히든 스킬 컷인·효과도 찍는다. 눈으로 연출을 확인하는 용도라 게임 규칙에는 손대지 않는다.
## [쓰는 곳] 사람·검수관이 직접 돌린다: "…/Godot_v4.7.2-stable_win64_console.exe" --path . -s tools/weapon_showcase.gd -- --survivor=police --capture=tools/out/showcase [--weapons=shotgun,molotov,saw_drone]
## [근거 문서] 14 §2-7 눈에 띄는 연출, 12 검수(화면 캡처 확인), 10 §9 확인
extends SceneTree

# 시험 스크립트는 자동 로드(GameData·SceneRouter)가 생기기 전에 읽혀서, 게임 클래스 이름(LevelUp 등)을 타입으로 쓰면
# 그 스크립트들이 먼저 읽히며 오류가 난다 → 여기서는 Node·Object 로만 들고 이름으로 찾아 부른다.

const RUN_SCENE := "res://scenes/run.tscn"
const SETUP_SECOND := 0.6
const EVOLVE_SECOND := 4.0
const PANEL_SECOND := 7.4
const BANISH_SECOND := 8.0
const PANEL_CLOSE_SECOND := 8.4
const HIDDEN_SKILL_SECOND := 8.8
const QUIT_SECOND := 12.0
## 무기 연출은 짧게 번쩍이고 사라져서 구간 안을 BURST_GAP 마다 여러 장 찍는다 (보통 → 진화)
const NORMAL_WINDOW := Vector2(2.0, 3.8)
const EVOLVED_WINDOW := Vector2(4.8, 7.0)
const BURST_GAP := 0.3
## 그 밖에 찍는 순간 (초) → 파일 이름 뒷부분
const FIXED_CAPTURES := {
	7.8: "c_cards_1", 8.2: "c_cards_2",
	8.9: "d_cutin_1", 9.1: "d_cutin_2", 9.35: "d_cutin_3", 10.0: "d_hidden_1", 10.6: "d_hidden_2", 11.3: "d_hidden_3",
}
const ZOMBIES_PER_WAVE := 30
const WAVE_SECONDS := 0.8
const TEST_HEALTH := 100000.0
const CAPTURE_SCALE := 3

var _time: float = 0.0
var _captures: Dictionary = {}
var _started_at_msec: int = -1
var _done: Dictionary = {}
var _wave_timer: float = 0.0
var _run: Node = null
var _capture_folder: String = "tools/out/showcase"
var _survivor_id: String = "police"


func _initialize() -> void:
	_capture_folder = String(_user_option("capture", _capture_folder))
	_survivor_id = String(_user_option("survivor", _survivor_id))
	var scene_router := root.get_node("SceneRouter")
	scene_router.set("has_seen_first_run_hints", true)   # 조작 안내 글이 사진을 가리지 않게
	scene_router.set("selected_survivor_id", _survivor_id)
	_captures = FIXED_CAPTURES.duplicate()
	_add_burst(NORMAL_WINDOW, "a_normal")
	_add_burst(EVOLVED_WINDOW, "b_evolved")
	change_scene_to_file(RUN_SCENE)


func _add_burst(window: Vector2, prefix: String) -> void:
	var count := int((window.y - window.x) / BURST_GAP) + 1
	for index: int in range(count):
		_captures[window.x + BURST_GAP * index] = "%s_%02d" % [prefix, index + 1]


## 시각은 실제 시간으로 잰다 (히든 스킬 컷인 동안 게임 시간이 멈춰서 delta 로 재면 찍을 때를 놓친다)
func _process(delta: float) -> bool:
	if _started_at_msec < 0:
		_started_at_msec = Time.get_ticks_msec()
	_time = (Time.get_ticks_msec() - _started_at_msec) / 1000.0
	_run_step_once(SETUP_SECOND, _give_weapons)
	_run_step_once(EVOLVE_SECOND, _evolve_all)
	_run_step_once(PANEL_SECOND, _show_special_cards)
	_run_step_once(BANISH_SECOND, _press_banish)
	_run_step_once(PANEL_CLOSE_SECOND, _close_cards)
	_run_step_once(HIDDEN_SKILL_SECOND, _use_hidden_skill)
	if _run != null and not paused:
		_keep_zombies_coming(delta)
	for second: float in _captures.keys():
		if _time >= second and not _done.has(second):
			_done[second] = true
			_capture(String(_captures[second]))
	return _time >= QUIT_SECOND


func _run_step_once(second: float, step: Callable) -> void:
	if _time >= second and not _done.has(step):
		_done[step] = true
		step.call()


## 생존자 전용 무기(또는 --weapons)를 모두 최고 단계로. 레벨 업 창이 끼어들지 않게 경험치 연결은 끊는다.
func _give_weapons() -> void:
	_run = current_scene
	var context: Object = _run.get("context")
	var level_up := _run.get_node("Systems/LevelUp")
	var shards: Object = context.get("shards")
	shards.disconnect("collected", Callable(level_up, "add_experience"))
	var survivor: Object = context.get("survivor")
	survivor.get("stats").call("set_source", "showcase", [{"add": {"max_health": TEST_HEALTH}}])
	survivor.set("health", TEST_HEALTH)
	var rack := _run.get_node("World/WeaponRack")
	for weapon_id: String in _weapon_list():
		if rack.call("weapon_of", weapon_id) == null:
			rack.call("add_weapon", weapon_id)
		var weapon: Object = rack.call("weapon_of", weapon_id)
		weapon.set("level", weapon.call("max_level"))


func _evolve_all() -> void:
	var rack := _run.get_node("World/WeaponRack")
	var level_up := _run.get_node("Systems/LevelUp")
	for weapon: Object in rack.get("weapons"):
		rack.call("add_or_upgrade_gear", weapon.call("evolution_gear_id"))
		level_up.call("apply_card", {"kind": "evolution", "id": weapon.get("weapon_id")})


## 히든 카드 + 진화 카드 + 보통 카드를 한 창에 띄워 찍는다
func _show_special_cards() -> void:
	var level_up := _run.get_node("Systems/LevelUp")
	var deck: Object = level_up.get("deck")
	var cards: Array = [deck.call("hidden_card")]
	var pistol_info: Dictionary = _game_data().call("entry", "weapons", "pistol")
	var evolution: Dictionary = pistol_info["evolution"]
	cards.append({"kind": "evolution", "id": "pistol", "name": evolution["name"], "icon": evolution["icon"],
		"description": evolution["description"], "level_text": "진화!", "flavor": "둘이 합쳐지면…"})
	var normal_cards: Array = deck.call("upgrade_cards")
	if not normal_cards.is_empty():
		cards.append(normal_cards[0])
	paused = true
	level_up.emit_signal("cards_ready", cards)


## 빼 버리기 버튼을 누른 모양 (뺄 수 있는 카드만 빨간 테두리)
func _press_banish() -> void:
	_run.get_node("Hud").get("level_up_panel").call("_toggle_banish")


func _close_cards() -> void:
	var panel: Control = _run.get_node("Hud").get("level_up_panel")
	panel.visible = false
	paused = false


func _use_hidden_skill() -> void:
	var survivor_info: Dictionary = _game_data().call("entry", "survivors", _survivor_id)
	var skill_runner := _run.get_node("Systems/SkillRunner")
	skill_runner.call("set_hidden_skill", String(survivor_info["hidden_skill"]))
	skill_runner.call("try_use")


## 생존자 둘레에 좀비를 계속 깔아 무기가 쉬지 않게
func _keep_zombies_coming(delta: float) -> void:
	_wave_timer -= delta
	if _wave_timer > 0.0:
		return
	_wave_timer = WAVE_SECONDS
	var horde := _run.get_node("World/ZombieHorde")
	var survivor_position: Vector2 = _run.get_node("World/Survivor").get("position")
	for index: int in range(ZOMBIES_PER_WAVE):
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(28.0, 110.0)
		horde.call("spawn", "walker", survivor_position + offset, 1.0)


func _capture(capture_name: String) -> void:
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * CAPTURE_SCALE, image.get_height() * CAPTURE_SCALE, Image.INTERPOLATE_NEAREST)
	var folder := ProjectSettings.globalize_path("res://" + _capture_folder) if not _capture_folder.contains(":") else _capture_folder
	DirAccess.make_dir_recursive_absolute(folder)
	image.save_png(folder.path_join("%s_%s.png" % [_survivor_id, capture_name]))


func _weapon_list() -> Array[String]:
	var chosen := String(_user_option("weapons", ""))
	var list: Array[String] = []
	if chosen.is_empty():
		var survivor_info: Dictionary = _game_data().call("entry", "survivors", _survivor_id)
		list.assign(survivor_info["weapon_pool"])
	else:
		list.assign(chosen.split(","))
	return list


func _game_data() -> Node:
	return root.get_node("GameData")


func _user_option(option_name: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % option_name):
			return argument.split("=", true, 1)[1]
	return fallback
