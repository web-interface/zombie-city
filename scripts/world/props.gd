## [파일] scripts/world/props.gd
## [하는 일] 도시 소품: 블록마다 같은 규칙(위치 숫자로 정한 무작위)으로 버려진 차·가로등과 동네 소품(분리수거함·배달 오토바이·드럼통·고깔·타이어 — data/city_decor.json)을 놓는다. 차는 막히는 장애물이라 생존자·좀비가 통과하지 못하고(push_out), 가로등 위치는 빛 담당에게 넘긴다. 카메라 근처 블록만 만들고 멀어지면 치운다.
## [쓰는 곳] scenes/run.tscn 의 World/Props. run.gd 가 update() 를, 생존자·좀비 이동 뒤 push_out() 을 부른다.
## [근거 문서] 04 §6 지역(도심 도로), 02 §8 지형, data/run_rules.json city_layout
class_name Props
extends Node2D

const SPRITE_FOLDER := "res://art/sprites/"
const CAR_HALF_SIZE := Vector2(5, 9)      # 차 그림(12×20)에서 실제로 막히는 몸통 반쪽 크기
const ACTIVE_BLOCK_RANGE := 1             # 카메라가 있는 블록 둘레 몇 칸까지 만들어 둘지

var _context: RunContext
var _block_spacing: float
var _road_half_width: float
var _car_chance: int
var _decorations: Array = []
var _blocks: Dictionary = {}              # Vector2i 블록 → {"nodes": [...], "cars": [Rect2…], "lamps": [Vector2…]}
var _textures: Dictionary = {}


func setup(context: RunContext, city_layout: Dictionary) -> void:
	_context = context
	_block_spacing = float(city_layout["block_spacing"])
	_road_half_width = float(city_layout["road_half_width"])
	_car_chance = int(city_layout["car_chance_percent"])
	_decorations = GameData.table("city_decor")["decorations"]
	y_sort_enabled = true


func update(view_center: Vector2) -> void:
	var center_block := _block_of(view_center)
	var wanted: Dictionary = {}
	for block_y: int in range(center_block.y - ACTIVE_BLOCK_RANGE, center_block.y + ACTIVE_BLOCK_RANGE + 1):
		for block_x: int in range(center_block.x - ACTIVE_BLOCK_RANGE, center_block.x + ACTIVE_BLOCK_RANGE + 1):
			var block := Vector2i(block_x, block_y)
			wanted[block] = true
			if not _blocks.has(block):
				_blocks[block] = _build_block(block)
	for block: Vector2i in _blocks.keys():
		if not wanted.has(block):
			for node: Node in _blocks[block]["nodes"]:
				node.queue_free()
			_blocks.erase(block)
	_context.lighting.set_lamp_positions(_nearby_lamps(view_center))


## 차에 겹친 위치를 차 밖으로 밀어낸다. radius 는 밀려나는 쪽 몸 크기.
func push_out(at_position: Vector2, radius: float) -> Vector2:
	var block := _block_of(at_position)
	if not _blocks.has(block):
		return at_position
	for car_rect: Rect2 in _blocks[block]["cars"]:
		var grown := car_rect.grow(radius)
		if grown.has_point(at_position):
			at_position = _nearest_edge_point(grown, at_position)
	return at_position


func _build_block(block: Vector2i) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = hash(block)
	var corner := Vector2(block) * _block_spacing
	var built := {"nodes": [], "cars": [], "lamps": []}
	if random.randi_range(1, 100) <= _car_chance:
		_add_car(built, corner + Vector2(_road_half_width - 14.0, _road_half_width + 30.0 + random.randf_range(0.0, 80.0)))
	if random.randi_range(1, 100) <= _car_chance:
		_add_car(built, corner + Vector2(_block_spacing * 0.5 + random.randf_range(-30.0, 30.0), _block_spacing - _road_half_width + 14.0))
	for decoration: Dictionary in _decorations:
		if random.randi_range(1, 100) <= int(decoration["chance_percent"]):
			_add_sprite(built, String(decoration["sprite"]), corner + _decoration_offset(String(decoration["place"]), random))
	for lamp_offset: Vector2 in [Vector2(_road_half_width + 6.0, _road_half_width + 6.0), Vector2(_block_spacing - _road_half_width - 6.0, _block_spacing - _road_half_width - 6.0)]:
		_add_sprite(built, "lamp", corner + lamp_offset)
		built["lamps"].append(corner + lamp_offset)
	return built


## 놓는 자리 종류(data/city_decor.json _놓는_자리)마다 블록 모서리에서의 위치
func _decoration_offset(place: String, random: RandomNumberGenerator) -> Vector2:
	match place:
		"sidewalk_corner":
			return Vector2(_road_half_width + 16.0 + random.randf_range(0.0, 6.0), _road_half_width + 6.0)
		"curb":
			return Vector2(_block_spacing - _road_half_width + 8.0, _block_spacing * 0.5 + random.randf_range(-50.0, 50.0))
		"road":
			return Vector2(random.randf_range(-_road_half_width + 8.0, _road_half_width - 8.0), _block_spacing * 0.5 + random.randf_range(-60.0, 60.0))
	push_error("data/city_decor.json: 모르는 놓는 자리 '%s'" % place)
	return Vector2.ZERO


func _add_car(built: Dictionary, center: Vector2) -> void:
	_add_sprite(built, "car", center)
	built["cars"].append(Rect2(center - CAR_HALF_SIZE, CAR_HALF_SIZE * 2.0))


func _add_sprite(built: Dictionary, sprite_name: String, at_position: Vector2) -> void:
	if not _textures.has(sprite_name):
		_textures[sprite_name] = load(SPRITE_FOLDER + sprite_name + ".png")
	var sprite := Sprite2D.new()
	sprite.texture = _textures[sprite_name]
	sprite.position = at_position.round()
	add_child(sprite)
	built["nodes"].append(sprite)


func _nearby_lamps(view_center: Vector2) -> Array[Vector2]:
	var lamps: Array[Vector2] = []
	for block_data: Dictionary in _blocks.values():
		for lamp: Vector2 in block_data["lamps"]:
			if absf(lamp.x - view_center.x) < 140.0 and absf(lamp.y - view_center.y) < 220.0:
				lamps.append(lamp)
	return lamps


func _block_of(at_position: Vector2) -> Vector2i:
	return Vector2i(floori(at_position.x / _block_spacing), floori(at_position.y / _block_spacing))


func _nearest_edge_point(rect: Rect2, point: Vector2) -> Vector2:
	var to_left := point.x - rect.position.x
	var to_right := rect.end.x - point.x
	var to_top := point.y - rect.position.y
	var to_bottom := rect.end.y - point.y
	var smallest := minf(minf(to_left, to_right), minf(to_top, to_bottom))
	if smallest == to_left:
		return Vector2(rect.position.x, point.y)
	if smallest == to_right:
		return Vector2(rect.end.x, point.y)
	if smallest == to_top:
		return Vector2(point.x, rect.position.y)
	return Vector2(point.x, rect.end.y)
