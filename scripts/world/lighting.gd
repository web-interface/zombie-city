## [파일] scripts/world/lighting.gd
## [하는 일] 빛과 어둠: 화면 전체를 밤처럼 어둡게 덮고(CanvasModulate), 생존자 손전등(손전등 배터리 장비만큼 넓게)·가로등·스킬 빛(섬광탄·조명탄 등)을 계단식 빛 그림으로 켠다. 게임 규칙용으로 "이 자리가 밝은가?"(is_in_light)에 답한다.
## [쓰는 곳] scenes/run.tscn 의 World/Lighting. 좀비 무리가 빠르기·피해 배율을 정할 때, 기어다니는 좀비를 보일지 정할 때 묻는다. 소품(props.gd)이 가로등 위치를, 스킬이 잠깐 빛을 넘긴다.
## [근거 문서] 02 §4 빛과 어둠, 03 §7, 06 밤 분위기
class_name Lighting
extends Node2D

const LIGHT_TEXTURE: Texture2D = preload("res://art/sprites/light_stepped.png")
const LIGHT_TEXTURE_RADIUS := 32.0          # 빛 그림(64×64)의 반지름
const LAMP_COLOR := Color("ffd59a")         # 가로등은 따뜻한 노란빛
const FLASHLIGHT_COLOR := Color("e3ebff")
const BURST_COLOR := Color("fff6d8")
const MAX_LAMP_LIGHTS := 12
const MAX_TEMPORARY_LIGHTS := 6   # 조명탄·스킬 빛이 한꺼번에 많아도 빛 개수는 이만큼 (웹·폰에서 빛 하나마다 그리기가 늘어서 — 검수 지적)

var _context: RunContext
var _rules: Dictionary = {}
var _flashlight: PointLight2D
var _lamp_lights: Array[PointLight2D] = []
var _lamp_positions: Array[Vector2] = []
var _temporary_lights: Array[Dictionary] = []
var _darkness: CanvasModulate
var _lamp_radius: float = 0.0   # 매번 사전을 찾지 않게 (is_in_light 는 좀비마다 프레임에 여러 번 불림)
var _flashlight_radius: float = 0.0


func setup(context: RunContext) -> void:
	_context = context
	_rules = context.light_rules
	_darkness = CanvasModulate.new()
	_darkness.color = Color(String(_rules["darkness_color"]))
	add_child(_darkness)
	_flashlight_radius = float(_rules["flashlight_radius"])
	_lamp_radius = float(_rules["street_lamp_radius"])
	_flashlight = _make_light(FLASHLIGHT_COLOR, _flashlight_radius)
	_flashlight.energy = 1.1
	for index: int in range(MAX_LAMP_LIGHTS):
		_lamp_lights.append(_make_light(LAMP_COLOR, float(_rules["street_lamp_radius"])))


## 밤마다 다른 어둠 색 (scripts/world/weather.gd 가 그 밤의 분위기로 바꿈)
func set_darkness_color(color: Color) -> void:
	_darkness.color = color


## 지금 화면 근처 가로등 위치 (props.gd 가 넘김)
func set_lamp_positions(positions: Array[Vector2]) -> void:
	_lamp_positions = positions


func lamp_positions() -> Array[Vector2]:
	return _lamp_positions


func add_temporary_light(at_position: Vector2, radius: float, seconds: float) -> void:
	if _temporary_lights.size() >= MAX_TEMPORARY_LIGHTS:
		(_temporary_lights.pop_front()["light"] as PointLight2D).queue_free()   # 가장 오래된 빛을 끄고 새 빛
	var light := _make_light(BURST_COLOR, radius)
	light.position = at_position
	light.energy = 1.4
	_temporary_lights.append({"position": at_position, "radius": radius, "time_left": seconds, "total": seconds, "light": light})


## 다음 밤으로 넘어갈 때 잠깐 빛(헬기 착륙 지점 등)을 끈다
func clear_temporary_lights() -> void:
	for item: Dictionary in _temporary_lights:
		(item["light"] as PointLight2D).queue_free()
	_temporary_lights.clear()


func update(delta: float) -> void:
	_flashlight_radius = float(_rules["flashlight_radius"]) * _context.survivor.stats.value("light_radius_multiplier")   # 손전등 배터리 장비
	_flashlight.texture_scale = _flashlight_radius / LIGHT_TEXTURE_RADIUS
	_flashlight.position = _context.survivor.position
	for index: int in range(_lamp_lights.size()):
		var light := _lamp_lights[index]
		light.visible = index < _lamp_positions.size()
		if light.visible:
			light.position = _lamp_positions[index]
	var write_index := 0   # 다 꺼진 빛은 그 자리에서 빼낸다 (매 프레임 새 배열을 만들지 않게)
	for item: Dictionary in _temporary_lights:
		item["time_left"] = float(item["time_left"]) - delta
		var light: PointLight2D = item["light"]
		light.energy = 1.4 * clampf(float(item["time_left"]) / minf(1.0, float(item["total"])), 0.0, 1.0)
		if float(item["time_left"]) <= 0.0:
			light.queue_free()
		else:
			_temporary_lights[write_index] = item
			write_index += 1
	_temporary_lights.resize(write_index)


func is_in_light(at_position: Vector2) -> bool:
	if at_position.distance_to(_context.survivor.position) <= _flashlight_radius:
		return true
	for lamp_position: Vector2 in _lamp_positions:
		if at_position.distance_to(lamp_position) <= _lamp_radius:
			return true
	for item: Dictionary in _temporary_lights:
		if at_position.distance_to(item["position"]) <= float(item["radius"]):
			return true
	return false


func _make_light(color: Color, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = LIGHT_TEXTURE
	light.texture_scale = radius / LIGHT_TEXTURE_RADIUS
	light.color = color
	add_child(light)
	return light
