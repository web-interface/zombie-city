## [파일] scripts/world/health_packs.gd
## [하는 일] 편의점 구급함(회복 아이템): 쓰러진 좀비가 가끔 떨구고(확률은 data), 생존자가 줍는 범위에 들어가면 끌려와 체력을 회복시킨다. 위기에서 다시 살아나는 '아슬아슬한 맛'을 만든다. 체력이 가득이면 줍지 않고 두며, 개수가 다 차면 가장 먼 것을 치운다.
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


## 다음 밤으로 넘어갈 때 비운다
func clear() -> void:
	_packs.clear()
	queue_redraw()


## 정예처럼 꼭 떨구는 경우 (확률 없이)
func drop_at(at_position: Vector2) -> void:
	if _packs.size() >= int(_rules["max_on_field"]):
		_packs.remove_at(_farthest_index())
	_packs.append(at_position)


func maybe_drop(at_position: Vector2) -> void:
	if randf() >= float(_rules["drop_chance"]) * _context.night_cycle.health_pack_chance_multiplier():   # 감염도 3 '반만'
		return
	if _packs.size() >= int(_rules["max_on_field"]):
		_packs.remove_at(_farthest_index())   # 꽉 차면 멀리 두고 온 것을 치운다 (지나친 구급함이 쌓여 더 안 떨어지던 것 — 마지막 검수)
	_packs.append(at_position)


func update(delta: float) -> void:
	_time += delta
	queue_redraw()
	var survivor := _context.survivor
	if survivor.health_ratio() >= 1.0:
		return   # 체력이 가득이면 줍지 않고 그대로 둔다 (주워도 회복 0 이라 아까움)
	var pickup_radius := survivor.stats.value("pickup_radius")
	for index: int in range(_packs.size() - 1, -1, -1):
		var to_survivor := survivor.position - _packs[index]
		if to_survivor.length() <= COLLECT_DISTANCE:
			_packs.remove_at(index)
			survivor.heal(float(_rules["heal_ratio"]))
			_context.play_sound("skill_heal")
		elif to_survivor.length() <= pickup_radius:
			_packs[index] += to_survivor.normalized() * minf(PULL_SPEED * delta, to_survivor.length())


func _farthest_index() -> int:
	var survivor_position := _context.survivor.position
	var farthest := 0
	for index: int in range(1, _packs.size()):
		if _packs[index].distance_to(survivor_position) > _packs[farthest].distance_to(survivor_position):
			farthest = index
	return farthest


func _draw() -> void:
	var bob := roundf(sin(_time * BOB_SPEED))   # 1점씩 위아래로 떠서 눈에 띄게
	for pack_position: Vector2 in _packs:
		draw_texture(ICON, (pack_position - ICON.get_size() * 0.5 + Vector2(0, bob)).round())
