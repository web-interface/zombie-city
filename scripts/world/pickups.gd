## [파일] scripts/world/pickups.gd
## [하는 일] 바닥에 떨어진 특별한 것들: 보물 상자(정예·보스가 떨굼 — 주우면 슬롯 창), 자석(화면 조각을 다 끌어옴), 폭탄(화면 좀비에게 큰 피해), 냉각 스프레이(좀비가 잠깐 얼어붙음). 통통 튀며 반짝이고, 생존자가 닿으면 줍는다. 오래 두면 사라진다.
## [쓰는 곳] scenes/run.tscn 의 World/Pickups (RunContext.pickups). scripts/run/run_rewards.gd 가 drop() 하고 picked 신호로 효과·상자 창을 연다. 자동 플레이 봇이 positions() 로 주우러 간다.
## [근거 문서] 14 §2-6 보물 상자·줍기, data/run_rules.json chest·pickups
class_name Pickups
extends Node2D

signal picked(kind: String, at_position: Vector2)

const CHEST_TEXTURE: Texture2D = preload("res://art/sprites/chest.png")
const ICON_NAMES := {"magnet": "icon_magnet", "bomb": "icon_bomb", "freeze": "icon_freeze"}
const BOB_SPEED := 4.0
const BLINK_BEFORE_GONE_SECONDS := 5.0

var _items: Array[Dictionary] = []   # {kind, position, time_left}
var _icons: Dictionary = {}
var _rules: Dictionary = {}
var _context: RunContext
var _time: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	_rules = GameData.rules("pickups")
	z_index = -1
	for kind: String in ICON_NAMES:
		var path := "res://art/sprites/icons/%s.png" % ICON_NAMES[kind]
		_icons[kind] = load(path) if ResourceLoader.exists(path) else null


## kind: "chest" · "magnet" · "bomb" · "freeze"
func drop(kind: String, at_position: Vector2) -> void:
	if _items.size() >= int(_rules["max_on_field"]) and kind != "chest":
		return
	var life := float(_rules["life_seconds"]) * (3.0 if kind == "chest" else 1.0)   # 상자는 오래 남는다
	_items.append({"kind": kind, "position": at_position, "time_left": life})


## 좀비가 쓰러질 때 아주 가끔 (data/run_rules.json pickups)
func maybe_drop(at_position: Vector2) -> void:
	var roll := randf()
	for kind: String in ["magnet", "bomb", "freeze"]:
		var chance := float(_rules[kind + "_chance"])
		if roll < chance:
			drop(kind, at_position)
			return
		roll -= chance


func positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for item: Dictionary in _items:
		result.append(item["position"])
	return result


## 다음 밤으로 넘어갈 때: 바닥에 남은 보물 상자를 거둬 그 수를 돌려준다 (사라지지 않고 다음 밤에 열리게)
func take_chests() -> int:
	var count := 0
	for item: Dictionary in _items:
		if item["kind"] == "chest":
			count += 1
	return count


func clear() -> void:
	_items.clear()
	queue_redraw()


func update(delta: float) -> void:
	_time += delta
	var survivor_position := _context.survivor.position
	var reach := float(_rules["collect_distance"])
	for item: Dictionary in _items:
		item["time_left"] = float(item["time_left"]) - delta
		if survivor_position.distance_to(item["position"]) <= reach:
			item["time_left"] = -1.0
			picked.emit(String(item["kind"]), Vector2(item["position"]))
	_items.assign(_items.filter(func(item: Dictionary) -> bool: return float(item["time_left"]) > 0.0))
	queue_redraw()


func _draw() -> void:
	for item: Dictionary in _items:
		var time_left := float(item["time_left"])
		if time_left < BLINK_BEFORE_GONE_SECONDS and int(_time * 8.0) % 2 == 0:
			continue   # 곧 사라지면 깜빡임
		var bob := roundf(sin(_time * BOB_SPEED + Vector2(item["position"]).x) * 1.5)
		var point := Vector2(item["position"]).round() + Vector2(0, bob)
		draw_circle(Vector2(item["position"]).round() + Vector2(0, 5), 4.0, Color(0, 0, 0, 0.35))
		draw_circle(point, 8.0 + sin(_time * 6.0), Color(1.0, 0.85, 0.35, 0.18))   # 반짝이는 빛 (멀리서도 보이게)
		if item["kind"] == "chest":
			draw_texture_rect_region(CHEST_TEXTURE, Rect2(point - Vector2(8, 10), Vector2(16, 16)), Rect2(0, 0, 16, 16))
		elif _icons.get(item["kind"]) != null:
			draw_texture(_icons[item["kind"]], point - Vector2(5, 7))
