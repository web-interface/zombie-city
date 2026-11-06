## [파일] scripts/world/health_packs.gd
## [하는 일] 편의점 구급함(회복 아이템): 쓰러진 좀비가 가끔 떨구고(확률은 data), 생존자가 줍는 범위에 들어가면 끌려와 체력을 회복시킨다. 위기에서 다시 살아나는 '아슬아슬한 맛'을 만든다. 화면에 너무 많이 쌓이지 않게 개수를 제한한다.
## [쓰는 곳] scenes/run.tscn 의 World/HealthPacks. run.gd 가 좀비가 쓰러질 때 maybe_drop() 을, 매 프레임 update() 를 부른다.
## [근거 문서] 12 §5 재미 지표(아슬아슬 생존 2~4번), docs/balance_log.md 1차(회복 수단이 없어 0번), data/run_rules.json health_pack
class_name HealthPacks
extends Node2D

const ICON: Texture2D = preload("res://art/sprites/icons/icon_first_aid.png")
const COLLECT_DISTANCE := 6.0
const PULL_SPEED := 90.0
const BOB_SPEED := 4.0

var _packs: Array[Vector2] = []
var _context: RunContext
var _rules: Dictionary = {}
var _time: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	_rules = GameData.rules("health_pack")
	z_index = -2


## 떨어져 있는 구급함 위치들 (자동 플레이 봇이 주우러 갈 때)
func positions() -> Array[Vector2]:
	return _packs


func maybe_drop(at_position: Vector2) -> void:
	if _packs.size() >= int(_rules["max_on_field"]) or randf() >= float(_rules["drop_chance"]):
		return
	_packs.append(at_position)


func update(delta: float) -> void:
	_time += delta
	var survivor := _context.survivor
	var pickup_radius := survivor.stats.value("pickup_radius")
	for index: int in range(_packs.size() - 1, -1, -1):
		var to_survivor := survivor.position - _packs[index]
		if to_survivor.length() <= COLLECT_DISTANCE:
			_packs.remove_at(index)
			survivor.heal(float(_rules["heal_ratio"]))
			_context.play_sound("skill_heal")
		elif to_survivor.length() <= pickup_radius:
			_packs[index] += to_survivor.normalized() * minf(PULL_SPEED * delta, to_survivor.length())
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_time * BOB_SPEED))   # 1점씩 위아래로 떠서 눈에 띄게
	for pack_position: Vector2 in _packs:
		draw_texture(ICON, (pack_position - ICON.get_size() * 0.5 + Vector2(0, bob)).round())
