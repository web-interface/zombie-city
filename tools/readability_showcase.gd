## [파일] tools/readability_showcase.gd
## [하는 일] '보이는 규칙' 눈 확인용 캡처(시험 스크립트, 창이 뜸): 한 판을 열어 장면을 차례로 만들고 PNG(3배)로 찍는다 — 적 웅덩이 위에 내 불·연기·독 구름이 겹친 장면, 침 뱉는 좀비 침·웅덩이, 부푼 좀비 터짐 예고, 보스 산성 비·토하기 예고, 안개 밤 속 적 테두리, 웅덩이 안에 서 있을 때(발밑 고리·가장자리 빨강), 체력 30% 아래 가장자리, 레벨 업 카드 흐림 → 켜짐, 마지막에 쓰러져 결과 화면 '무엇에 당했나'. 겹친 장면은 흑백 사진도 한 장 (색 없이 모양으로 구분되는지).
## [쓰는 곳] 사람·검수관이 돌린다: "…/Godot_v4.7.2-stable_win64_console.exe" --audio-driver Dummy --position 2600,100 --path . -s tools/readability_showcase.gd -- --survivor=firefighter --capture=tools/out/captures/readability
## [근거 문서] 15 §7 보이는 규칙·§8 잘못 눌림, 12 검수(화면 캡처 확인)
extends SceneTree

const RUN_SCENE := "res://scenes/run.tscn"
const CAPTURE_SCALE := 3
const TEST_HEALTH := 100000.0
## (초, 할 일 이름) — 차례대로
const STEPS: Array[Array] = [
	[0.6, "prepare"], [1.2, "overlap"], [2.6, "shot_overlap"], [2.8, "spitters"], [5.2, "shot_spitters"],
	[5.4, "bloater"], [5.7, "shot_bloater"], [6.6, "boss_acid"], [7.3, "shot_boss_acid"], [8.6, "fog_night"],
	[9.4, "shot_fog"], [9.6, "stand_in_zone"], [10.2, "shot_standing"], [10.4, "low_health"], [11.0, "shot_low_health"],
	[11.2, "level_up"], [12.6, "die"], [16.5, "shot_result"], [17.0, "quit"],
]

var _started_msec: int = -1
var _done: Dictionary = {}
var _run: Node = null
var _context: Object = null
var _folder: String = "tools/out/captures/readability"
var _survivor_id: String = "firefighter"
var _panel_shots: Array[float] = []


func _initialize() -> void:
	_folder = _user_option("capture", _folder)
	_survivor_id = _user_option("survivor", _survivor_id)
	var router := root.get_node("SceneRouter")
	router.set("has_seen_first_run_hints", true)
	router.set("selected_survivor_id", _survivor_id)
	change_scene_to_file(RUN_SCENE)


func _process(_delta: float) -> bool:
	if _started_msec < 0:
		_started_msec = Time.get_ticks_msec()
	var seconds := (Time.get_ticks_msec() - _started_msec) / 1000.0
	for step: Array in STEPS:
		if seconds >= float(step[0]) and not _done.has(step[1]):
			_done[step[1]] = true
			call("_step_" + String(step[1]))
	_capture_level_up_panel()
	return _done.has("quit")


func _step_prepare() -> void:
	_run = current_scene
	_context = _run.get("context")
	var survivor: Object = _context.get("survivor")
	survivor.get("stats").call("set_source", "showcase", [{"add": {"max_health": TEST_HEALTH}}])
	survivor.set("health", TEST_HEALTH)
	var level_up := _run.get_node("Systems/LevelUp")
	_context.get("shards").disconnect("collected", Callable(level_up, "add_experience"))
	_run.get_node("Systems/ZombieSpawner").set_process(false)
	_run.get_node("Systems/ZombieSpawner").set_physics_process(false)


## 적 웅덩이 셋 위에 내 불·연기·독 구름·빛을 겹쳐 깐다 + 둘레 좀비
func _step_overlap() -> void:
	var center: Vector2 = _survivor_position()
	var hazards: Object = _context.get("hazards")
	var zones: Object = _run.get_node("World/WeaponRack").get("zones")
	var area: Object = _context.get("area_effects")
	for offset: Vector2 in [Vector2(-34, -40), Vector2(30, -30), Vector2(0, 34)]:
		hazards.call("add_puddle", center + offset, 13.0, 30.0, 0.0, "산성 웅덩이")
	zones.call("add_zone", "fire", center + Vector2(-26, -34), 22.0, 30.0, 1.0)
	zones.call("add_zone", "gas", center + Vector2(26, -24), 20.0, 30.0, 0.0)
	area.call("add_poison_cloud", center + Vector2(8, 30), 20.0, 30.0, 1.0)
	area.call("add_fire_zone", center + Vector2(-14, 40), 14.0, 30.0, 1.0)
	_spawn_ring("walker", 14, 30.0, 70.0)


func _step_spitters() -> void:
	_clear_field()
	_spawn_ring("spitter", 5, 50.0, 60.0)
	_spawn_ring("walker", 10, 40.0, 80.0)


func _step_bloater() -> void:
	var horde := _run.get_node("World/ZombieHorde")
	for offset: Vector2 in [Vector2(-30, -20), Vector2(28, 26)]:
		var bloater: Object = horde.call("spawn", "bloater", _survivor_position() + offset, 1.0)
		horde.call("hit", bloater, 99999.0, {"source": "showcase"})


## 거대 감염체 산성 비(예고 원 → 웅덩이) + 토하기 예고 선 + 도살자 식칼
func _step_boss_acid() -> void:
	var center: Vector2 = _survivor_position()
	var hazards: Object = _context.get("hazards")
	for offset: Vector2 in [Vector2(-40, -10), Vector2(36, -44), Vector2(10, 44), Vector2(-20, -60)]:
		hazards.call("warn", center + offset, 14.0, 1.2, {"type": "acid", "source": "산성 비", "puddle": {"seconds": 20.0, "damage_per_second": 0.0}})
	hazards.call("warn_line", center + Vector2(70, -70), center + Vector2(-10, 10), 10.0, 1.5, {"type": "line_puddles", "count": 3, "source": "거대 감염체 토사물", "puddle": {"radius": 9.0, "seconds": 20.0, "damage_per_second": 0.0}})
	hazards.call("shoot", center + Vector2(80, 0), Vector2(-40, 0), 0.0, "도살자 식칼", "cleaver")
	hazards.call("shoot", center + Vector2(-70, 30), Vector2(30, -10), 0.0, "철거반장 철근", "rebar")


func _step_fog_night() -> void:
	var weather: Object = _context.get("weather")
	weather.call("apply_theme", {"name": "안개", "darkness": "#20242e", "weather": "fog"})
	_step_overlap()


## 웅덩이 한가운데 세우고 실제로 맞게 (테스트 체력이라 안 쓰러짐)
func _step_stand_in_zone() -> void:
	var hazards: Object = _context.get("hazards")
	hazards.call("add_puddle", _survivor_position(), 14.0, 30.0, 6.0, "산성 웅덩이")


func _step_low_health() -> void:
	var survivor: Object = _context.get("survivor")
	survivor.set("health", TEST_HEALTH * 0.2)


func _step_level_up() -> void:
	var level_up := _run.get_node("Systems/LevelUp")
	level_up.call("add_experience", float(level_up.call("experience_needed")) * 1.05)
	_panel_shots = [0.1, 0.4, 0.8]


## 레벨 업 창이 뜬 뒤 0.1·0.4초(흐림)·0.8초(켜짐)에 찍고 0.8초 사진 뒤 카드를 고른다
func _capture_level_up_panel() -> void:
	if _panel_shots.is_empty() or _run == null:
		return
	var panel: Control = _run.get_node("Hud").get("level_up_panel")
	if not panel.visible:
		return
	if not panel.has_meta("opened_msec"):
		panel.set_meta("opened_msec", Time.get_ticks_msec())
	var since := (Time.get_ticks_msec() - int(panel.get_meta("opened_msec"))) / 1000.0
	if since >= _panel_shots[0]:
		_capture("level_up_%.1fs" % _panel_shots.pop_front())
		if _panel_shots.is_empty():
			panel.call("choose", 0)


## 체력을 진짜로 낮춰 웅덩이·좀비·식칼에 쓰러지게 → 결과 화면
func _step_die() -> void:
	var survivor: Object = _context.get("survivor")
	survivor.get("stats").call("set_source", "showcase", [])
	survivor.set("health", 30.0)
	var hazards: Object = _context.get("hazards")
	hazards.call("add_puddle", _survivor_position(), 14.0, 30.0, 8.0, "산성 웅덩이")
	hazards.call("shoot", _survivor_position() + Vector2(40, 0), Vector2(-60, 0), 12.0, "도살자 식칼", "cleaver")
	_spawn_ring("walker", 6, 8.0, 12.0)


func _step_shot_overlap() -> void:
	_capture("overlap")
	_capture("overlap_gray", true)


func _step_shot_spitters() -> void:
	_capture("spitters")


func _step_shot_bloater() -> void:
	_capture("bloater")


func _step_shot_boss_acid() -> void:
	_capture("boss_acid")


func _step_shot_fog() -> void:
	_capture("fog_night")
	_capture("fog_night_gray", true)


func _step_shot_standing() -> void:
	_capture("standing_in_zone")


func _step_shot_low_health() -> void:
	_capture("low_health")


func _step_shot_result() -> void:
	_capture("result")


func _step_quit() -> void:
	pass


func _clear_field() -> void:
	for node_path: String in ["World/Hazards", "World/AreaEffects"]:
		_run.get_node(node_path).call("clear")
	_run.get_node("World/WeaponRack").get("zones").call("clear")


func _spawn_ring(kind: String, count: int, near: float, far: float) -> void:
	var horde := _run.get_node("World/ZombieHorde")
	for index: int in range(count):
		var offset := Vector2.from_angle(TAU * index / count + randf() * 0.4) * randf_range(near, far)
		horde.call("spawn", kind, _survivor_position() + offset, 1.0)


func _survivor_position() -> Vector2:
	return _run.get_node("World/Survivor").get("position")


func _capture(capture_name: String, is_gray: bool = false) -> void:
	var image := root.get_texture().get_image()
	if is_gray:
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var luminance := image.get_pixel(x, y).get_luminance()
				image.set_pixel(x, y, Color(luminance, luminance, luminance))
	image.resize(image.get_width() * CAPTURE_SCALE, image.get_height() * CAPTURE_SCALE, Image.INTERPOLATE_NEAREST)
	var folder := ProjectSettings.globalize_path("res://" + _folder) if not _folder.contains(":") else _folder
	DirAccess.make_dir_recursive_absolute(folder)
	image.save_png(folder.path_join("%s_%s.png" % [_survivor_id, capture_name]))


func _user_option(option_name: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % option_name):
			return argument.split("=", true, 1)[1]
	return fallback
